import SwiftUI

/// S2 · Connect — the one form that adds a transport. GitHub first (REST git, no
/// helper binary), then SSH, then the local folder import the home screen owns.
struct ConnectScreen: View {
    let onWorkspace: (Workspace) -> Void
    let onOpenWebIDE: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private struct SSHTrustPrompt {
        let fingerprint: String
        let changed: Bool

        var message: String {
            if changed {
                return "The server presented a different host key. Compare this fingerprint with the server operator before trusting it:\n\(fingerprint)"
            }
            return "This host key has not been verified before. Compare this fingerprint with the server operator before trusting it:\n\(fingerprint)"
        }
    }

    // GitHub
    @State private var token = ""
    @State private var account: String?
    @State private var repositories: [String] = []
    @State private var repository = ""
    @State private var branch = ""
    @State private var githubError: String?
    @State private var githubBusy = false
    @State private var cloning = false

    // GitLab Web IDE
    @State private var gitlabProject = ""
    @State private var gitlabBranch = ""
    @State private var webIDEError: String?

    // SSH
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var remotePath = ""
    @State private var useKey = true
    @State private var privateKey = ""
    @State private var password = ""
    @State private var generatedPublicKey: String?
    @State private var sshError: String?
    @State private var sshBusy = false
    @State private var sshTrustPrompt: SSHTrustPrompt?

    var body: some View {
        Form {
            githubSection
            webIDESection
            sshSection
            advancedSection
        }
        .scrollContentBackground(.hidden)
        .background(IDETheme.canvas)
        .navigationTitle("Connections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .frame(minHeight: IDETheme.minimumHitTarget)
            }
        }
        .task {
            if KeychainStore.read(KeychainStore.githubTokenAccount) != nil {
                await refreshAccount()
            }
            if privateKey.isEmpty, let stored = KeychainStore.read(KeychainStore.sshKeyAccount) {
                privateKey = stored
            }
        }
        .alert("Verify SSH host key", isPresented: Binding(
            get: { sshTrustPrompt != nil },
            set: { if !$0 { sshTrustPrompt = nil } }
        )) {
            Button("Trust fingerprint") {
                guard let prompt = sshTrustPrompt else { return }
                sshTrustPrompt = nil
                Task { await connectSSH(trustedFingerprint: prompt.fingerprint) }
            }
            Button("Cancel", role: .cancel) { sshTrustPrompt = nil }
        } message: {
            Text(sshTrustPrompt?.message ?? "")
        }
    }

    private var webIDESection: some View {
        Section {
            Text("Open a remote editor in the embedded browser. Sign in with the provider if asked.")
                .font(.system(size: 13))
                .foregroundStyle(IDETheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .listRowBackground(IDETheme.chassis)

            Text("Use the GitHub repository and branch above to start or resume a Codespace, or open your Codespaces list.")
                .font(.system(size: 12))
                .foregroundStyle(IDETheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .listRowBackground(IDETheme.chassis)

            secondaryActionButton("Open GitHub Codespaces", action: openCodespaces)
                .listRowBackground(IDETheme.chassis)

            Text("Creating or resuming a Codespace may incur GitHub usage charges.")
                .font(.system(size: 12))
                .foregroundStyle(IDETheme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .listRowBackground(IDETheme.chassis)

            TextField("GitLab project URL or group/project", text: $gitlabProject)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .listRowBackground(IDETheme.chassis)

            TextField("Branch (optional)", text: $gitlabBranch)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .listRowBackground(IDETheme.chassis)

            secondaryActionButton("Open in GitLab Web IDE", action: openGitLabWebIDE)
                .disabled(gitlabWebIDEURL == nil)
                .opacity(gitlabWebIDEURL == nil ? 0.45 : 1)
                .listRowBackground(IDETheme.chassis)

            if let webIDEError {
                errorRow(webIDEError)
            }
        } header: {
            header("Web IDEs")
        } footer: {
            Text("GitLab accepts a project URL or namespace/project path. Leave the branch blank to use the project's default branch.")
                .font(.system(size: 12))
                .foregroundStyle(IDETheme.muted)
        }
    }

    private func secondaryActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: IDETheme.recommendedHitTarget)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(IDETheme.secondary.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(IDETheme.secondary)
        .listRowBackground(IDETheme.chassis)
    }

    private var gitlabWebIDEURL: URL? {
        WebIDEURLBuilder.gitLab(projectURL: gitlabProject, branch: gitlabBranch)
    }

    private func openCodespaces() {
        webIDEError = nil
        let input = repository.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            onOpenWebIDE("https://github.com/codespaces")
            dismiss()
            return
        }

        do {
            let parsed = try Self.parseRepository(input)
            guard let url = WebIDEURLBuilder.codespaces(
                owner: parsed.owner,
                repo: parsed.repo,
                branch: branch.trimmingCharacters(in: .whitespacesAndNewlines)
            ) else {
                webIDEError = "Enter a GitHub repository as owner/repository."
                return
            }
            onOpenWebIDE(url.absoluteString)
            dismiss()
        } catch {
            webIDEError = error.localizedDescription
        }
    }

    private func openGitLabWebIDE() {
        guard let url = gitlabWebIDEURL else {
            webIDEError = "Enter a GitLab project URL or namespace/project path."
            return
        }
        webIDEError = nil
        onOpenWebIDE(url.absoluteString)
        dismiss()
    }

    // MARK: GitHub

    private var githubSection: some View {
        Section {
            if let account {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(IDETheme.emerald)
                    Text("Signed in as \(account)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(IDETheme.primary)
                    Spacer()
                    Button("Sign out") {
                        KeychainStore.remove(KeychainStore.githubTokenAccount)
                        self.account = nil
                        token = ""
                    }
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(IDETheme.coral)
                    .frame(minHeight: IDETheme.minimumHitTarget)
                }
                .listRowBackground(IDETheme.chassis)
            } else {
                SecureField("Personal access token", text: $token)
                    .font(.system(size: 14, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .listRowBackground(IDETheme.chassis)

                // Tokens are 90+ characters; typing one on a phone keyboard is
                // the worst part of connecting. Paste and verify in one tap.
                Button {
                    pasteTokenFromClipboard()
                } label: {
                    Label("Paste token from clipboard", systemImage: "doc.on.clipboard")
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: IDETheme.recommendedHitTarget)
                }
                .buttonStyle(.plain)
                .foregroundStyle(IDETheme.azure)
                .disabled(githubBusy)
                .listRowBackground(IDETheme.chassis)

                Button {
                    Task { await saveToken() }
                } label: {
                    Text(githubBusy ? "Checking…" : "Save token")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: IDETheme.recommendedHitTarget)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(IDETheme.secondary.opacity(0.18), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .foregroundStyle(token.isEmpty ? IDETheme.muted : IDETheme.secondary)
                .disabled(token.isEmpty || githubBusy)
                .listRowBackground(IDETheme.chassis)
            }

            TextField("owner/repository", text: $repository)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .listRowBackground(IDETheme.chassis)

            if !repositories.isEmpty {
                Menu {
                    ForEach(repositories, id: \.self) { name in
                        Button(name) {
                            repository = name
                            Haptics.light()
                        }
                    }
                } label: {
                    Label("Choose from \(repositories.count) repositories", systemImage: "list.bullet")
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: IDETheme.recommendedHitTarget)
                }
                .foregroundStyle(IDETheme.azure)
                .listRowBackground(IDETheme.chassis)
            }

            TextField("Branch (default)", text: $branch)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .listRowBackground(IDETheme.chassis)

            Button {
                Task { await clone() }
            } label: {
                Text(cloning ? "Cloning…" : "Clone workspace")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: IDETheme.recommendedHitTarget)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(IDETheme.secondary.opacity(0.18), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .foregroundStyle(IDETheme.secondary)
            .disabled(account == nil || repository.isEmpty || cloning)
            .listRowBackground(IDETheme.chassis)

            if let githubError {
                errorRow(githubError)
            }
        } header: {
            header("GITHUB · REST GIT")
        } footer: {
            Text("A fine-grained token with Contents: read and write on the repositories you choose. The token is kept in the Keychain.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(IDETheme.muted)
        }
    }

    // MARK: SSH

    private var sshSection: some View {
        Section {
            TextField("host, for example dev.local", text: $host)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .listRowBackground(IDETheme.chassis)

            HStack(spacing: 12) {
                TextField("user", text: $username)
                    .font(.system(size: 14, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("port", text: $port)
                    .font(.system(size: 14, design: .monospaced))
                    .keyboardType(.numberPad)
                    .frame(width: 64)
            }
            .listRowBackground(IDETheme.chassis)

            TextField("/workspace/project", text: $remotePath)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .listRowBackground(IDETheme.chassis)

            Picker("Authentication", selection: $useKey) {
                Text("Private key").tag(true)
                Text("Password").tag(false)
            }
            .pickerStyle(.segmented)
            .listRowBackground(IDETheme.chassis)

            if useKey {
                Button {
                    let generated = OpenSSHKey.generate()
                    privateKey = generated.privateKey
                    generatedPublicKey = generated.publicKey
                    try? KeychainStore.save(generated.privateKey, for: KeychainStore.sshKeyAccount)
                } label: {
                    Label("Generate an ed25519 key on device", systemImage: "key.horizontal")
                        .font(.system(size: 13, design: .monospaced))
                        .frame(minHeight: IDETheme.recommendedHitTarget)
                }
                .buttonStyle(.plain)
                .foregroundStyle(IDETheme.azure)
                .listRowBackground(IDETheme.chassis)

                if let generatedPublicKey {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PUBLIC KEY · ADD TO authorized_keys")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                        Text(generatedPublicKey)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(IDETheme.primary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Button {
                            UIPasteboard.general.string = generatedPublicKey
                            Haptics.light()
                        } label: {
                            Text("Copy public key")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(minHeight: IDETheme.minimumHitTarget)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(IDETheme.azure)
                    }
                    .listRowBackground(IDETheme.chassis)
                }

                TextEditor(text: $privateKey)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(minHeight: 88)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if privateKey.isEmpty {
                            Text("-----BEGIN OPENSSH PRIVATE KEY-----")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(IDETheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .listRowBackground(IDETheme.chassis)
                    .onChange(of: privateKey) { _, newValue in
                        if !newValue.isEmpty {
                            try? KeychainStore.save(newValue, for: KeychainStore.sshKeyAccount)
                            KeychainStore.remove(KeychainStore.sshPasswordAccount)
                        }
                    }
            } else {
                SecureField("Password", text: $password)
                    .font(.system(size: 14, design: .monospaced))
                    .listRowBackground(IDETheme.chassis)
                    .onChange(of: password) { _, newValue in
                        if !newValue.isEmpty {
                            try? KeychainStore.save(newValue, for: KeychainStore.sshPasswordAccount)
                        }
                    }
            }

            Button {
                Task { await connectSSH() }
            } label: {
                Text(sshBusy ? "Connecting…" : "Connect host")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: IDETheme.recommendedHitTarget)
                    .background(canConnect ? IDETheme.emerald : IDETheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(canConnect ? IDETheme.oledBlack : IDETheme.muted)
            .disabled(!canConnect || sshBusy)
            .listRowBackground(IDETheme.chassis)

            if let sshError {
                errorRow(sshError)
            }
        } header: {
            header("SSH · swift-nio-ssh")
        } footer: {
            Text("Verify the host fingerprint before trusting it. A changed key requires a fresh out-of-band check.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(IDETheme.muted)
        }
    }

    // MARK: Advanced

    private var advancedSection: some View {
        Section {
            Button {
                dismiss()
            } label: {
                Text("Advanced web workspace lives in Settings")
                    .font(.system(size: 13))
                    .frame(minHeight: IDETheme.minimumHitTarget)
            }
            .buttonStyle(.plain)
            .foregroundStyle(IDETheme.secondary)
            .listRowBackground(IDETheme.chassis)
        } header: {
            header("ADVANCED")
        } footer: {
            Text("Set a custom remote development URL in Settings. GitHub Codespaces and GitLab Web IDE open from Web IDEs above.")
                .font(.system(size: 12))
                .foregroundStyle(IDETheme.muted)
        }
    }

    // MARK: Pieces

    private func header(_ text: String) -> some View {
        let title: String
        switch text {
        case "GITHUB · REST GIT": title = "GitHub"
        case "SSH · swift-nio-ssh": title = "SSH"
        case "ADVANCED": title = "Advanced"
        default: title = text
        }
        return Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(IDETheme.secondary)
            .textCase(nil)
    }

    private func errorRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(IDETheme.coral)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(IDETheme.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .listRowBackground(IDETheme.chassis)
    }

    private var canConnect: Bool {
        !host.isEmpty && !username.isEmpty && !remotePath.isEmpty &&
            (useKey ? !privateKey.isEmpty : !password.isEmpty)
    }

    // MARK: Actions

    private func refreshAccount() async {
        guard let token = GitHubClient.storedToken, !token.isEmpty else { return }
        do {
            let client = GitHubClient(token: token)
            account = try await client.currentUser()
            repositories = (try? await client.repositories()) ?? []
        } catch {
            githubError = error.localizedDescription
        }
    }

    private func pasteTokenFromClipboard() {
        guard let pasted = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines), !pasted.isEmpty else {
            githubError = "The clipboard is empty. Copy the token from GitHub first."
            return
        }
        token = pasted
        Haptics.light()
        Task { await saveToken() }
    }

    private func saveToken() async {
        githubBusy = true
        githubError = nil
        defer { githubBusy = false }
        do {
            let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
            let client = GitHubClient(token: trimmed)
            let login = try await client.currentUser()
            try KeychainStore.save(trimmed, for: KeychainStore.githubTokenAccount)
            account = login
            repositories = (try? await client.repositories()) ?? []
            token = ""
            Haptics.success()
        } catch {
            githubError = error.localizedDescription
        }
    }

    private func clone() async {
        cloning = true
        githubError = nil
        defer { cloning = false }
        do {
            let parsed = try Self.parseRepository(repository)
            let (binding, name) = try await WorkspaceSync.shared.cloneGitHub(
                owner: parsed.owner,
                repo: parsed.repo,
                branch: branch.trimmingCharacters(in: .whitespaces)
            )
            let id = "github:\(binding.owner)/\(binding.repo)@\(binding.branch)"
            var library = WorkspaceLibrary.load()
            library.storeGithub(id: id, name: name, binding: binding)
            library.save()

            let workspace = Workspace(
                id: id,
                name: name,
                rootURL: WorkspaceStorage.workspaceDirectory(for: id),
                github: binding
            )
            onWorkspace(workspace)
            Haptics.success()
            dismiss()
        } catch {
            githubError = error.localizedDescription
        }
    }

    private func connectSSH(trustedFingerprint: String? = nil) async {
        sshBusy = true
        sshError = nil
        defer { sshBusy = false }
        do {
            let auth: SSHConnection.Auth = useKey ? .privateKey(privateKey) : .password(password)
            let result = try await WorkspaceSync.shared.connectSSH(
                host: host.trimmingCharacters(in: .whitespaces),
                port: Int(port) ?? 22,
                username: username.trimmingCharacters(in: .whitespaces),
                remotePath: remotePath.trimmingCharacters(in: .whitespaces),
                auth: auth,
                trustedFingerprint: trustedFingerprint
            )
            let binding = SSHBinding(
                host: host.trimmingCharacters(in: .whitespaces),
                port: Int(port) ?? 22,
                username: username.trimmingCharacters(in: .whitespaces),
                remotePath: remotePath.trimmingCharacters(in: .whitespaces)
            )
            let id = "ssh:\(binding.username)@\(binding.host):\(binding.port)/\(binding.remotePath)"
            var library = WorkspaceLibrary.load()
            library.storeSSH(id: id, name: result.name, binding: binding, fingerprint: result.fingerprint)
            library.save()

            let workspace = Workspace(
                id: id,
                name: result.name,
                rootURL: WorkspaceStorage.workspaceDirectory(for: id),
                ssh: binding
            )
            onWorkspace(workspace)
            Haptics.success()
            dismiss()
        } catch let error as SSHError {
            switch error {
            case .untrustedHostKey(let observed):
                sshTrustPrompt = SSHTrustPrompt(fingerprint: observed, changed: false)
            case .hostKeyChanged(_, let observed):
                sshTrustPrompt = SSHTrustPrompt(fingerprint: observed, changed: true)
            default:
                sshError = error.localizedDescription
            }
        } catch {
            sshError = error.localizedDescription
        }
    }

    private static func parseRepository(_ text: String) throws -> (owner: String, repo: String) {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("git@github.com:") {
            value = String(value.dropFirst("git@github.com:".count))
        } else if value.contains("://") {
            guard let components = URLComponents(string: value),
                  components.scheme?.lowercased() == "https",
                  components.host?.lowercased() == "github.com",
                  components.user == nil,
                  components.password == nil else {
                throw GitHubError.transport("Use a GitHub repository URL or owner/repository path.")
            }
            value = components.path
        } else if value.hasPrefix("github.com/") {
            value = String(value.dropFirst("github.com/".count))
        }
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if value.hasSuffix(".git") { value.removeLast(4) }
        let parts = value.split(separator: "/").map(String.init)
        guard parts.count >= 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            throw GitHubError.transport("Use owner/repository, for example ykz2111/iVisualStudio.")
        }
        return (parts[0], parts[1])
    }
}
