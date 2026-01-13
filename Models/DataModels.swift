import SwiftUI

// MARK: - Data Models
enum ClipboardCategory: Int, CaseIterable {
    case text = 0, code = 1, link = 2, email = 3, phone = 4, color = 5, image = 6

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .code: return "Code"
        case .link: return "Link"
        case .email: return "Email"
        case .phone: return "Phone"
        case .color: return "Color"
        case .image: return "Image"
        }
    }

    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .link: return "link"
        case .email: return "envelope"
        case .phone: return "phone"
        case .color: return "paintpalette"
        case .image: return "photo"
        }
    }

    var color: Color {
        switch self {
        case .text: return .blue
        case .code: return .purple
        case .link: return .green
        case .email: return .orange
        case .phone: return .pink
        case .color: return .red
        case .image: return .cyan
        }
    }
}
