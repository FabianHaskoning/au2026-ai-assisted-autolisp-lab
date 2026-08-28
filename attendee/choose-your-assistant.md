# Choose your assistant

The assistant for today runs **in the browser** — the same ChatGPT, Claude,
Copilot or Gemini you may already know. This VM has them one click away, and
whichever you pick, the workflow stays identical: ask for code, put it in a
file, `APPLOAD` it in AutoCAD, iterate on the exact error text.

---

## 1. The default: a browser assistant + the boilerplate prompt

On the **desktop**, open the **AI Assistants** folder. Each shortcut opens
its assistant in Microsoft Edge:

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

Sign in with your own account, or use one with a free tier — **Copilot works
without signing in at all**.

Then, before anything else: **paste the block from
[`boilerplate-prompt.md`](boilerplate-prompt.md) as your first message.** A
web chatbot knows nothing about AutoCAD 2026, `APPLOAD` or `*error*`
handlers until you tell it — that block is the telling, and re-pasting it at
the start of every new chat is the whole trick. Full click path:
[Open the assistant](how-to/open-the-assistant.md).

**One caution on a shared machine:** this VM is wiped after the session, but
still — sign out of anything you signed into before you leave, and don't
paste confidential drawing data into a cloud assistant your company hasn't
approved.

## 2. Which one should I pick?

- **You have an account with any of them?** Use that one. Your quota, your
  familiar tool — the tracks don't care which chat window the code comes
  from.
- **No account with anything?** Use **Copilot** — free tier, no login needed
  for basic chat.
- Whichever you pick: ask for **one small, concrete thing at a time**, not a
  whole finished tool, and start a **new chat** (boilerplate first) whenever
  you change subject.

## 3. Also installed on this VM — mostly ignore it

VS Code also carries installed assistants — **Continue** (a panel backed by
a model running on this machine) and on the larger VMs **Claude Code** — and
the Start menu has an **Ollama** chat app and desktop **ChatGPT**/**Claude**
apps. On these lab VMs they often don't respond, so no track uses them.

If you want to try one anyway, do it *after* finishing a track, not instead
of one — and know the traps: the Continue icon in VS Code's far-left strip
is **not the play-button-with-a-bug icon** (that's *Run and Debug*); hover to
see the names. If a panel sits silent for a minute, that's this VM, not you —
go back to the browser. These same tools work properly on your own hardware;
Track 3 covers taking that pattern home.

---

← [Start here](START-HERE.md) · [Open the assistant](how-to/open-the-assistant.md)
