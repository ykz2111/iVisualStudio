import SwiftUI

enum EditorSaveState {
    case unsaved
    case saving
    case saved
    case failed

    var label: String {
        switch self {
        case .unsaved: return "UNSAVED"
        case .saving: return "SAVING"
        case .saved: return "SAVED"
        case .failed: return "SAVE FAILED"
        }
    }

    var color: Color {
        switch self {
        case .unsaved: return IDETheme.amber
        case .saving: return IDETheme.azure
        case .saved: return IDETheme.emerald
        case .failed: return .red
        }
    }
}

/// Phase 2 editor screen: fully editable, autosaved with a 0.9 s debounce
/// plus a synchronous flush on disappear, thumb bar and find & replace.
struct EditorScreenView: View {
    let file: CodeFile

    @StateObject private var handle = EditorHandle()
    @State private var text = ""
    @State private var lastSavedText = ""
    @State private var loadError: String?
    @State private var saveState: EditorSaveState = .saved
    @State private var showFindSheet = false
    @State private var saveTask: Task<Void, Never>?
    @ScaledMetric(relativeTo: .footnote) private var codeSize = IDETheme.codeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        Group {
            if let loadError {
                ContentUnavailableView(
                    "Can't open this file",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(loadError)
                )
                .background(IDETheme.oledBlack)
            } else {
                ZStack(alignment: .topLeading) {
                    EditorTextView(
                        text: $text,
                        handle: handle,
                        codeSize: codeSize,
                        wrapLines: verticalSizeClass != .compact
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    GutterRulerView(handle: handle)
                        .frame(width: handle.gutterWidth)
                        .allowsHitTesting(false)
                }
                .background(IDETheme.oledBlack)
            }
        }
        .background(IDETheme.oledBlack.ignoresSafeArea())
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFindSheet = true
                } label: {
                    Image(systemName: "text.magnifyingglass")
                        .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                }
                .accessibilityLabel("Find and replace")
            }
        }
        .sheet(isPresented: $showFindSheet) {
            FindReplaceSheet(handle: handle)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ThumbBar(handle: handle)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            statusStrip
        }
        .task(id: file.id) { load() }
        .onChange(of: text) { _, newValue in
            guard newValue != lastSavedText else { return }
            scheduleSave()
        }
        .onDisappear { flushSave() }
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(IDETheme.cyan)
                .frame(width: 6, height: 6)
            Text(file.workspace.name.uppercased())
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("LN \(handle.cursorLine) COL \(handle.cursorColumn)")
                .monospacedDigit()
            Text(saveState.label)
                .foregroundStyle(saveState.color)
            Text("UTF-8")
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(IDETheme.secondary)
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(IDETheme.chassis)
        .accessibilityElement(children: .combine)
    }

    private func load() {
        do {
            let loaded = try file.readText()
            text = loaded
            lastSavedText = loaded
            loadError = nil
            saveState = .saved
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveState = .unsaved
        saveTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(0.9))
            } catch {
                return // cancelled; a newer edit rescheduled
            }
            await save()
        }
    }

    private func save() async {
        saveState = .saving
        do {
            try file.writeText(text)
            lastSavedText = text
            saveState = .saved
        } catch {
            saveState = .failed
        }
    }

    private func flushSave() {
        saveTask?.cancel()
        guard text != lastSavedText else { return }
        do {
            try file.writeText(text)
            lastSavedText = text
            saveState = .saved
        } catch {
            saveState = .failed
        }
    }
}
