# Mobile Workflow — editing iVisualStudio from an iPad

The repository is hosted on two remotes so that any device with a git client
can read, edit, and push without depending on Dropbox:

- **GitHub**: `https://github.com/ykz2111/iVisualStudio.git`
- **GitLab**: `https://gitlab.com/groove-labz/iVisual-Studio.git`

(The old README URL `gitlab.com/ykz2111/codespaced` is a typo — the actual
project path is `groove-labz/iVisual-Studio` with a hyphen.)

## What this replaces

Previously, the only iPad-accessible copy was a Dropbox file mirror. Two
problems with that:

1. iPad has no git client that bridges through a Dropbox folder.
2. The Dropbox cloud-shim filesystem (`~/Library/CloudStorage/Dropbox-…`)
   breaks POSIX atomic-rename, so a real `.git` directory will not survive
   there — see `bin/refresh-dropbox` for the rationale.

This document covers the Working Copy flow that replaces it.

## Recommended iOS client: Working Copy

> [App Store — Working Copy](https://apps.apple.com/app/working-copy-git-client/id896694807)

Working Copy is the only iPad/iPhone Git client that does private cloning,
in-place editing, and authenticated push without a desktop relay. The Pro
add-on is required to push to private repos; this repo is **public**, so the
free tier is sufficient.

### One-time install

1. Install **Working Copy** from the App Store.
2. Open it. It registers itself as a Files-provider location (you will see
   "Working Copy" inside the iOS Files app under Locations).
3. Create a **Personal Access Token** on whichever remote you want to push
   to. (You only need one; the other remote will be added as a second
   fetch/push URL after the first clone.)

   - **GitHub**: Settings → Developer settings → Personal access tokens →
     Fine-grained tokens → generate. Scope: `Contents: Read and write` on
     this repository. Expiration: pick whatever feels right; I rotate mine
     annually.
   - **GitLab**: User Settings → Access Tokens → generate. Scope:
     `api`, `read_repository`, `write_repository`. Expiration: annual.

   Treat the token like a password. It will only display once. Paste it
   into Working Copy when prompted for the remote URL — Working Copy stores
   it in the iOS Keychain.

### Clone the repo on the iPad

In Working Copy:

1. **+** → **Clone repository**.
2. URL: `https://github.com/ykz2111/iVisualStudio.git`
3. Branch: `main` for read; `bugfix/studio-injection-and-symlinks` if you
   are actively working on that branch.
4. Authentication: paste the GitHub PAT.

The first clone pulls the entire repo (~6 MB pack + brand assets) — fast on
any reasonable connection. After that, Working Copy works fully offline:
you can browse `brand/`, preview `ide-mobile-studio.html` in Safari via the
share sheet, edit `tokens.css` in any text editor that supports Files
providers, and run `git log` / `git diff` natively.

### Push back from the iPad

After making changes and committing in Working Copy:

- **Pull** before you push, if you have not pulled in a while.
- **Push** to the remote you authenticated with.

To also land the commit on the second remote, add it as a remote in
Working Copy's repository settings and push there too — or wait until you
are back at the Mac, where `bin/double-push` handles both remotes in one
shot (see below).

## On the Mac

The day-to-day commit workflow at `~/CODING/IVS`:

```bash
git add <paths>
git commit -m "feat: ..."
# post-commit hook fires bin/double-push → both remotes
```

Or run it explicitly:

```bash
bin/double-push
```

### What `bin/double-push` does

Pushes the current branch to `origin` (GitHub), then `gitlab` (GitLab). If
either push fails, the local commit is preserved and the script tells you
exactly which remote rejected it — the commit does **not** silently land on
only one host. Re-run after fixing.

### Optional: mirror into Dropbox

If you also want the brand assets to appear in the Mac's Dropbox folder for
casual browsing:

```bash
bin/refresh-dropbox
```

This is **best-effort, one-way, files-only**. It does not put a `.git` in
the Dropbox folder (the filesystem can't host one). The remote repos
remain the source of truth. If you push on the Mac and then forget to
refresh, the Dropbox mirror is stale until you run the script again —
that is the only acceptable behavior on this filesystem.

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `git push` failed: 403 / PAT scope missing | Token scope wrong | Regenerate token with Contents Read+Write |
| `bin/double-push` stops after first push | Network blip / GitLab unreachable | Re-run after connectivity returns; local commit preserved |
| Dropbox mirror files missing | Mid-flight rsync + Dropbox sync collision | Re-run `bin/refresh-dropbox` |
| Packfile errors in Dropbox-side `.git` | The filesystem refused a rename | Move `.git` to APFS; only mirror files via `bin/refresh-dropbox` |
| iPad cannot push | Working Copy not configured with PAT, or repo is private | Generate PAT as above; this repo is public so free Working Copy is fine |

## Why two remotes?

The user's README states *"one repository, one iVisualStudio remote,
pushed to two hosts"*. The two-host mirror is a free disaster-recovery
move — losing GitHub or GitLab in isolation won't lose the work — and it
gives two independent CI/event-stream surfaces if you ever wire either
up. `bin/double-push` keeps the two in lockstep on a per-commit basis.
