# Optional: push your work to your own remote

Everything you make today lives in a real git repository at `C:\LabWork`, on
this VM only. **That's fine - you don't need a remote for anything in this
session**, and nothing below is required.

But if you want tonight's work on your own GitHub before you leave the room,
it's three commands plus a token. Here's the neat version.

## Before you push: make the commits yours

The workspace was set up with a placeholder identity. Give your commits your
real name (inside this repo only - no `--global`):

```powershell
cd C:\LabWork
git config user.name "Your Name"
git config user.email "you@example.com"
```

This only affects commits made from now on - fine for today's purposes.

## Connect and push

1. On github.com, create a **new, empty** repository (no README, no
   `.gitignore` - the workspace already has content).
2. Create a token: **Settings → Developer settings → Personal access tokens →
   Fine-grained**, with read/write access to that one repository. GitHub
   stopped accepting account passwords over HTTPS, so this token *is* your
   password in step 3. Give it the shortest expiry offered.
3. Connect and push:

```powershell
cd C:\LabWork
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin HEAD
```

Git asks for credentials on the first push: username = your GitHub username,
password = the token. `HEAD` pushes the branch you're on; push your other
routine branches the same way (`git push -u origin my-first`), or all at once
with `git push -u origin --all`.

## Before you hand the VM back

Windows caches your token in Credential Manager so you won't be asked twice -
convenient for you, and exactly why it must not stay on a shared machine:

```powershell
cmdkey /delete:git:https://github.com
```

(Or let the short expiry from step 2 take care of it.)

## When it goes wrong

- **`Authentication failed`** - you used your account password, or the token
  lacks write access to this repository. Make a new fine-grained token
  scoped to the repo, and run the `cmdkey /delete` line above first so git
  asks again.
- **`Updates were rejected`** - the GitHub repo wasn't empty (it has a README
  or licence). Easiest fix today: create another repo, genuinely empty, and
  `git remote set-url origin <new-url>`.
- **`remote origin already exists`** - you ran step 3 twice. Use
  `git remote set-url origin <url>` instead of `remote add`.

## Not GitHub?

GitLab, Azure DevOps, Bitbucket - same three commands, different URL, and
each has its own token flavour (GitLab: personal access token; Azure DevOps:
PAT). Nothing else changes.

> Working with a colleague rather than solo? Track 3's
> [`pair-workflow.md`](../3-teach-and-scale/pair-workflow.md) is the fuller
> version of this: fork, branches, pull requests and a merge conflict.
