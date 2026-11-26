import SwiftUI

/// S13 · Settings, and the one place the Advanced webview toggle lives.
struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("ide.haptics.enabled") private var haptics = true
    @AppStorage("ide.editor.codeSize") private var codeSize = 13.5
    @AppStorage("ide.advanced.webview") private var advancedWeb = false
    @AppStorage("ide.advanced.webURL") private var webURL = ""
    @AppStorage("ide.lsp.command") private var lspCommand = ""
    @AppStorage("ide.assist.endpoint") private var assistEndpoint = ""
    @AppStorage("ide.assist.model") private var assistModel = ""
    @State private var assistKey = KeychainStore.read("assist.key") ?? ""

    var body: some View {
        Form {
            Section("Editor") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Code size")
                        Spacer()
                        Text("\(Int(codeSize)) pt")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                    }
                    Slider(value: $codeSize, in: 11...20, step: 1)
                        .tint(IDETheme.azure)
                }
                .listRowBackground(IDETheme.chassis)

                Toggle(isOn: $haptics) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Haptics")
                        Text("Light on keys, success on push")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                    }
                }
                .tint(IDETheme.emerald)
                .listRowBackground(IDETheme.chassis)
            }
            .font(.system(size: 15))

            Section {
                Toggle(isOn: $advancedWeb) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Web workspace")
                        Text("Remote VS Code in WebKit, never the default surface")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                    }
                }
                .tint(IDETheme.azure)
                .listRowBackground(IDETheme.chassis)

                if advancedWeb {
                    TextField("https://host/?folder=/workspace", text: $webURL)
                        .font(.system(size: 13, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .listRowBackground(IDETheme.chassis)
                }

                TextField("Language server command", text: $lspCommand)
                    .font(.system(size: 13, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .listRowBackground(IDETheme.chassis)

                TextField("Model endpoint", text: $assistEndpoint)
                    .font(.system(size: 13, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .listRowBackground(IDETheme.chassis)

                TextField("Model name", text: $assistModel)
                    .font(.system(size: 13, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .listRowBackground(IDETheme.chassis)

                SecureField("Model key (optional)", text: $assistKey)
                    .font(.system(size: 13, design: .monospaced))
                    .listRowBackground(IDETheme.chassis)
                    .onChange(of: assistKey) { _, newValue in
                        if newValue.isEmpty {
                            KeychainStore.remove("assist.key")
                        } else {
                            try? KeychainStore.save(newValue, for: "assist.key")
                        }
                    }
            } header: {
                Text("ADVANCED")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(IDETheme.secondary)
            } footer: {
                Text("The native editor is what makes this app shippable (guideline 4.2). The webview is for a host with no native transport. lpBOT sends only the selection, to the endpoint you name.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(IDETheme.muted)
            }

            Section {
                Button(role: .destructive) {
                    KeychainStore.remove(KeychainStore.githubTokenAccount)
                    KeychainStore.remove(KeychainStore.sshKeyAccount)
                    KeychainStore.remove(KeychainStore.sshPasswordAccount)
                    Haptics.medium()
                } label: {
                    Text("Erase stored credentials")
                        .frame(minHeight: IDETheme.recommendedHitTarget)
                }
                .listRowBackground(IDETheme.chassis)
            } header: {
                Text("CREDENTIALS")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(IDETheme.secondary)
            } footer: {
                Text("Removes the GitHub token and the SSH key or password from the Keychain. Workspaces stay on device. No account exists, so there is nothing else to delete (5.1.1(v)).")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(IDETheme.muted)
            }

            Section("ABOUT") {
                LabeledContent("Version", value: Bundle.main.appVersion)
                LabeledContent("Editor", value: "Native UIKit text view")
                LabeledContent("SSH", value: "swift-nio-ssh")
                LabeledContent("Fonts", value: "System mono")
            }
            .font(.system(size: 13, design: .monospaced))
        }
        .scrollContentBackground(.hidden)
        .background(IDETheme.canvas)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .frame(minHeight: IDETheme.minimumHitTarget)
            }
        }
    }
}

extension Bundle {
    var appVersion: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
