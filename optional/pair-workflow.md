# Two people, one routine

> **This is the only page in the workshop that uses git and a terminal.** It's
> Track 3, Part D, and it's optional — nothing else depends on it. If you'd
> rather not, you lose nothing. New to git?
> [Git, if you want it](git-if-you-want-it.md) is the gentler start.

About 25 minutes. The smallest complete git loop that lets two engineers work
on the same AutoLISP routine without one of them overwriting the other.

Pick **one** path:

- **Path A - with a colleague, via GitHub.** Realistic, and it contributes
  something back to this repo. Needs a GitHub account (free, 2 minutes to
  create) and someone else in the room to pair with.
- **Path B - on your own, offline.** Same git mechanics against a second clone
  on this VM. No account needed. Do this if you're working alone or GitHub is
  blocked.

Both teach the same four moves: **branch, review, merge, resolve a conflict.**

---

## Path A - With a colleague, via GitHub

### A1. Fork the repo (3 min)

One of you opens the browser on the VM and goes to:

```text
https://github.com/FabianHaskoning/au2026-ai-assisted-autolisp-lab
```

Click **Fork** (top right). That makes your own copy. Then clone it:

```powershell
cd C:\
git clone https://github.com/<your-username>/au2026-ai-assisted-autolisp-lab.git C:\LabFork
cd C:\LabFork
```

Add your partner as a collaborator: on your fork's GitHub page,
**Settings → Collaborators → Add people**. They accept, then clone the same
URL.

> Git will ask for GitHub credentials on your first push. Use a **personal
> access token** as the password, not your account password - GitHub stopped
> accepting passwords over HTTPS. Create one at
> **Settings → Developer settings → Personal access tokens → Fine-grained**,
> with write access to this one repository.

### A2. Each take a branch (5 min)

**Person 1:**

```powershell
cd C:\LabFork
git checkout -b add-my-rules
```

Add a rules file at `my-rules/07-<yourcompany>.md` - your real
layer naming or text-height conventions from Track 3 Part B.

```powershell
git add -A
git commit -m "Add <company> AutoLISP conventions as a rules file"
git push -u origin add-my-rules
```

**Person 2:** same thing, different branch and different file:

```powershell
git checkout -b add-example-routine
```

Add a small commented routine under
`attendee/tracks/1-first-routine/examples/`, commit, and push it on
`add-example-routine`.

### A3. Review each other's work (10 min)

On GitHub, each of you opens a **pull request** from your branch into `master`.

Now **swap**. Open your partner's PR, click **Files changed**, and leave at
least one real comment - click the `+` next to a line to comment on that line
specifically.

Review it like an engineer, not a programmer. Ask:

- Would I be able to work out what this does in six months?
- What happens if it's run on an empty drawing, or run twice in a row?
- Does it change anything it doesn't restore?
- Is there an `*error*` handler?

That's a code review, and it is the entire governance story. You don't need to
read every bracket to catch the things that actually go wrong.

Then approve and **Merge pull request**.

### A4. Make a conflict on purpose (7 min)

Conflicts are the thing that scares people off git. They're much less dramatic
than their reputation.

Both of you, at the same time:

```powershell
git checkout master
git pull
git checkout -b conflict-demo-<your-name>
```

**Both** edit the same line of the same file - the first bullet in
`boilerplate-prompt.md` will do. Write something
different. Both commit and push, both open a PR.

The first PR merges normally. The second says **"This branch has conflicts"**.
To fix it:

```powershell
git checkout master
git pull
git checkout conflict-demo-<your-name>
git merge master
```

Git marks the clash in the file:

```text
<<<<<<< HEAD
your version
=======
their version
>>>>>>> master
```

Delete the three marker lines and leave the text you want - which may be a
blend of both. Then:

```powershell
git add -A
git commit -m "Resolve conflict in prompting habits"
git push
```

The PR goes green. **That's all a conflict is:** git refusing to guess which
of two humans was right, and asking you.

---

## Path B - On your own, offline

Same mechanics, no account, no network. You'll play both people.

### B1. Make a second clone (3 min)

```powershell
cd C:\
git clone C:\LabWork C:\LabWork-colleague
cd C:\LabWork-colleague
git config user.name "Colleague"
git config user.email "colleague@lab.local"
```

`C:\LabWork-colleague` now behaves exactly like a teammate's machine, with
`C:\LabWork` acting as the shared server.

### B2. Both change the same file (8 min)

**As yourself**, in `C:\LabWork`:

```powershell
cd C:\LabWork
git checkout master
New-Routine shared-tool
```

Put something in `shared-tool\shared-tool-core.lsp`, then `save "my version"`.

**As your colleague**, in `C:\LabWork-colleague`:

```powershell
cd C:\LabWork-colleague
git fetch origin
git checkout -b colleague-changes origin/master
```

Create `shared-tool\shared-tool-core.lsp` there too, with *different* content,
then:

```powershell
git add -A
git commit -m "Colleague's version of the shared tool"
```

### B3. Merge and resolve (10 min)

Back in `C:\LabWork`:

```powershell
cd C:\LabWork
git checkout shared-tool
git pull C:\LabWork-colleague colleague-changes
```

Git reports a conflict. Open the file in VS Code - it highlights the clash and
gives you **Accept Current / Accept Incoming / Accept Both** buttons above it.
Pick, or hand-edit, then:

```powershell
save "merged both versions of the shared tool"
```

### B4. See the history you just made (4 min)

```powershell
git log --oneline --graph --all
```

Two lines of work, diverging and coming back together. That picture *is* the
answer to "who changed this and why" - and it's the thing a shared drive can
never give you.

---

## What to take back to work

You don't need GitHub, and you don't need this repo. You need four habits:

| Habit | Why it matters |
| --- | --- |
| **A branch per routine** | Two people can work at once without waiting |
| **Commit early and often** | Every state you liked is recoverable |
| **A pull request before merging** | Someone else looks at it before it's shared |
| **Instruction files in the repo** | Standards get versioned and reviewed like code |

The tooling underneath can be GitHub, Azure DevOps, GitLab, or a bare repo on a
network share. The habits are what carry.

And the two commands you'll actually use every day:

```powershell
git config --global alias.save '!git add -A && git commit -m'
git config --global alias.undo 'reset --soft HEAD~1'
```

That gives you `git save "message"` and `git undo` on any machine, in any
terminal, with any AI tool and any git host.

---

← [Git, if you want it](git-if-you-want-it.md) ·
[Track 3](../tracks/3-teach-and-scale/README.md) ·
[Start here](../START-HERE.md)
