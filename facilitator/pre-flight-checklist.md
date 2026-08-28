# Pre-flight checklist

Run per VM (or per representative sample of a batch) shortly before doors
open. Under two minutes.

## 1. Let the script do the checkable part

```powershell
git pull
.\verification\Invoke-LabSelfTest.ps1
.\verification\Publish-LabReport.ps1
```

- [ ] Self-test summary is **PASS** (a WARN is acceptable only once you've
      read the reason and accepted it)
- [ ] The report published without a credentials error

That single run covers what used to be seven boxes here: hardware and tooling,
Ollama serving, every expected model pulled by exact tag, **the model actually
answering** and how fast, the Continue.dev and Claude Code configs, the
workspace contents (including the `how-to/` cards, both showcases, the
ready-made `my-work\` folders and `.vscode\settings.json`), and the desktop
shortcut. The two git-helper checks are WARN-only now — the session is
terminal-free, so a broken helper isn't a reason to hold a VM back.

Any FAIL names its own fix. If it doesn't get you there, see
[`troubleshooting.md`](troubleshooting.md).

## 2. The part no script can check

- [ ] **AutoCAD 2026 launches** and opens a blank drawing
- [ ] **Civil 3D 2026 launches**
- [ ] The **START HERE** desktop shortcut opens VS Code on `C:\LabWork` with
      `START-HERE.md` showing, no error banners
- [ ] Load `C:\LabWork\tracks\1-first-routine\examples\hello-world.lsp` via
      `APPLOAD` and run `HELLO` - **the exact first thing Track 1 asks for**
- [ ] Sign off: initials + timestamp

## 2b. Walk the click paths

**Do this once, carefully, on a real VM.** Every instruction an attendee reads
is written as "click here, then here". Those paths were written against the
standard VS Code menus — they have never been observed on this image. If one of
them is wrong, 60-90 people hit it simultaneously.

Work through this list as an attendee would, using **only the mouse**:

- [ ] `START-HERE.md` opens as a **rendered page**, not raw markdown, and the
      three track links are clickable. *(If it opens as raw text,
      `C:\LabWork\.vscode\settings.json` didn't take — see
      [`troubleshooting.md`](troubleshooting.md).)*
- [ ] Every link on `START-HERE.md` goes somewhere real: the three tracks, the
      six `how-to/` cards, `showcase/`, `optional/`
- [ ] The **AI Assistants** folder is on the desktop, and at least one shortcut
      in it opens its assistant in Edge with a usable sign-in or free tier —
      **this is the primary path now**, so this one is a hard stop if it fails
- [ ] The **Source Control** icon in the left-hand strip shows **no number
      badge** *(if it does, see "Already-captured template?" below)*
- [ ] Optional, WARN-level: the **Continue** icon (not the play-button-with-a-bug
      icon — that's Run and Debug) opens its panel and a trivial prompt gets a
      reply. The docs no longer depend on it, so a silent panel doesn't hold
      the VM back — but note it on the sign-off.
- [ ] `C:\LabWork\my-work\routine-1\` exists in the Explorer with four
      correctly-named `.lsp` files
- [ ] **File → Save** is where the tracks say it is
- [ ] In the Explorer, click `my-work\rules-experiment\baseline.lsp`, Ctrl+click
      `after.lsp`, right-click → **Compare Selected** appears and opens a diff
- [ ] Open any file, edit and save it twice, then find **Timeline** at the
      bottom of the Explorer; right-click an entry → **Restore Contents** is
      there
- [ ] **View → Command Palette…** exists in the menu bar (the fallback route
      the docs use for Reload Window and Open Preview)

## Already-captured template showing a number on Source Control?

A template provisioned with an older script only committed the workspace on
its very first run, so a re-provisioned image can carry dozens of uncommitted
files — VS Code then shows them as a number badge ("49") to every attendee.
Current provisioning commits on every run; on a template you don't want to
re-provision, fix it by hand once and re-capture:

```powershell
git -C C:\LabWork add -A
git -C C:\LabWork commit -m "Refresh lab workspace"
```

Then add these two lines to `C:\LabWork\.vscode\settings.json` (current
provisioning writes them for you):

```json
"git.countBadge": "off",
"git.decorations.enabled": false
```

Open VS Code via the START HERE shortcut, confirm the Source Control icon has
no number, and **Capture**.

## 3. Then, from your own machine

```powershell
.\verification\Get-LabReports.ps1
```

- [ ] Every VM in the fleet reports **PASS** (the script exits non-zero if not)

That's the go/no-go.
