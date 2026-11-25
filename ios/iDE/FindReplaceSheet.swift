import SwiftUI

/// Find with match count and prev/next selection, replace / replace-all with
/// regex and case toggles, plus a jump-to-line field.
struct FindReplaceSheet: View {
    @ObservedObject var handle: EditorHandle
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var replacement = ""
    @State private var isRegex = false
    @State private var isCaseSensitive = true
    @State private var jumpText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Find") {
                    HStack(spacing: 12) {
                        TextField("Find", text: $query)
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Text(countLabel)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(IDETheme.secondary)
                        Button {
                            handle.findPrevious()
                        } label: {
                            Image(systemName: "chevron.up")
                                .frame(minWidth: 22, minHeight: 22)
                        }
                        .disabled(handle.matchCount == 0)
                        Button {
                            handle.findNext()
                        } label: {
                            Image(systemName: "chevron.down")
                                .frame(minWidth: 22, minHeight: 22)
                        }
                        .disabled(handle.matchCount == 0)
                    }
                    HStack(spacing: 12) {
                        Toggle(isOn: $isRegex) {
                            Text(".*")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        }
                        .toggleStyle(.button)
                        Toggle(isOn: $isCaseSensitive) {
                            Text("Aa")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        }
                        .toggleStyle(.button)
                        Spacer()
                    }
                }
                Section("Replace") {
                    TextField("Replace with", text: $replacement)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    HStack(spacing: 12) {
                        Button("Replace") {
                            handle.replaceCurrent(with: replacement)
                        }
                        .disabled(handle.matchCount == 0)
                        Button("Replace All") {
                            handle.replaceAll(with: replacement)
                        }
                        .disabled(handle.matchCount == 0)
                    }
                }
                Section("Jump to line") {
                    HStack(spacing: 12) {
                        TextField("Line", text: $jumpText)
                            .font(.system(.body, design: .monospaced))
                            .keyboardType(.numberPad)
                        Button("Go") {
                            if let line = Int(jumpText) {
                                handle.jump(toLine: line)
                            }
                        }
                        .disabled(Int(jumpText) == nil)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(IDETheme.canvas)
            .navigationTitle("Find & Replace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .frame(minHeight: IDETheme.minimumHitTarget)
                }
            }
            .onChange(of: query) { _, _ in runFind() }
            .onChange(of: isRegex) { _, _ in runFind() }
            .onChange(of: isCaseSensitive) { _, _ in runFind() }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var countLabel: String {
        handle.matchCount == 0 ? "no matches" : "\(handle.currentMatchNumber) of \(handle.matchCount)"
    }

    private func runFind() {
        handle.performFind(query: query, isRegex: isRegex, caseSensitive: isCaseSensitive)
    }
}
