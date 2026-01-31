import SwiftUI
import AppKit
import CoreData

// MARK: - Main Content View (Enhanced with AI features)
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItemEntity.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<ClipboardItemEntity>

    @State private var searchText = ""
    @State private var selectedCategory: ClipboardCategory?
    @State private var showingSettings = false
    @State private var selectedItem: ClipboardItemEntity?
    @State private var showingAIPanel = false
    @State private var searchMode: SearchMode = .hybrid
    @State private var selectedTag: String?
    @State private var showingTagSheet = false
    @ObservedObject private var settings = SettingsManager.shared
    private let smartSearch = SmartSearchEngine.shared
    private let contextDetector = ContextDetector.shared

    // License management
    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var showUpgradePrompt = false
    @State private var upgradeFeature = "Pro Features"

    var filteredItems: [ClipboardItemEntity] {
        var filtered = Array(items)

        // Apply smart search if text is entered
        if !searchText.isEmpty && settings.enableSemanticSearch {
            let searchResults = smartSearch.search(query: searchText, in: filtered, mode: searchMode)
            filtered = searchResults.map { $0.item }
        } else if !searchText.isEmpty {
            // Fallback to keyword search if semantic disabled
            filtered = filtered.filter { item in
                let content = item.displayContent.localizedCaseInsensitiveContains(searchText)
                let ocr = (item.ocrText ?? "").localizedCaseInsensitiveContains(searchText)
                return content || ocr
            }
        }

        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.clipboardCategory == category }
        }

        // Apply tag filter
        if let tag = selectedTag {
            filtered = filtered.filter { $0.projectTag == tag }
        }

        // Sort by context score if no search
        if searchText.isEmpty && settings.enableSemanticSearch {
            filtered = filtered.sorted { ($0.contextScore) > ($1.contextScore) }
        }

        return filtered
    }

    var availableTags: [String] {
        let tags = items.compactMap { $0.projectTag }.filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Clipso")
                        .font(.headline)
                    Spacer()

                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingSettings) {
                        SettingsView()
                            .frame(width: 400, height: 500)
                    }

                    Text("\(items.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search (includes OCR text)...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

                // Search mode picker (only show when semantic search enabled and searching)
                if settings.enableSemanticSearch && !searchText.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: searchMode == .semantic ? "brain" : searchMode == .keyword ? "text.magnifyingglass" : "sparkles")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Search Mode", selection: $searchMode) {
                            Text("Keyword").tag(SearchMode.keyword)

                            if licenseManager.canUseSemanticSearch() {
                                Text("Semantic").tag(SearchMode.semantic)
                                Text("Smart").tag(SearchMode.hybrid)
                            } else {
                                Text("Semantic 🔒").tag(SearchMode.semantic)
                                Text("Smart 🔒").tag(SearchMode.hybrid)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: searchMode) { newMode in
                            if (newMode == .semantic || newMode == .hybrid) &&
                               !licenseManager.canUseSemanticSearch() {
                                upgradeFeature = "AI Semantic Search"
                                showUpgradePrompt = true
                                searchMode = .keyword
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }

                // Project tags (if any exist)
                if !availableTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            ForEach(availableTags, id: \.self) { tag in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedTag = selectedTag == tag ? nil : tag
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        if selectedTag == tag {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption2)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(selectedTag == tag ? tagColor(for: tag) : tagColor(for: tag).opacity(0.15))
                                    )
                                    .foregroundColor(selectedTag == tag ? .white : tagColor(for: tag))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 4)
                }

                // Category filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryButton(title: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }

                        ForEach(ClipboardCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.displayName,
                                icon: category.icon,
                                color: category.color,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Items list
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No clipboard history yet" : "No results found")
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text("Copy something to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Results count header
                HStack {
                    Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !searchText.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 3) {
                            Image(systemName: searchMode == .semantic ? "brain" : searchMode == .keyword ? "text.magnifyingglass" : "sparkles")
                                .font(.caption2)
                            Text(searchMode == .hybrid ? "Smart Search" : searchMode == .semantic ? "Semantic" : "Keyword")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardItemRow(item: item, settings: settings)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity
                                ))
                                .animation(.easeInOut(duration: 0.2).delay(Double(index) * 0.02), value: filteredItems.count)
                                .contextMenu {
                                    Button("Copy") {
                                        copyToClipboard(item, smart: false)
                                    }

                                    if settings.enableSmartPaste {
                                        Button("Smart Paste") {
                                            copyToClipboard(item, smart: true)
                                        }
                                    }

                                    Divider()

                                    Menu("AI Actions") {
                                        Button("Summarize") {
                                            selectedItem = item
                                            showAISummary(item)
                                        }
                                        Button("Extract To-Dos") {
                                            selectedItem = item
                                            showActionItems(item)
                                        }
                                        Button("Fix Grammar") {
                                            selectedItem = item
                                            fixGrammar(item)
                                        }
                                    }

                                    if settings.enableSemanticSearch {
                                        Divider()

                                        Menu("Tag as...") {
                                            // Show suggested tags
                                            let suggestions = contextDetector.suggestProjectTags(for: item, basedOn: Array(items))
                                            if !suggestions.isEmpty {
                                                ForEach(suggestions.prefix(3)) { suggestion in
                                                    Button("\(suggestion.tag) (\(suggestion.confidencePercent)%)") {
                                                        setTag(for: item, tag: suggestion.tag)
                                                    }
                                                }
                                                Divider()
                                            }

                                            // Show existing tags
                                            ForEach(availableTags, id: \.self) { tag in
                                                Button(tag) {
                                                    setTag(for: item, tag: tag)
                                                }
                                            }

                                            Divider()

                                            Button("New Tag...") {
                                                selectedItem = item
                                                showingTagSheet = true
                                            }

                                            if item.projectTag != nil {
                                                Button("Remove Tag") {
                                                    removeTag(from: item)
                                                }
                                            }
                                        }
                                    }

                                    Divider()

                                    Button("Delete") {
                                        deleteItem(item)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingTagSheet) {
            if let item = selectedItem {
                TagInputSheet(item: item, onSave: { tag in
                    setTag(for: item, tag: tag)
                    showingTagSheet = false
                })
            }
        }
        .sheet(isPresented: $showUpgradePrompt) {
            ProUpgradePromptView(feature: upgradeFeature)
        }
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

    private func deleteItem(_ item: ClipboardItemEntity) {
        viewContext.delete(item)
        PersistenceController.shared.save()
    }

    private func showAISummary(_ item: ClipboardItemEntity) {
        let summary = AIClipboardAssistant.shared.summarize(item.displayContent)
        let alert = NSAlert()
        alert.messageText = "Summary"
        alert.informativeText = summary
        alert.addButton(withTitle: "Copy Summary")
        alert.addButton(withTitle: "Close")

        if alert.runModal() == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(summary, forType: .string)
        }
    }

    private func showActionItems(_ item: ClipboardItemEntity) {
        let items = AIClipboardAssistant.shared.extractActionItems(item.displayContent)
        let alert = NSAlert()
        alert.messageText = "Action Items Found"
        alert.informativeText = items.isEmpty ? "No action items detected" : items.joined(separator: "\n\n")
        alert.addButton(withTitle: "Copy Items")
        alert.addButton(withTitle: "Close")

        if alert.runModal() == .alertFirstButtonReturn && !items.isEmpty {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(items.joined(separator: "\n"), forType: .string)
        }
    }

    private func fixGrammar(_ item: ClipboardItemEntity) {
        let fixed = AIClipboardAssistant.shared.fixGrammar(item.displayContent)
        let alert = NSAlert()
        alert.messageText = "Grammar Fixed"
        alert.informativeText = fixed
        alert.addButton(withTitle: "Copy Fixed Version")
        alert.addButton(withTitle: "Close")

        if alert.runModal() == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(fixed, forType: .string)
        }
    }

    private func setTag(for item: ClipboardItemEntity, tag: String) {
        item.projectTag = tag
        PersistenceController.shared.save()
        print("✅ Tagged item \(item.id) with: \(tag)")
    }

    private func removeTag(from item: ClipboardItemEntity) {
        item.projectTag = nil
        PersistenceController.shared.save()
        print("✅ Removed tag from item \(item.id)")
    }

    private func tagColor(for tag: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .indigo, .teal]
        let hash = abs(tag.hashValue)
        return colors[hash % colors.count]
    }
}
