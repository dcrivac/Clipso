import SwiftUI
import AppKit

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let icon: String
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Clipboard Item Row (Enhanced)
struct ClipboardItemRow: View {
    let item: ClipboardItemEntity
    let settings: SettingsManager
    @State private var isHovered = false

    private var contextScorePercent: Int {
        Int(item.contextScore * 100)
    }

    private var contextScoreColor: Color {
        switch item.contextScore {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .gray
        }
    }

    private var hasRelatedItems: Bool {
        item.relatedItemIDs != nil && !item.relatedItemIDs!.isEmpty
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon with context score indicator
            ZStack(alignment: .topTrailing) {
                Image(systemName: item.clipboardCategory.icon)
                    .font(.title3)
                    .foregroundColor(item.clipboardCategory.color)
                    .frame(width: 24)

                // Context score badge (only if semantic search enabled)
                if settings.enableSemanticSearch && item.contextScore > 0.3 {
                    Circle()
                        .fill(contextScoreColor)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let image = item.displayImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 100)
                        .cornerRadius(4)

                    if let ocrText = item.ocrText, !ocrText.isEmpty {
                        Text("OCR: \(ocrText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    Text(item.displayContent)
                        .lineLimit(3)
                        .font(.system(.body, design: item.clipboardCategory == .code ? .monospaced : .default))
                        .foregroundColor(.primary)
                }

                // Project tag (if exists)
                if let tag = item.projectTag, !tag.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                        Text(tag)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tagColor(for: tag).opacity(0.15))
                    .foregroundColor(tagColor(for: tag))
                    .cornerRadius(6)
                }

                // Metadata row
                HStack(spacing: 8) {
                    // Category badge
                    HStack(spacing: 3) {
                        Image(systemName: item.clipboardCategory.icon)
                            .font(.caption2)
                        Text(item.clipboardCategory.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.clipboardCategory.color.opacity(0.1))
                    .foregroundColor(item.clipboardCategory.color)
                    .cornerRadius(4)

                    if let app = item.sourceApp {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(app)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Indicators
                    if item.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .help("Encrypted")
                    }

                    if item.ocrText != nil {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .help("OCR Text Available")
                    }

                    if hasRelatedItems && settings.enableSemanticSearch {
                        Image(systemName: "link.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .help("Has Related Items")
                    }

                    Spacer()

                    // Context score (on hover)
                    if isHovered && settings.enableSemanticSearch && item.contextScore > 0 {
                        Text("\(contextScorePercent)%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(contextScoreColor)
                            .help("Context Relevance Score")
                    }

                    Text(timeAgo(from: item.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isHovered {
                VStack(spacing: 4) {
                    Button(action: {
                        copyToClipboard(item, smart: false)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Copy")

                    if settings.enableSmartPaste {
                        Button(action: {
                            copyToClipboard(item, smart: true)
                        }) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.purple)
                        }
                        .buttonStyle(.plain)
                        .help("Smart Paste")
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.blue.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .onTapGesture {
            copyToClipboard(item, smart: false)
        }
    }

    // Generate consistent color for tags
    private func tagColor(for tag: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .indigo, .teal]
        let hash = abs(tag.hashValue)
        return colors[hash % colors.count]
    }

    private func copyToClipboard(_ item: ClipboardItemEntity, smart: Bool) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let image = item.displayImage {
            pasteboard.writeObjects([image])
        } else {
            var content = item.displayContent

            if smart, let app = NSWorkspace.shared.frontmostApplication?.localizedName {
                content = SmartPasteEngine.shared.transform(
                    content: content,
                    targetApp: app,
                    category: item.clipboardCategory
                )
            }

            pasteboard.setString(content, forType: .string)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}
