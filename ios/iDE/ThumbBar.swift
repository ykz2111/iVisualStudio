import SwiftUI

/// The 48 pt thumb-zone coding bar riding above the keyboard: a fixed cursor
/// cluster, horizontally scrollable key pages, page toggle, undo/redo and a
/// hide-keyboard key. Light haptic on taps, medium on undo/redo.
struct ThumbBar: View {
    @ObservedObject var handle: EditorHandle
    @State private var showsSymbolsPage = false

    private static let codeKeys = ["Tab", "{", "}", "(", ")", "[", "]", ";", "="]
    private static let symbolKeys = ["<", ">", "\"", "'", "`", ":", "!", "&", "|", "⇤"]

    var body: some View {
        HStack(spacing: 0) {
            cursorCluster
            divider
            pageScroller
            divider
            trailingCluster
        }
        .frame(height: IDETheme.recommendedHitTarget)
        .frame(maxWidth: .infinity)
        .background(IDETheme.thumbBar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(IDETheme.elevated)
                .frame(height: 1)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(IDETheme.elevated)
            .frame(width: 1)
            .padding(.vertical, 8)
    }

    private var cursorCluster: some View {
        HStack(spacing: 0) {
            iconButton("chevron.left", label: "Move cursor left") { handle.moveCursor(.left) }
            iconButton("chevron.up", label: "Move cursor up") { handle.moveCursor(.up) }
            iconButton("chevron.down", label: "Move cursor down") { handle.moveCursor(.down) }
            iconButton("chevron.right", label: "Move cursor right") { handle.moveCursor(.right) }
        }
        .padding(.horizontal, 2)
    }

    private var pageScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(showsSymbolsPage ? Self.symbolKeys : Self.codeKeys, id: \.self) { key in
                    keyButton(key)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var trailingCluster: some View {
        HStack(spacing: 0) {
            Button {
                Haptics.light()
                showsSymbolsPage.toggle()
            } label: {
                Text(showsSymbolsPage ? "abc" : "#+")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .frame(width: 38, height: IDETheme.minimumHitTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(IDETheme.azure)
            .accessibilityLabel(showsSymbolsPage ? "Show code keys" : "Show symbol keys")

            iconButton("arrow.uturn.backward", label: "Undo") {
                Haptics.medium()
                handle.undo()
            }
            iconButton("arrow.uturn.forward", label: "Redo") {
                Haptics.medium()
                handle.redo()
            }
            iconButton("keyboard.chevron.compact.down", label: "Hide keyboard") {
                Haptics.light()
                handle.dismissKeyboard()
            }
        }
        .padding(.horizontal, 2)
    }

    private func iconButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 30, height: IDETheme.minimumHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(IDETheme.primary)
        .accessibilityLabel(label)
    }

    private func keyButton(_ key: String) -> some View {
        Button {
            Haptics.light()
            switch key {
            case "Tab": handle.tabKey()
            case "⇤": handle.dedent()
            default: handle.insert(key)
            }
        } label: {
            Text(key)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .frame(width: 44, height: IDETheme.minimumHitTarget)
                .background(IDETheme.elevated, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(IDETheme.primary)
        .accessibilityLabel(key == "⇤" ? "Dedent" : key)
    }
}

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
