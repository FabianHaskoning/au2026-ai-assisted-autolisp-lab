# Choose your assistant

You can do everything today with the assistant that's already open. But this
VM offers more than one way to talk to an AI, and if you have your own account
with ChatGPT, Claude, Copilot or any other assistant, you're welcome to use it.
This page is the map.

Whatever you pick, the AutoLISP workflow stays identical: ask for code, put it
in a file, `APPLOAD` it in AutoCAD, iterate on the exact error text.

---

## 1. The default: Continue.dev (no account, already set up)

Press **`Ctrl+L`** in VS Code. This is the assistant every track assumes.

- No account, no API key, no cost - the model runs on this machine.
- It has already read the six rules files in `C:\LabWork\.continue\rules\`,
  so it knows about AutoCAD 2026, `*error*` handlers and your git helpers.
- It is slower and smaller than the big-name assistants. Ask for one small,
  concrete thing at a time.

**If the panel doesn't answer within 60 seconds:** raise your hand.

## 2. Also on this VM, no account needed

**Claude Code** - the same coding agent developers use, pointed at the local
model instead of the cloud. Open a PowerShell window and run `claude-local`.
It reads `C:\LabWork\CLAUDE.md` the way Continue.dev reads the rules files.
Only available on the larger VMs; if `claude-local` isn't recognized, this VM
doesn't have it - Continue.dev is unaffected.

**If Claude Code shows an Anthropic sign-in screen instead of a prompt:** in a
new PowerShell window run `local-mode`, then reload VS Code
(`Ctrl+Shift+P` → **Developer: Reload Window**). That points it back at the
local model.

**The Ollama app** - the model behind everything above has its own chat app
(Start menu → **Ollama**). Plain chat, no editor integration. Handy to see
what the raw model does without any rules files helping it.

**Microsoft Copilot** - built into Windows 11 (Start menu → **Copilot**).
Free tier, no login required for basic chat.

## 3. Bring your own account (optional)

If you already pay for - or have free access to - an assistant, use it. Your
account, your quota, your familiar tool.

Desktop apps installed on this VM (Start menu):

- **ChatGPT** (OpenAI account)
- **Claude** (Anthropic account)

The **AI Assistants** folder on the desktop has Microsoft Edge shortcuts for
the rest:

| Assistant | Where it goes |
| --- | --- |
| ChatGPT | chatgpt.com |
| Claude | claude.ai |
| Microsoft Copilot | copilot.microsoft.com |
| Gemini | gemini.google.com |
| Le Chat (Mistral) | chat.mistral.ai |
| Kimi | kimi.com |
| Lumo (Proton) | lumo.proton.me |
| DeepSeek | chat.deepseek.com |
| Perplexity | perplexity.ai |
| Qwen Chat | chat.qwen.ai |

**If a desktop app is missing from the Start menu:** use the matching web
shortcut instead - they do the same thing.

**One caution on a shared machine:** this VM is wiped after the session, but
still - sign out of anything you signed into before you leave, and don't
paste confidential drawing data into a cloud assistant your company hasn't
approved.

## 4. Using your own tool? Paste the boilerplate first

Continue.dev and Claude Code have already read this workspace's standing
instructions. A web chatbot has read nothing. Level the field: open
[`boilerplate-prompt.md`](boilerplate-prompt.md) and paste its prompt block as
your **first message** (or into the tool's project/custom instructions if it
has them). It carries the same environment facts and safety rules, minus the
git parts that only make sense on this VM.

## 5. Which one should I pick?

- **Doing the tracks as written?** Stay with `Ctrl+L`. Everything is tuned
  for it.
- **The local model feels too slow and you have an account?** Use your own
  assistant with the boilerplate prompt. The tracks still work - only the
  chat window changes.
- **Curious what the fuss about coding agents is?** Try `claude-local` after
  you've finished a track, not instead of one.
