import SwiftUI
import WebKit

/// S14 · Fallback webview. Deliberately not the default surface: it exists for
/// hosts with no native transport, and it labels itself as advanced.
struct WebWorkspaceView: View {
    let urlString: String

    @State private var isLoading = true
    @State private var error: String?
    @State private var reloadToken = UUID()

    private var host: String {
        URL(string: urlString)?.host ?? "remote"
    }

    var body: some View {
        ZStack(alignment: .top) {
            IDETheme.oledBlack.ignoresSafeArea()
            WebView(urlString: urlString, reloadToken: reloadToken, isLoading: $isLoading, error: $error)
                .ignoresSafeArea(edges: .bottom)
            if isLoading {
                ProgressView()
                    .tint(IDETheme.azure)
                    .padding(10)
                    .background(IDETheme.chassis.opacity(0.9), in: Capsule())
                    .padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(IDETheme.amber)
                Text("ADVANCED · \(host)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(IDETheme.secondary)
                    .lineLimit(1)
                Spacer()
                Button {
                    reloadToken = UUID()
                    Haptics.light()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: IDETheme.minimumHitTarget, height: IDETheme.minimumHitTarget)
                }
                .buttonStyle(.plain)
                .foregroundStyle(IDETheme.primary)
                .accessibilityLabel("Reload")
            }
            .padding(.horizontal, IDETheme.pageGutter)
            .frame(height: 44)
            .background(IDETheme.chassis)
            .overlay(alignment: .bottom) { Rectangle().fill(IDETheme.elevated).frame(height: 1) }
        }
        .overlay(alignment: .bottom) {
            if let error {
                Text(error)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(IDETheme.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(IDETheme.coral.opacity(0.18))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebView: UIViewRepresentable {
    let urlString: String
    let reloadToken: UUID
    @Binding var isLoading: Bool
    @Binding var error: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = UIColor(IDETheme.oledBlack)
        view.scrollView.backgroundColor = UIColor(IDETheme.oledBlack)
        if let url = URL(string: normalized) {
            view.load(URLRequest(url: url))
        }
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.loadedToken != reloadToken else { return }
        context.coordinator.loadedToken = reloadToken
        if let url = URL(string: normalized) {
            view.load(URLRequest(url: url))
        }
    }

    /// Adds a scheme when the user typed a bare host, which is what people do.
    private var normalized: String {
        urlString.contains("://") ? urlString : "https://" + urlString
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: WebView
        var loadedToken = UUID()

        init(_ parent: WebView) {
            self.parent = parent
            self.loadedToken = parent.reloadToken
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.error = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.error = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.error = error.localizedDescription
        }
    }
}

/// S15 · Onboarding. Three screens, one idea each, skip always present.
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0

    private struct Page {
        let title: String
        let body: [String]
        let glyph: String
    }

    private let pages: [Page] = [
        Page(
            title: "Your code runs on your server",
            body: [
                "This app is an editor and a client, not a runtime.",
                "Files live on your device or on your host. Nothing compiles here."
            ],
            glyph: "server.rack"
        ),
        Page(
            title: "Connect something",
            body: [
                "GitHub over REST, a folder from Files, or a host over SSH.",
                "Credentials stay in the Keychain."
            ],
            glyph: "link"
        ),
        Page(
            title: "Thumbs, not cursors",
            body: [
                "The 48 pt bar sits in the bottom 35% where your thumb is.",
                "Caret keys, brackets and RUN never cost a keyboard dismissal."
            ],
            glyph: "hand.point.up.left"
        )
    ]

    var body: some View {
        ZStack {
            IDETheme.oledBlack.ignoresSafeArea()
            VStack(alignment: .leading, spacing: IDETheme.minimumGap * 3) {
                HStack {
                    Text("iDE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(IDETheme.secondary)
                    Spacer()
                    Button("Skip") { onFinish() }
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(IDETheme.secondary)
                        .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                }

                Spacer(minLength: 0)

                Image(systemName: pages[page].glyph)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(IDETheme.azure)

                Text(pages[page].title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(IDETheme.primary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(pages[page].body, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: IDETheme.minimumGap) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == page ? IDETheme.azure : IDETheme.muted)
                            .frame(width: 6, height: 6)
                    }
                    Spacer()
                    Button {
                        Haptics.light()
                        if page == pages.count - 1 {
                            onFinish()
                        } else {
                            withAnimation(.easeInOut(duration: 0.12)) { page += 1 }
                        }
                    } label: {
                        Text(page == pages.count - 1 ? "START" : "NEXT")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(0.5)
                            .frame(width: 148, height: IDETheme.recommendedHitTarget)
                            .background(IDETheme.emerald, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(IDETheme.oledBlack)
                }
            }
            .padding(IDETheme.pageGutter)
        }
    }
}
