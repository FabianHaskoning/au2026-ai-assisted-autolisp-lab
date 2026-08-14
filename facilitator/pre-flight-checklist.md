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
answering** and how fast, the Continue.dev and Claude Code configs, the helper
commands in both PowerShell versions, the workspace contents, the desktop
shortcut, and a `New-Routine` smoke test against a temp workspace.

Any FAIL names its own fix. If it doesn't get you there, see
[`troubleshooting.md`](troubleshooting.md).

## 2. The part no script can check

- [ ] **AutoCAD 2026 launches** and opens a blank drawing
- [ ] **Civil 3D 2026 launches**
- [ ] The **START HERE** desktop shortcut opens VS Code on `C:\LabWork` with
      `START-HERE.md` showing, no error banners
- [ ] `Ctrl+Shift+V` renders that file readably (this is the first thing every
      attendee does)
- [ ] `Ctrl+L` opens the Continue.dev panel and a trivial prompt gets a reply,
      with the expected model name shown in the panel
- [ ] Load `C:\LabWork\tracks\1-first-routine\examples\hello-world.lsp` via
      `APPLOAD` and run `HELLO` - **the exact first thing Track 1 asks for**
- [ ] Sign off: initials + timestamp

## 3. Then, from your own machine

```powershell
.\verification\Get-LabReports.ps1
```

- [ ] Every VM in the fleet reports **PASS** (the script exits non-zero if not)

That's the go/no-go.
