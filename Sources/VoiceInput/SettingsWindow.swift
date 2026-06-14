import AppKit

final class SettingsWindow: NSPanel {
    private let targetLanguagePopup = NSPopUpButton()
    private let llmBaseURLField = NSTextField()
    private let llmAPIKeyField = NSSecureTextField()
    private let llmModelField = NSTextField()
    private let statusLabel = NSTextField(labelWithString: "")

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 360),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        title = "Translation Settings"
        isReleasedWhenClosed = false
        minSize = NSSize(width: 520, height: 320)
        setupUI()
        loadSettings()
        center()
    }

    private func setupUI() {
        guard let cv = contentView else { return }

        TranslationLanguages.supported.forEach { targetLanguagePopup.addItem(withTitle: $0.title) }

        llmBaseURLField.placeholderString = "https://api.openai.com/v1"
        llmAPIKeyField.placeholderString = "sk-..."
        llmModelField.placeholderString = "gpt-4o-mini"

        let targetGroup = makeGroup(
            title: "Target Language",
            subtitle: nil,
            rows: [
                ("Language", targetLanguagePopup),
            ]
        )

        let llmGroup = makeGroup(
            title: "LLM API",
            subtitle: "OpenAI-compatible",
            rows: [
                ("Base URL", llmBaseURLField),
                ("API Key", llmAPIKeyField),
                ("Model", llmModelField),
            ]
        )

        let contentStack = NSStackView(views: [targetGroup, llmGroup])
        contentStack.orientation = .vertical
        contentStack.spacing = 18
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        configureStatusLabel(statusLabel)

        let testButton = NSButton(title: "Test", target: self, action: #selector(test))
        testButton.bezelStyle = .rounded

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.keyEquivalent = "\r"
        saveButton.bezelStyle = .rounded

        let footer = NSStackView(views: [statusLabel, testButton, saveButton])
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.spacing = 8
        footer.translatesAutoresizingMaskIntoConstraints = false

        cv.addSubview(contentStack)
        cv.addSubview(footer)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: cv.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -20),

            footer.topAnchor.constraint(greaterThanOrEqualTo: contentStack.bottomAnchor, constant: 20),
            footer.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 20),
            footer.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -20),
            footer.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -16),
        ])
    }

    private func makeGroup(title: String, subtitle: String?, rows: [(String, NSView)]) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 12
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        let views = rows.map { (labelText, field) in
            [makeRightAlignedLabel(labelText), field]
        }
        let grid = NSGridView(views: views)
        configureGrid(grid)

        let arranged: [NSView]
        if let subtitle, !subtitle.isEmpty {
            let subtitleLabel = NSTextField(labelWithString: subtitle)
            subtitleLabel.textColor = .secondaryLabelColor
            arranged = [titleLabel, subtitleLabel, grid]
        } else {
            arranged = [titleLabel, grid]
        }

        let stack = NSStackView(views: arranged)
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        for (_, field) in rows {
            field.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        }

        return container
    }

    private func configureGrid(_ grid: NSGridView) {
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 12
        grid.columnSpacing = 8
        grid.column(at: 0).xPlacement = .trailing
    }

    private func makeRightAlignedLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .right
        return label
    }

    private func configureStatusLabel(_ label: NSTextField) {
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func loadSettings() {
        let settings = AppSettings.shared
        let llm = settings.llmConfiguration

        targetLanguagePopup.selectItem(withTitle: TranslationLanguages.title(for: settings.targetLocaleCode))
        llmBaseURLField.stringValue = llm.baseURL
        llmAPIKeyField.stringValue = llm.apiKey
        llmModelField.stringValue = llm.model
    }

    @objc private func test() {
        applyFields()
        showStatus("Testing...", success: nil)
        TranslationService.shared.testActiveProvider(sampleText: "你好，这是一个测试。") { [weak self] result in
            switch result {
            case .success(let text):
                self?.showStatus("OK: \(text)", success: true)
            case .failure(let error):
                self?.showStatus(error.localizedDescription, success: false)
            }
        }
    }

    @objc private func save() {
        applyFields()
        close()
    }

    private func applyFields() {
        let settings = AppSettings.shared
        if let language = TranslationLanguages.supported.first(where: { $0.title == targetLanguagePopup.titleOfSelectedItem }) {
            settings.targetLocaleCode = language.appValue
        }
        settings.llmConfiguration = LLMProviderConfiguration(
            baseURL: llmBaseURLField.stringValue,
            model: llmModelField.stringValue,
            apiKey: llmAPIKeyField.stringValue
        )
    }

    private func showStatus(_ text: String, success: Bool?) {
        statusLabel.stringValue = text
        switch success {
        case .some(true):
            statusLabel.textColor = .systemGreen
        case .some(false):
            statusLabel.textColor = .systemRed
        case .none:
            statusLabel.textColor = .secondaryLabelColor
        }
    }
}
