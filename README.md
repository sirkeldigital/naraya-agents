# NARAYA Agents

Production-grade autonomous engineering agents for **Claude Code**, **OpenCode**, and **Factory Droid**.

Six specialist agents with one philosophy: **evidence before claims, smallest safe change, verify before reporting done**.

---

## What's included

| Agent | Role |
|---|---|
| **naraya-worker** | Principal-level lead. Plans, delegates, executes, verifies. Hybrid orchestrator + standalone worker. |
| **naraya-researcher** | Evidence-first technical research. Docs, libraries, codebases, GitHub, web — with sourced findings and explicit confidence. |
| **oracle** | Architecture and deep debugging specialist. Hard decisions, root-cause analysis, complex trade-offs. |
| **explorer** | Fast codebase navigation. Maps files, symbols, references, call paths. Read-only. |
| **frontend** | UI/UX engineering. React, Vue, Svelte, CSS, Tailwind, accessibility, responsive design. |
| **android** | Native Android. Kotlin/Java, Gradle, Jetpack Compose, AndroidManifest, adb/logcat, APK/AAB release. |

All agents are **bilingual** (Bahasa Indonesia + English — they reply in the user's language) and **platform-portable** (same prompts, three platform variants).

---

## Quick Install

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.ps1 | iex
```

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.sh | bash
```

The installer will:
1. Detect which AI CLIs you have installed (Claude Code, OpenCode, Droid).
2. Ask which platform(s) to install for.
3. Download the right variant and copy to the platform's agent directory.
4. Back up any existing agent with the same name.

### Skip the prompt

```powershell
# Windows
$env:NARAYA_PLATFORM='claude-code'; irm https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.ps1 | iex
```

```bash
# macOS/Linux
NARAYA_PLATFORM=claude-code curl -fsSL https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.sh | bash
```

Valid platforms: `claude-code`, `opencode`, `droid`, `all`.

---

## Manual Install

If you prefer to clone and copy:

```bash
git clone https://github.com/sirkeldigital/naraya-agents.git
cd naraya-agents
```

| Platform | Copy this | To this |
|---|---|---|
| Claude Code | `platforms/claude-code/agents/*.md` | `~/.claude/agents/` |
| OpenCode | `platforms/opencode/agents/*.md` | `~/.config/opencode/agents/` |
| Factory Droid | `platforms/droid/droids/*.md` | `~/.factory/droids/` |

Then restart your CLI.

---

## Usage

### Claude Code

After install + restart:

```
/agents
```

You should see `naraya-worker`, `oracle`, `naraya-researcher`, `explorer`, `frontend`, `android` under **Personal agents**.

Invoke via:
- Auto-dispatch: just ask normally — Claude routes to the right agent based on intent.
- Explicit: `"use naraya-worker to refactor this module"`

### OpenCode

```
@naraya-worker plan refactor untuk modul auth
```

Switch primary with **Tab** between built-in `build`/`plan` and `naraya-worker`.

### Factory Droid

```
/droids
```

Invoke via Task tool:
```
Use subagent naraya-researcher to find the latest stable Postgres pgvector version
```

---

## Philosophy

All NARAYA agents follow these principles:

1. **Evidence before confidence** — claims need sources, verification, or explicit "not verified" labels.
2. **Smallest safe change** — narrow patches, preserve user work, never bundle refactors with features.
3. **Verify before reporting done** — run the command, read the output, then claim success.
4. **Honest correction over false agreement** — disagree when evidence supports it.
5. **The Boulder Rule** — stopping early is failure. Continue within scope until blocked or verified-complete.

---

## Customization

The repo structure:

```
naraya-agents/
├── source/                    # Single source of truth (6 agents)
│   ├── naraya-worker.md
│   ├── naraya-researcher.md
│   ├── oracle.md
│   ├── explorer.md
│   ├── frontend.md
│   └── android.md
├── platforms/                 # Generated per-platform variants
│   ├── claude-code/agents/
│   ├── opencode/agents/
│   └── droid/droids/
├── install/
│   ├── install.ps1
│   └── install.sh
└── build.ps1                  # Regenerate platform variants from source/
```

To customize:
1. Edit files in `source/`.
2. Run `pwsh build.ps1` to regenerate platform variants.
3. Reinstall.

---

## Updating

Re-run the installer. It will diff hashes and only update files that changed. Modified existing files get a `.bak` backup.

---

## Sister Agents (Architecture)

Agents work two ways:

- **Standalone** — Use any agent directly. Each is self-contained.
- **Orchestrated** — `naraya-worker` decomposes work and dispatches to specialists in parallel.

```
                  naraya-worker (lead)
                       │
        ┌──────────────┼──────────────┬────────────┬────────────┐
        │              │              │            │            │
   naraya-researcher  oracle      explorer     frontend     android
   (research)       (architecture) (mapping)    (UI/UX)    (Android)
```

`naraya-worker` follows the **Anti-Duplication Rule**: once it delegates, it doesn't redo the same work. Sister agents return structured output (`Summary`, `Files`, `Verification`, `Risks`) so the worker can synthesize without re-investigating.

---

## Skills (Optional)

NARAYA agents work standalone, but they're designed to be combined with [Anthropic Agent Skills](https://docs.anthropic.com/en/api/skills) — modular reusable instructions for languages, frameworks, and domains.

If you want the **full NARAYA stack** (agents + 50+ skills + MCP integrations), see the larger setup in [opencode-naraya](https://github.com/sirkeldigital/opencode-naraya).

---

## License

MIT — use, modify, redistribute freely.

---

## Contributing

PRs welcome. Source of truth lives in `source/*.md`. Run `build.ps1` after editing.

For bugs or feature requests, open an issue.
