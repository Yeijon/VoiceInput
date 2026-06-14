import Cocoa

final class KeyMonitor {
    var onFnDown: ((RecordingMode) -> Void)?
    var onFnUp: ((RecordingMode) -> Void)?
    var onModeChanged: ((RecordingMode) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var fnPressed = false
    private var optionPressed = false
    private var sawOptionWhileFnPressed = false

    /// Start monitoring. Returns false if accessibility permission is missing.
    func start() -> Bool {
        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<KeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handle(type: type, event: event)
            },
            userInfo: refcon
        ) else {
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        runLoopSource = nil
        eventTap = nil
    }

    // MARK: - Private

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable tap if the system disabled it
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        let flags = event.flags
        let fnDown = flags.contains(.maskSecondaryFn)
        let optionDown = flags.contains(.maskAlternate)
        let previousOptionPressed = optionPressed
        optionPressed = optionDown

        if fnDown && !fnPressed {
            fnPressed = true
            sawOptionWhileFnPressed = optionDown
            let mode: RecordingMode = sawOptionWhileFnPressed ? .translation : .dictation
            DispatchQueue.main.async { [weak self] in self?.onFnDown?(mode) }
            return nil // suppress Fn press (prevents emoji picker)
        } else if !fnDown && fnPressed {
            fnPressed = false
            let mode: RecordingMode = sawOptionWhileFnPressed ? .translation : .dictation
            sawOptionWhileFnPressed = false
            DispatchQueue.main.async { [weak self] in self?.onFnUp?(mode) }
            return nil // suppress Fn release
        } else if fnPressed && optionDown != previousOptionPressed {
            if optionDown {
                sawOptionWhileFnPressed = true
            }
            let mode: RecordingMode = sawOptionWhileFnPressed ? .translation : .dictation
            DispatchQueue.main.async { [weak self] in self?.onModeChanged?(mode) }
        }

        return Unmanaged.passRetained(event)
    }
}
