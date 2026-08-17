# verification

How we know the fleet is actually ready, instead of hoping it is.

Two loops meet in this repo. One validates the **content** on every push;
the other validates each **VM** and reports back through the same git remote.

```text
  repo push ──> GitHub Actions ──> markdownlint
                                   PSScriptAnalyzer
                                   Test-RepoConsistency.ps1

  lab VM ────> Invoke-LabSelfTest.ps1 ──> report.json / report.md
                        │
                        └─> Publish-LabReport.ps1 ──> branch: vm-reports
                                                            │
  your laptop <────────────── Get-LabReports.ps1 <──────────┘
```

## On a lab VM

```powershell
cd <repo>
git pull
.\verification\Invoke-LabSelfTest.ps1
.\verification\Publish-LabReport.ps1
```

`Invoke-LabSelfTest.ps1` is **read-only** apart from its own report and a
throwaway temp workspace. It never touches the attendee workspace, never pulls
a model, and never changes configuration - so it is safe on a VM about to be
handed over.

**A FAIL means do not hand this VM to an attendee.** A WARN means it will work
but something is off; read the reason.

| # | Check | Why it's here |
| --- | --- | --- |
| 1 | Hardware, tooling, AutoCAD/Civil 3D | Delegated to `Test-LabVMSpecs.ps1` - one definition of "right image" |
| 2 | Ollama reachable | Distinguishes "not installed" from "installed but not serving" |
| 3 | Expected models pulled, by exact tag | A near-miss tag (`:4b` vs `:4b-instruct`) fails at the first prompt |
| 4 | **Model actually generates a response** | The one the manual checklist can't do at fleet scale. Times load and generation separately |
| 5 | Continue.dev config points at pulled models | The most common single cause of "the assistant is broken" |
| 6 | Claude Code routed to local Ollama | Otherwise attendees hit an Anthropic sign-in wall |
| 7 | Helpers wired into **both** PowerShell versions | 5.1 and 7+ share neither module path nor profile |
| 8 | Workspace complete + desktop shortcut | Every path `START-HERE.md` and Track 1 promise |
| 9 | `New-Routine` smoke test | Against a **temp** workspace, so no stray branch is left behind |
| 10 | Ollama warm-start configured | Without it the first prompt after a boot costs ~90s - and that is Track 1's opening step |
| 11 | Example `.lsp` files parse | An example that won't `APPLOAD` wastes 80 people's first ten minutes |

### What check 4 learned on the real VM

Two measurements shaped how it reports, and both are worth knowing:

**Thinking is expensive.** `qwen3.5:4b` is a reasoning model. Asked to say
hello it spent **222 tokens and 31.8s** thinking, to produce "Hello there!".
With `think=false`: **10 tokens, 2.1s**, an equally good answer. The check now
asks for thinking off, falling back to a default request because Ollama
rejects the field on models that don't support it.

**Loading is not generating.** A first call after boot took **90.7s total -
~88s loading the model off cold disk, 2.0s generating**. Later calls were ~2s
at ~17 tok/s, and the model stayed resident across an idle gap. Wall-clock
alone blamed inference for a disk read, so load, generation and tokens/sec are
reported separately and warned on for their own reasons.

That cold load is a once-per-boot cost, which is why check 10 exists: it lands
on an attendee's very first prompt unless something warms the model first.

`-SkipGeneration` skips check 4 when you're re-testing something else, at the
cost of a WARN recording that the model was never exercised.

### Publishing

`Publish-LabReport.ps1` commits the report to `reports/<vm-name>/<timestamp>`
on a **`vm-reports`** branch and pushes it. That branch is orphaned on purpose:
it shares no history with `master`, holds no source, and is never merged - a
mailbox, not code.

It refuses to run with uncommitted changes in the tree, because publishing
switches branches and won't do that over someone's work.

**Credentials.** The first push from a VM needs auth. Easiest is
`gh auth login` (HTTPS, "Login with a web browser" - it prints a code to paste
into the browser on the VM). Otherwise push manually with a personal access
token as the password. The report is committed locally either way, so a failed
push never loses it - re-run with `-UseExistingReport` afterwards.

Facilitators publish. **Attendees never push anything.**

## From your own machine

```powershell
.\verification\Get-LabReports.ps1            # newest report per VM
.\verification\Get-LabReports.ps1 -Detailed  # with the failing checks and why
```

It reads the branch via `git show` without checking it out, so it's safe to run
mid-edit. **Exit code 1 if any VM's latest run is FAIL**, so it can gate a
go/no-go decision rather than just informing one.

## Validating the repo itself

```powershell
.\verification\Test-RepoConsistency.ps1
```

Catches what markdownlint and PSScriptAnalyzer can't:

1. **Relative markdown links resolve.** Including from `attendee/`, which is
   copied to `C:\LabWork` - a link that works in the repo but not on the VM is
   a broken link for 60-90 people.
2. **The root README folder map matches reality.** A folder missing from it is
   invisible; a row pointing at a deleted folder is a lie.
3. **Files the provisioning scripts copy exist.** A rename would otherwise
   surface as a provisioning failure on the VM, hours before doors open.
4. **Model tags in docs match the decision table.** Docs naming a tag that was
   never pulled send a facilitator chasing nothing.
5. **Every `.lsp` has balanced parentheses** (`Test-LispBalance.ps1`, shared
   with check 10 above).

There is deliberately **no blocklist of removed feature names** in it. Anything
deleted from the repo already fails checks 1-3, and a blocklist would have to
be maintained and reverted alongside every scope change.

## Before the session

1. `Test-RepoConsistency.ps1` green locally, CI green on the branch.
2. Self-test PASS on the template VM, published.
3. `Get-LabReports.ps1` shows every VM in the fleet as PASS.
4. Then the short manual list in
   [`facilitator/pre-flight-checklist.md`](../facilitator/pre-flight-checklist.md)
   for what no script can check - AutoCAD and Civil 3D actually launching, VS
   Code opening cleanly, and the desktop shortcut doing what it should.
