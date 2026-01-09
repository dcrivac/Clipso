import SwiftUI
import AppKit
import CoreData

// MARK: - Settings View (Enhanced)
struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var newExcludedApp = ""
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var showLicenseActivation = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // License status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("License")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack {
                            if licenseManager.isProUser {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("✓ Pro License Active")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    if let email = licenseManager.licenseEmail {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(licenseManager.licenseType.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Deactivate") {
                                    licenseManager.deactivateLicense()
                                }
                                .foregroundColor(.red)
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Free Plan")
                                        .font(.headline)
                                    Text("250 items • 30-day retention • Keyword search")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Upgrade to Pro") {
                                    licenseManager.purchaseLifetime()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        Button("Activate License...") {
                            showLicenseActivation = true
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    // History settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History Retention")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack {
                            Text("Keep items for:")
                            Stepper("\(settings.retentionDays) days", value: $settings.retentionDays, in: 1...365)
                        }

                        HStack {
                            Text("Maximum items:")
                            Stepper("\(settings.maxItems)", value: $settings.maxItems, in: 50...1000, step: 50)
                        }
                    }

                    Divider()

                    // Security settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Security")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Toggle("Enable encryption", isOn: $settings.enableEncryption)

                        Text("When enabled, clipboard content is encrypted using AES-256")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // AI Features
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Features")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Toggle("Enable OCR for screenshots", isOn: $settings.enableOCR)
                        Text("Automatically extract text from images")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Toggle("Enable Smart Paste", isOn: $settings.enableSmartPaste)
                        Text("Auto-format content based on target app")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Toggle("Enable Semantic Search & Context Detection", isOn: $settings.enableSemanticSearch)
                        Text("AI-powered search and project context detection")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if settings.enableSemanticSearch {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Auto-detect Projects", isOn: $settings.enableAutoProjects)
                                    .padding(.leading, 20)
                                Text("Group clipboard items by app patterns and time windows")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 20)

                                HStack {
                                    Text("Context Window:")
                                        .padding(.leading, 20)
                                    Stepper("\(settings.contextWindowMinutes) minutes", value: $settings.contextWindowMinutes, in: 15...120, step: 15)
                                }

                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Similarity Threshold:")
                                            .padding(.leading, 20)
                                        Spacer()
                                        Text(String(format: "%.2f", settings.similarityThreshold))
                                            .foregroundColor(.secondary)
                                    }
                                    Slider(value: $settings.similarityThreshold, in: 0.5...0.95, step: 0.05)
                                        .padding(.leading, 20)
                                    Text("Higher values = stricter matching")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 20)
                                }

                                Button("Rebuild Embeddings") {
                                    rebuildEmbeddings()
                                }
                                .padding(.leading, 20)
                            }
                        }
                    }

                    Divider()

                    // Excluded apps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Excluded Applications")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("Clipboard won't monitor these apps")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("App name", text: $newExcludedApp)
                                .textFieldStyle(.roundedBorder)

                            Button("Add") {
                                if !newExcludedApp.isEmpty {
                                    settings.excludedApps.insert(newExcludedApp)
                                    newExcludedApp = ""
                                }
                            }
                            .disabled(newExcludedApp.isEmpty)
                        }

                        if !SettingsManager.suggestedExclusions.allSatisfy({ settings.excludedApps.contains($0) }) {
                            Text("Suggested:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            FlowLayout(spacing: 6) {
                                ForEach(SettingsManager.suggestedExclusions, id: \.self) { app in
                                    if !settings.excludedApps.contains(app) {
                                        Button(action: { settings.excludedApps.insert(app) }) {
                                            HStack(spacing: 4) {
                                                Text(app)
                                                    .font(.caption)
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.caption)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.1))
                                            .foregroundColor(.green)
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        if !settings.excludedApps.isEmpty {
                            Text("Currently excluded:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)

                            FlowLayout(spacing: 6) {
                                ForEach(Array(settings.excludedApps).sorted(), id: \.self) { app in
                                    HStack(spacing: 4) {
                                        Text(app)
                                            .font(.caption)
                                        Button(action: { settings.excludedApps.remove(app) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keyboard Shortcut")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack {
                            Text("⌘ ⇧ V")
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)

                            Text("to open clipboard manager")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showLicenseActivation) {
            LicenseActivationView()
        }
    }

    private func rebuildEmbeddings() {
        let context = PersistenceController.shared.container.viewContext
        EmbeddingProcessor.shared.processExistingItems(context: context)

        let alert = NSAlert()
        alert.messageText = "Rebuilding Embeddings"
        alert.informativeText = "Processing embeddings in the background. This may take a few moments."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
