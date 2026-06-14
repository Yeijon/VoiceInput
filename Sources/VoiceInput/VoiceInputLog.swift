import Foundation
import os.log

let voiceInputLogger = Logger(subsystem: "com.yetone.VoiceInput", category: "VoiceInput")

func logToFile(_ message: String) {
    let msg = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
    let logURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/VoiceInput.log")
    if let handle = try? FileHandle(forWritingTo: logURL) {
        handle.seekToEndOfFile()
        handle.write(msg.data(using: .utf8)!)
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logURL.path, contents: msg.data(using: .utf8))
    }
}
