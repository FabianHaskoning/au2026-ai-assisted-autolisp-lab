# Choose your assistant

You can do everything today with the assistant that's already set up. But this
VM offers more than one way to talk to an AI, and if you have your own account
with ChatGPT, Claude, Copilot or anything else, you're welcome to use it. This
page is the map.

Whatever you pick, the workflow stays identical: ask for code, put it in a
file, `APPLOAD` it in AutoCAD, iterate on the exact error text.

---

## 1. The default: Continue.dev (no account, already set up)

In the narrow strip of icons down the far left of VS Code, click the
**Continue** icon. This is the assistant every track assumes. Full
instructions: [Open the assistant](how-to/open-the-assistant.md).

- No account, no API key, no cost — the model runs on this machine.
- It has already read the six rules files in `C:\LabWork\.continue\rules\`,
  so it knows about AutoCAD 2026 and `*error*` handlers before you say a word.
- It is slower and smaller than the big-name assistants. Ask for one small,
  concrete thing at a time.

**If the panel doesn't answer within 60 seconds:** raise your hand.

## 2. Also on this VM, no account needed

**Claude Code** — the same coding agent developers use, pointed at the local
model instead of the cloud. If this VM has it, there's a **Claude Code** icon
in that same left-hand strip in VS Code; click it and it opens as a panel like
Continue does. Only the larger VMs have it — no icon means this VM doesn't,
and Continue is unaffected.

**If it shows an Anthropic sign-in screen instead of a prompt:** raise your
hand. It's a one-line fix a facilitator can do, and it isn't your problem to
solve.

**The Ollama app** — the model behind everything above has its own chat app
(Start menu → **Ollama**). Plain chat, no editor integration. Handy to see
what the raw model does without any rules files helping it.

**Microsoft Copilot** — built into Windows 11 (Start menu → **Copilot**).
Free tier, no login required for basic chat.

## 3. Bring your own account (optional)

If you already pay for — or have free access to — an assistant, use it. Your
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
shortcut instead — they do the same thing.

**One caution on a shared machine:** this VM is wiped after the session, but
still — sign out of anything you signed into before you leave, and don't
paste confidential drawing data into a cloud assistant your company hasn't
approved.

## 4. Using your own tool? Paste the boilerplate first

The assistants set up here have already read this workspace's standing
instructions. A web chatbot has read nothing. Level the field: open
[`boilerplate-prompt.md`](boilerplate-prompt.md) and paste its prompt block as
your **first message** (or into the tool's project/custom instructions if it
has them). Same environment facts, same safety rules.

## 5. Which one should I pick?

- **Doing the tracks as written?** Stay with Continue. Everything is tuned for
  it.
- **The local model feels too slow and you have an account?** Use your own
  assistant with the boilerplate prompt. The tracks still work — only the chat
  window changes.
- **Curious what the fuss about coding agents is?** Try the Claude Code panel
  *after* you've finished a track, not instead of one.

---

← [Start here](START-HERE.md) · [Open the assistant](how-to/open-the-assistant.md)
