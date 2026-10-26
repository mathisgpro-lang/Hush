# Restoring Hush on a fresh Mac

Backed up to a private GitHub repository on 2026-10-26, before Mathis reset his computer.

## 1. Get the files back
1. Install Xcode from the App Store and open it once (it installs its command-line tools).
2. In Terminal, in the folder where the project should live (it used to be `~/AI Projects/Hush`):
   ```
   git clone https://github.com/<your-username>/hush.git "Hush"
   ```
   GitHub asks for your username and, as the password, a personal access token (github.com → Settings → Developer settings → Personal access tokens).

## 2. What is in the backup, and what is not
- **In it:** every document (`docs/`: the master plan, the decisions log, the conversation log, Plan 2.0, the designs and Codex's art), the real app (`app/`), the prototype game Mathis plays on his phone (`prototypes/p2-spikes/`, the SpikeLab Xcode project), all scripts and tools, and Claude's memory notes about Mathis and the project (`docs/claude-memory/`).
- **Not in it, and not needed:** build output (`prototypes/p2-spikes/dd-spikelab-dev/`, `app/**/.build/`): Xcode rebuilds it. The game's progress on the phone lives on the phone, not here.
- **To redo by hand after the reset:**
  - Sign in to Xcode with the Apple ID (Xcode → Settings → Accounts) so it can sign the app for the iPhone (free 7-day signing, decision 88).
  - Install Claude Code and the ChatGPT app (Codex CLI lives inside it).
  - Copy `docs/claude-memory/*.md` into Claude's memory folder for this project (Claude can do it: tell it "restore your memory from docs/claude-memory").

## 3. Back in action
Open Claude Code in the project folder and say **"work again"**. It reads `docs/master-plan/00-index.md` (the RESUME HERE block) and continues from there. To put the game back on the iPhone, Claude rebuilds and installs it (the phone must be unlocked and on the same Wi-Fi, or plugged in).
