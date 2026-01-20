import Foundation
import AppKit

// MARK: - Debug Helper
func debugLog(_ message: String) {
    NSLog(message)
    let msg = "[\(Date())] \(message)\n"
    if let data = msg.data(using: .utf8) {
        let url = URL(fileURLWithPath: "/tmp/clipboard_monitor_debug.txt")
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }
}
