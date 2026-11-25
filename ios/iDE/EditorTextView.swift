import SwiftUI
import UIKit

// MARK: - Cursor direction

enum CursorDirection {
    case left, right, up, down
}

// MARK: - Editor handle

/// Bridge that lets SwiftUI controls (thumb bar, find sheet, status strip)
/// drive the UIKit text view and read its live state.
@MainActor
final class EditorHandle: ObservableObject {
    @Published var cursorLine = 1
    @Published var cursorColumn = 1
    @Published var lineCount = 1
    @Published var gutterWidth: CGFloat = 36
    @Published var matchCount = 0
    @Published var currentMatchNumber = 0

    weak var textView: CodeTextView?
    weak var gutter: GutterView?

    private var matches: [NSRange] = []
    private var currentIndex = 0
    private var findQuery = ""
    private var findIsRegex = false
    private var findIsCaseSensitive = false

    // MARK: Cursor commands

    func moveCursor(_ direction: CursorDirection) {
        textView?.moveCursor(direction)
    }

    /// Inserts raw text at the caret (thumb bar keys).
    func insert(_ text: String) {
        textView?.insertText(text)
    }

    func tabKey() {
        textView?.insertTabOrIndentBlock()
    }

    func indent() {
        textView?.indentBlock()
    }

    func dedent() {
        textView?.dedentBlock()
    }

    func undo() {
        textView?.undoManager?.undo()
    }

    func redo() {
        textView?.undoManager?.redo()
    }

    func dismissKeyboard() {
        textView?.endEditing(true)
    }

    func invalidateGutter() {
        gutter?.setNeedsDisplay()
    }

    // MARK: Find & replace

    func performFind(query: String, isRegex: Bool, caseSensitive: Bool) {
        findQuery = query
        findIsRegex = isRegex
        findIsCaseSensitive = caseSensitive
        matches = Self.computeMatches(
            in: textView?.text ?? "",
            query: query,
            isRegex: isRegex,
            caseSensitive: caseSensitive
        )
        matchCount = matches.count
        guard matchCount > 0 else {
            currentIndex = 0
            currentMatchNumber = 0
            return
        }
        let selectionLocation = textView?.selectedRange.location ?? 0
        currentIndex = matches.firstIndex { NSMaxRange($0) > selectionLocation } ?? 0
        currentMatchNumber = currentIndex + 1
        selectCurrentMatch()
    }

    func findNext() {
        guard matchCount > 0 else { return }
        currentIndex = (currentIndex + 1) % matchCount
        currentMatchNumber = currentIndex + 1
        selectCurrentMatch()
    }

    func findPrevious() {
        guard matchCount > 0 else { return }
        currentIndex = (currentIndex - 1 + matchCount) % matchCount
        currentMatchNumber = currentIndex + 1
        selectCurrentMatch()
    }

    func replaceCurrent(with replacement: String) {
        guard matchCount > 0, currentIndex < matches.count, let textView else { return }
        textView.performReplace(matches[currentIndex], with: replacement)
        performFind(query: findQuery, isRegex: findIsRegex, caseSensitive: findIsCaseSensitive)
    }

    func replaceAll(with replacement: String) {
        guard let textView, !findQuery.isEmpty else { return }
        let source = textView.text ?? ""
        let nsSource = source as NSString
        let full = NSRange(location: 0, length: nsSource.length)
        let replacementText: String
        if findIsRegex, let regex = try? NSRegularExpression(
            pattern: findQuery,
            options: findIsCaseSensitive ? [] : .caseInsensitive
        ) {
            replacementText = regex.stringByReplacingMatches(
                in: source, options: [], range: full, withTemplate: replacement
            )
        } else {
            replacementText = nsSource.replacingOccurrences(
                of: findQuery,
                with: replacement,
                options: findIsCaseSensitive ? [] : .caseInsensitive,
                range: NSRange(location: 0, length: nsSource.length)
            )
        }
        guard replacementText != source else { return }
        textView.performReplace(full, with: replacementText)
        performFind(query: findQuery, isRegex: findIsRegex, caseSensitive: findIsCaseSensitive)
    }

    func jump(toLine line: Int) {
        guard let textView else { return }
        let source = textView.text ?? ""
        let nsSource = source as NSString
        let total = max(source.components(separatedBy: .newlines).count, 1)
        let target = min(max(line, 1), total)
        var offset = 0
        var line = 1
        while line < target {
            let found = nsSource.range(
                of: "\n",
                options: .literal,
                range: NSRange(location: offset, length: max(nsSource.length - offset, 0))
            )
            guard found.location != NSNotFound else { break }
            offset = found.location + 1
            line += 1
        }
        textView.selectedRange = NSRange(location: min(offset, nsSource.length), length: 0)
        textView.scrollRangeToVisible(textView.selectedRange)
    }

    private func selectCurrentMatch() {
        guard currentIndex < matches.count, let textView else { return }
        let range = matches[currentIndex]
        textView.selectedRange = range
        textView.scrollRangeToVisible(range)
    }

    static func computeMatches(in text: String, query: String, isRegex: Bool, caseSensitive: Bool) -> [NSRange] {
        guard !query.isEmpty else { return [] }
        let nsText = text as NSString
        if isRegex {
            guard let regex = try? NSRegularExpression(
                pattern: query,
                options: caseSensitive ? [] : .caseInsensitive
            ) else { return [] }
            return regex.matches(
                in: text,
                options: [],
                range: NSRange(location: 0, length: nsText.length)
            ).map(\.range)
        }
        var results: [NSRange] = []
        var search = NSRange(location: 0, length: nsText.length)
        while search.length > 0 {
            let found = nsText.range(
                of: query,
                options: caseSensitive ? [] : [.caseInsensitive],
                range: search
            )
            guard found.location != NSNotFound else { break }
            results.append(found)
            guard found.length > 0 else { break }
            search.location = found.location + found.length
            search.length = nsText.length - search.location
        }
        return results
    }
}

// MARK: - Syntax tokens (same palette as the Phase 1 viewer)

enum CodeTokenizer {
    private static let keywordRegex = try! NSRegularExpression(
        pattern: #"\b(func|let|var|struct|class|enum|case|import|return|if|else|for|in|throws|try|guard|private|public|static|some|true|false|nil)\b"#
    )
    private static let typeRegex = try! NSRegularExpression(
        pattern: #"\b[A-Z][A-Za-z0-9_]*\b"#
    )
    private static let numberRegex = try! NSRegularExpression(
        pattern: #"\b[0-9]+\b"#
    )
    private static let stringOrCommentRegex = try! NSRegularExpression(
        pattern: #""(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|//.*$"#,
        options: .anchorsMatchLines
    )

    /// Applies tokens to `range` only; strings and comments go last so they
    /// win over keywords and types inside them.
    static func highlight(_ storage: NSTextStorage, range: NSRange) {
        apply(keywordRegex, IDETheme.violet, to: storage, range: range)
        apply(typeRegex, IDETheme.azure, to: storage, range: range)
        apply(numberRegex, IDETheme.amber, to: storage, range: range)
        apply(stringOrCommentRegex, IDETheme.emerald, to: storage, range: range)
    }

    private static func apply(
        _ regex: NSRegularExpression,
        _ color: Color,
        to storage: NSTextStorage,
        range: NSRange
    ) {
        guard range.location >= 0, range.location <= storage.length else { return }
        let length = max(min(range.length, storage.length - range.location), 0)
        let safe = NSRange(location: range.location, length: length)
        for match in regex.matches(in: storage.string, options: [], range: safe) where match.range.length > 0 {
            storage.addAttribute(.foregroundColor, value: UIColor(color), range: match.range)
        }
    }
}

// MARK: - Text view

final class CodeTextView: UITextView {
    var onTextChanged: (@MainActor () -> Void)?
    var onCaretMoved: (@MainActor () -> Void)?
    var onScroll: (@MainActor () -> Void)?
    var onMetricsChanged: (@MainActor (Int, CGFloat) -> Void)?

    private(set) var wrapLines = true
    private var isHighlighting = false
    private var cachedIndentUnit: String?
    private var gutterWidthValue: CGFloat = 36
    private var offsetObservation: NSKeyValueObservation?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        _ = layoutManager // Touching layoutManager forces TextKit 1, which the gutter shares.
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _ = layoutManager
        configure()
    }

    private func configure() {
        backgroundColor = .clear
        autocorrectionType = .no
        autocapitalizationType = .none
        smartQuotesType = .no
        smartDashesType = .no
        smartInsertDeleteType = .no
        spellCheckingType = .no
        keyboardAppearance = .dark
        allowsEditingTextAttributes = false
        alwaysBounceVertical = true
        textContainerInset = UIEdgeInsets(top: 12, left: gutterWidthValue + 10, bottom: 24, right: 16)
        textStorage.delegate = self
        applyWrapMode()
        offsetObservation = observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.onScroll?()
            }
        }
    }

    // MARK: Wrap mode

    func setWrapLines(_ wrap: Bool) {
        guard wrap != wrapLines else { return }
        wrapLines = wrap
        applyWrapMode()
    }

    /// Portrait: vertical wrap. Landscape: horizontal scrolling line mode.
    private func applyWrapMode() {
        if wrapLines {
            textContainer.maximumNumberOfLines = 0
            textContainer.widthTracksTextView = true
            alwaysBounceHorizontal = false
            showsHorizontalScrollIndicator = false
        } else {
            textContainer.maximumNumberOfLines = 1
            textContainer.widthTracksTextView = false
            textContainer.size = CGSize(width: 1_000_000, height: 0)
            alwaysBounceHorizontal = true
            showsHorizontalScrollIndicator = true
        }
        let range = NSRange(location: 0, length: textStorage.length)
        layoutManager.invalidateGlyphs(forCharacterRange: range, changeInLength: 0, actualCharacterRange: nil)
        layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        layoutManager.ensureLayout(forCharacterRange: range)
    }

    // MARK: Gutter metrics

    /// Line count drives the gutter width; the text inset follows it.
    func updateGutterMetrics() {
        let source = text ?? ""
        let count = max(source.components(separatedBy: .newlines).count, 1)
        let digits = String(count).count
        let numberFont = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let charWidth = ("0" as NSString).size(withAttributes: [.font: numberFont]).width
        let width = max(34, CGFloat(digits) * ceil(charWidth) + 16)
        if width != gutterWidthValue {
            gutterWidthValue = width
            textContainerInset.left = width + 10
        }
        onMetricsChanged?(count, width)
    }

    // MARK: Undoable programmatic edits

    func performReplace(_ range: NSRange, with replacement: String) {
        guard range.location != NSNotFound,
              range.location >= 0, range.location <= textStorage.length else { return }
        let clamped = NSRange(
            location: range.location,
            length: max(min(range.length, textStorage.length - range.location), 0)
        )
        let previous = textStorage.attributedSubstring(from: clamped).string
        undoManager?.beginUndoGrouping()
        textStorage.replaceCharacters(in: clamped, with: replacement)
        undoManager?.setActionName("Edit")
        undoManager?.registerUndo(withTarget: self) { target in
            target.undoReplace(range: clamped, with: previous)
        }
        undoManager?.endUndoGrouping()
        selectedRange = NSRange(location: clamped.location + (replacement as NSString).length, length: 0)
    }

    private func undoReplace(range: NSRange, with text: String) {
        let location = min(range.location, textStorage.length)
        let clamped = NSRange(location: location, length: max(min(range.length, textStorage.length - location), 0))
        let previous = textStorage.attributedSubstring(from: clamped).string
        textStorage.replaceCharacters(in: clamped, with: text)
        undoManager?.registerUndo(withTarget: self) { target in
            target.undoReplace(range: clamped, with: previous)
        }
    }

    // MARK: Indent engine

    var indentUnit: String {
        if let cached = cachedIndentUnit { return cached }
        let detected = detectIndentUnit()
        cachedIndentUnit = detected
        return detected
    }

    /// Auto-detects tab vs 2-space vs 4-space from the file's own lines.
    private func detectIndentUnit() -> String {
        let source = text ?? ""
        if source.contains("\t") { return "\t" }
        var twoSpaceCount = 0
        var fourSpaceCount = 0
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let leading = line.prefix(while: { $0 == " " }).count
            if leading == 2 { twoSpaceCount += 1 }
            if leading >= 4 { fourSpaceCount += 1 }
        }
        if twoSpaceCount > fourSpaceCount { return "  " }
        if fourSpaceCount > 0 { return "    " }
        return "    "
    }

    func insertTabOrIndentBlock() {
        if selectedRange.length > 0 {
            indentBlock()
        } else {
            insertText(indentUnit)
        }
    }

    func indentBlock() {
        let nsSource = textStorage.string as NSString
        let selection = selectedRange
        guard selection.location <= nsSource.length else { return }
        let clampedSelection = NSRange(
            location: selection.location,
            length: max(min(selection.length, nsSource.length - selection.location), 0)
        )
        var lineStart = 0
        var lineEnd = 0
        nsSource.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: clampedSelection)
        let blockRange = NSRange(location: lineStart, length: max(lineEnd - lineStart, 0))
        guard blockRange.length > 0 else {
            insertText(indentUnit)
            return
        }
        let unit = indentUnit
        let indented = nsSource.substring(with: blockRange)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                let text = String(line)
                return text.isEmpty ? text : unit + text
            }
            .joined(separator: "\n")
        performReplace(blockRange, with: indented)
        selectedRange = NSRange(location: blockRange.location, length: (indented as NSString).length)
    }

    func dedentBlock() {
        let nsSource = textStorage.string as NSString
        let selection = selectedRange
        guard selection.location <= nsSource.length else { return }
        let clampedSelection = NSRange(
            location: selection.location,
            length: max(min(selection.length, nsSource.length - selection.location), 0)
        )
        var lineStart = 0
        var lineEnd = 0
        nsSource.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: clampedSelection)
        let blockRange = NSRange(location: lineStart, length: max(lineEnd - lineStart, 0))
        guard blockRange.length > 0 else { return }
        let unit = indentUnit
        let dedented = nsSource.substring(with: blockRange)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                let text = String(line)
                if text.isEmpty { return text }
                if text.hasPrefix(unit) { return String(text.dropFirst(unit.count)) }
                if text.hasPrefix("\t") { return String(text.dropFirst()) }
                let spaces = text.prefix(while: { $0 == " " })
                return String(text.dropFirst(min(spaces.count, unit.count)))
            }
            .joined(separator: "\n")
        performReplace(blockRange, with: dedented)
        selectedRange = NSRange(location: blockRange.location, length: (dedented as NSString).length)
    }

    /// Newline carries the current line's indentation and adds one indent
    /// unit after `{ ( [ :`; between a bracket pair the closer gets its own line.
    func insertSmartNewline() {
        let nsSource = textStorage.string as NSString
        let selection = selectedRange
        guard selection.location <= nsSource.length else { return }
        var lineStart = 0
        nsSource.getLineStart(&lineStart, end: nil, contentsEnd: nil, for: NSRange(location: selection.location, length: 0))
        let indentation = nsSource
            .substring(with: NSRange(location: lineStart, length: max(selection.location - lineStart, 0)))
            .prefix(while: { $0 == " " || $0 == "\t" })
        let unit = indentUnit
        var insertion = "\n" + indentation
        if selection.length == 0 {
            let previous = selection.location > 0
                ? nsSource.substring(with: nsSource.rangeOfComposedCharacterSequence(at: selection.location - 1))
                : ""
            let next = selection.location < nsSource.length
                ? nsSource.substring(with: nsSource.rangeOfComposedCharacterSequence(at: selection.location))
                : ""
            if ["{", "(", "[", ":"].contains(previous), ["}", ")", "]"].contains(next) {
                insertion += unit + "\n" + indentation
                insertText(insertion)
                selectedRange = NSRange(
                    location: selection.location + (insertion as NSString).length - (indentation as NSString).length - 1,
                    length: 0
                )
                return
            }
            if ["{", "(", "[", ":"].contains(previous) {
                insertion += unit
            }
        }
        insertText(insertion)
    }

    // MARK: Cursor movement

    func moveCursor(_ direction: CursorDirection) {
        let nsSource = (text ?? "") as NSString
        let selection = selectedRange
        switch direction {
        case .left:
            if selection.length > 0 {
                selectedRange = NSRange(location: selection.location, length: 0)
            } else if selection.location > 0 {
                selectedRange = NSRange(
                    location: nsSource.rangeOfComposedCharacterSequence(at: selection.location - 1).location,
                    length: 0
                )
            }
        case .right:
            if selection.length > 0 {
                selectedRange = NSRange(location: NSMaxRange(selection), length: 0)
            } else if selection.location < nsSource.length {
                selectedRange = NSRange(
                    location: NSMaxRange(nsSource.rangeOfComposedCharacterSequence(at: selection.location)),
                    length: 0
                )
            }
        case .up:
            verticalMove(up: true)
        case .down:
            verticalMove(up: false)
        }
        scrollRangeToVisible(selectedRange)
    }

    /// Vertical move that preserves the column by aiming at the current
    /// caret x in the line fragment above or below, clamped to that line.
    private func verticalMove(up: Bool) {
        let nsSource = (text ?? "") as NSString
        let caretPosition = selectedTextRange?.start ?? endOfDocument
        let caret = caretRect(for: caretPosition)
        let lineHeight = max(caret.height, font?.lineHeight ?? 16, 1)
        let targetY = up ? caret.minY - lineHeight * 0.5 : caret.maxY + lineHeight * 0.5
        if up && targetY < 0 {
            selectedRange = NSRange(location: 0, length: 0)
            return
        }
        let containerPoint = CGPoint(
            x: caret.minX - textContainerInset.left - textContainer.lineFragmentPadding,
            y: targetY - textContainerInset.top
        )
        var index = layoutManager.characterIndex(
            for: containerPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil
        )
        if index == NSNotFound || index >= nsSource.length {
            if up {
                var lineStart = 0
                nsSource.getLineStart(
                    &lineStart, end: nil, contentsEnd: nil,
                    for: NSRange(location: max(nsSource.length - 1, 0), length: 0)
                )
                index = lineStart
            } else {
                index = nsSource.length
            }
        } else {
            var lineStart = 0
            var lineEnd = 0
            nsSource.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: NSRange(location: index, length: 0))
            index = min(max(index, lineStart), max(lineEnd - 1, lineStart))
        }
        selectedRange = NSRange(location: index, length: 0)
        scrollRangeToVisible(selectedRange)
    }

    // MARK: Syntax highlighting (line-scoped, incremental)

    private func highlightLines(containing range: NSRange, in storage: NSTextStorage) {
        let nsText = storage.string as NSString
        guard nsText.length > 0 else { return }
        let startLocation = min(max(range.location, 0), nsText.length - 1)
        var lineStart = 0
        var lineEnd = 0
        nsText.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: NSRange(location: startLocation, length: 0))
        var endLineEnd = lineEnd
        if NSMaxRange(range) > lineEnd, NSMaxRange(range) <= nsText.length {
            nsText.getLineStart(
                nil, end: &endLineEnd, contentsEnd: nil,
                for: NSRange(location: min(NSMaxRange(range), nsText.length - 1), length: 0)
            )
        }
        let highlightRange = NSRange(location: lineStart, length: max(endLineEnd - lineStart, 0))
        guard highlightRange.length > 0 else { return }
        isHighlighting = true
        defer { isHighlighting = false }
        storage.removeAttribute(.foregroundColor, range: highlightRange)
        storage.addAttribute(.foregroundColor, value: UIColor(IDETheme.primary), range: highlightRange)
        CodeTokenizer.highlight(storage, range: highlightRange)
    }
}

extension CodeTextView: NSTextStorageDelegate {
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorage.EditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        if editedMask.contains(.editedCharacters), !isHighlighting {
            cachedIndentUnit = nil
            onTextChanged?()
            onCaretMoved?()
            updateGutterMetrics()
            onScroll?()
        }
        guard !isHighlighting else { return }
        highlightLines(containing: editedRange, in: textStorage)
    }
}

// MARK: - Line-number gutter

/// Draws line numbers from the text view's shared NSLayoutManager, offset
/// by contentOffset so it stays pinned while the code scrolls under it.
final class GutterView: UIView {
    weak var textView: CodeTextView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    override func draw(_ rect: CGRect) {
        guard let textView else { return }
        let layoutManager = textView.layoutManager
        let nsText = textView.textStorage.string as NSString

        UIColor(IDETheme.canvas).setFill()
        UIBezierPath(rect: rect).fill()
        if bounds.width > 0 {
            let divider = UIBezierPath()
            divider.move(to: CGPoint(x: bounds.maxX - 0.5, y: 0))
            divider.addLine(to: CGPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
            divider.lineWidth = 1
            UIColor(IDETheme.elevated).setStroke()
            divider.stroke()
        }

        let numberFont = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let inset = textView.textContainerInset
        let scrollOffsetY = textView.contentOffset.y
        let viewportMaxY = scrollOffsetY + textView.bounds.height

        var caretLineStart = -1
        if nsText.length > 0 {
            nsText.getLineStart(
                &caretLineStart, end: nil, contentsEnd: nil,
                for: NSRange(location: min(textView.selectedRange.location, nsText.length - 1), length: 0)
            )
        }

        var charIndex = 0
        var lineNumber = 1
        while charIndex < nsText.length {
            var lineStart = 0
            var lineEnd = 0
            nsText.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: NSRange(location: charIndex, length: 0))
            let lineCharRange = NSRange(location: charIndex, length: max(lineEnd - charIndex, 1))
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineCharRange, actualCharacterRange: nil)
            if glyphRange.location != NSNotFound {
                let fragment = layoutManager.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
                let fragmentTop = fragment.minY + inset.top
                let fragmentBottom = fragment.maxY + inset.top
                if fragmentBottom >= scrollOffsetY && fragmentTop <= viewportMaxY {
                    let numberColor: UIColor = charIndex == caretLineStart ? UIColor(IDETheme.azure) : UIColor(IDETheme.muted)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: numberFont,
                        .foregroundColor: numberColor
                    ]
                    let label = "\(lineNumber)" as NSString
                    let size = label.size(withAttributes: attributes)
                    let numberX = bounds.width - size.width - 10
                    let numberY = fragmentTop - scrollOffsetY + (fragment.height - size.height) / 2
                    label.draw(at: CGPoint(x: numberX, y: numberY), withAttributes: attributes)
                }
            }
            lineNumber += 1
            charIndex = max(lineEnd, charIndex + 1)
        }

        if nsText.length == 0 {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: numberFont,
                .foregroundColor: UIColor(IDETheme.muted)
            ]
            ("1" as NSString).draw(
                at: CGPoint(x: bounds.width - 10 - ("1" as NSString).size(withAttributes: attributes).width, y: inset.top),
                withAttributes: attributes
            )
        }
    }
}

// MARK: - Representables

struct EditorTextView: UIViewRepresentable {
    @Binding var text: String
    let handle: EditorHandle
    let codeSize: CGFloat
    let wrapLines: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> CodeTextView {
        let view = CodeTextView()
        context.coordinator.textView = view
        view.delegate = context.coordinator
        view.onTextChanged = { [weak coordinator = context.coordinator] in coordinator?.textDidChange() }
        view.onCaretMoved = { [weak coordinator = context.coordinator] in coordinator?.caretDidChange() }
        view.onScroll = { [weak coordinator = context.coordinator] in coordinator?.invalidateGutter() }
        view.onMetricsChanged = { [weak coordinator = context.coordinator] count, width in
            coordinator?.publishMetrics(lineCount: count, gutterWidth: width)
        }
        handle.textView = view
        view.updateGutterMetrics()
        return view
    }

    func updateUIView(_ uiView: CodeTextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        let desiredFont = UIFont.monospacedSystemFont(ofSize: codeSize, weight: .regular)
        if uiView.font != desiredFont {
            uiView.font = desiredFont
        }
        let desiredColor = UIColor(IDETheme.primary)
        if uiView.textColor != desiredColor {
            uiView.textColor = desiredColor
        }
        uiView.typingAttributes = [
            .font: desiredFont,
            .foregroundColor: desiredColor
        ]
        uiView.setWrapLines(wrapLines)
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        private let handle: EditorHandle
        private var parent: EditorTextView
        weak var textView: CodeTextView?

        init(_ parent: EditorTextView) {
            self.parent = parent
            self.handle = parent.handle
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            caretDidChange()
        }

        /// Intercepts Return so the newline goes through the indent engine.
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard text == "\n", let codeTextView = textView as? CodeTextView else { return true }
            codeTextView.insertSmartNewline()
            return false
        }

        func textDidChange() {
            guard let textView else { return }
            let value = textView.text ?? ""
            if parent.text != value {
                parent.text = value
            }
            caretDidChange()
        }

        func caretDidChange() {
            guard let textView else { return }
            let source = textView.text ?? ""
            let nsSource = source as NSString
            let location = min(textView.selectedRange.location, nsSource.length)
            let before = nsSource.substring(with: NSRange(location: 0, length: location))
            let parts = before.components(separatedBy: .newlines)
            let line = max(parts.count, 1)
            let column = (parts.last?.count ?? 0) + 1
            if handle.cursorLine != line || handle.cursorColumn != column {
                handle.cursorLine = line
                handle.cursorColumn = column
            }
            handle.invalidateGutter()
        }

        func invalidateGutter() {
            handle.invalidateGutter()
        }

        func publishMetrics(lineCount: Int, gutterWidth: CGFloat) {
            if handle.lineCount != lineCount { handle.lineCount = lineCount }
            if handle.gutterWidth != gutterWidth { handle.gutterWidth = gutterWidth }
        }
    }
}

struct GutterRulerView: UIViewRepresentable {
    let handle: EditorHandle

    func makeUIView(context: Context) -> GutterView {
        let view = GutterView()
        view.textView = handle.textView
        handle.gutter = view
        return view
    }

    func updateUIView(_ uiView: GutterView, context: Context) {
        uiView.textView = handle.textView
        uiView.setNeedsDisplay()
    }
}
