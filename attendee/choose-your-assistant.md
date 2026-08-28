# Choose your assistant

The assistant for today runs **in the browser** — the same ChatGPT, Claude,
Copilot or Gemini you may already know. This VM has them one click away, and
whichever you pick, the workflow stays identical: ask for code, put it in a
file, `APPLOAD` it in AutoCAD, iterate on the exact error text.

---

## 1. The default: a browser assistant + the boilerplate prompt

On the **desktop**, open the **AI Assistants** folder. Each shortcut opens
its assistant in Microsoft Edge:

| Assistant | Where it goes | Account needed? |
| --- | --- | --- |
| ChatGPT | chatgpt.com | No for basic chat |
| Claude | claude.ai | Free account |
| Microsoft Copilot | copilot.microsoft.com | No |
| Gemini | gemini.google.com | Free account |
| Le Chat (Mistral) | chat.mistral.ai | Free account |
| Kimi | kimi.com | Free account |
| Lumo (Proton) | lumo.proton.me | No for basic chat |
| DeepSeek | chat.deepseek.com | Free account |
| Perplexity | perplexity.ai | No for basic search |
| Qwen Chat | chat.qwen.ai | Free account |
| Grok | grok.com | Free account |
| Meta AI | meta.ai | No for basic chat |
| Duck.ai (DuckDuckGo) | duck.ai | No |

Sign in with your own account where the last column says so — **Copilot and
Duck.ai need no sign-in at all**, and a few others allow basic, capped use
without an account.

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
- **No account with anything?** Use **Copilot** or **Duck.ai** — both work
  with no sign-in at all.
- Whichever you pick: ask for **one small, concrete thing at a time**, not a
  whole finished tool, and start a **new chat** (boilerplate first) whenever
  you change subject.

And a rough, moves-fast guide to the differences — a starting point, not
gospel:

- **Capability:** ChatGPT, Claude, Gemini and Grok are the current top tier,
  with DeepSeek, Qwen, Kimi, Le Chat and Copilot close behind — for today's
  exercises, every assistant in the folder writes usable AutoLISP. Duck.ai
  and Lumo run smaller models: fine today, weaker on long or subtle work.
- **Price:** every free tier here is enough for this workshop. Expect caps
  (messages per hour/day) and a switch to a lighter model when it's busy;
  paid plans (mostly around $20/month) buy bigger limits and stronger models.
- **Privacy:** the shared-machine caution above is the one that matters
  today. Beyond that: assume chats may be used for training unless you opt
  out or pay; Duck.ai (anonymised, no training) and Lumo (Proton, European,
  no logs) are the privacy-minded picks; DeepSeek, Kimi and Qwen are hosted
  in China — fine for generic AutoLISP questions, not for company data.

## 3. Also installed on this VM — mostly ignore it

VS Code also carries installed assistants — **Continue** (a panel backed by
a model running on this machine) and on the larger VMs **Claude Code** — and
the Start menu has an **Ollama** chat app and desktop **ChatGPT**/**Claude**
apps. We installed and tested all of it while building this lab; on these
hosted VMs it doesn't respond reliably, so no track uses it — the whole
session runs in the browser instead.

If you want to try one anyway, do it *after* finishing a track, not instead
of one — and know the traps: the Continue icon in VS Code's far-left strip
is **not the play-button-with-a-bug icon** (that's *Run and Debug*); hover to
see the names. If a panel sits silent for a minute, that's this VM, not you —
go back to the browser. These same tools work properly on your own hardware;
Track 3 covers taking that pattern home.

---

← [Start here](START-HERE.md) · [Open the assistant](how-to/open-the-assistant.md)
