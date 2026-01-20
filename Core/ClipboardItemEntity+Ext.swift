import Foundation
import AppKit
import CoreData

// MARK: - Core Data Entity Extension
extension ClipboardItemEntity {
    var clipboardCategory: ClipboardCategory {
        get { ClipboardCategory(rawValue: Int(category)) ?? .text }
        set { category = Int16(newValue.rawValue) }
    }

    var displayContent: String {
        if isEncrypted, let encData = encryptedContent {
            return EncryptionHelper.decrypt(encData) ?? "[Encrypted]"
        }
        return content ?? ""
    }

    var displayImage: NSImage? {
        guard let data = imageData else { return nil }
        return NSImage(data: data)
    }
}
