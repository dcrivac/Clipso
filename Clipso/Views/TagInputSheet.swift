import SwiftUI

// MARK: - Tag Input Sheet
struct TagInputSheet: View {
    let item: ClipboardItemEntity
    let onSave: (String) -> Void
    @State private var tagName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Project Tag")
                .font(.headline)

            TextField("Tag name (e.g., \"Auth Feature\")", text: $tagName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    if !tagName.isEmpty {
                        onSave(tagName)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(tagName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
