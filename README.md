# NARAYA Agents

Production-grade autonomous engineering agents **+ 65 on-demand skills** for **Claude Code**, **OpenCode**, and **Factory Droid**.

Six specialist agents with one philosophy: **evidence before claims, smallest safe change, verify before reporting done**.

---

## What's included

### 6 Agents

| Agent | Role |
|---|---|
| **naraya-worker** | Principal-level lead. Plans, delegates, executes, verifies. Hybrid orchestrator + standalone worker. |
| **naraya-researcher** | Evidence-first technical research. Docs, libraries, codebases, GitHub, web — with sourced findings and explicit confidence. |
| **oracle** | Architecture and deep debugging specialist. Hard decisions, root-cause analysis, complex trade-offs. |
| **explorer** | Fast codebase navigation. Maps files, symbols, references, call paths. Read-only. |
| **frontend** | UI/UX engineering. React, Vue, Svelte, CSS, Tailwind, accessibility, responsive design. |
| **android** | Native Android. Kotlin/Java, Gradle, Jetpack Compose, AndroidManifest, adb/logcat, APK/AAB release. |

All agents are **bilingual** (Bahasa Indonesia + English — they reply in the user's language) and **platform-portable** (same prompts, three platform variants).

### 65 Skills (on-demand)

Modular instructions loaded when relevant. Includes:

- **Languages**: typescript, python, rust, go, java-kotlin, csharp, php, ruby, cpp, scala, elixir, shell-bash
- **Frameworks**: react, vue, svelte, angular, nextjs, astro-remix, laravel, django-fastapi, express-nestjs, spring-boot, rails, tauri
- **Mobile**: android-kotlin, android-compose, android-gradle, android-release, android-security, android-testing, swift-ios, react-native, flutter-dart
- **Domains**: security, architecture, devops, frontend, sql-database, observability, distributed-systems, realtime-systems, blockchain-web3, game-development, ai-llm-engineering, design-systems
- **Engineering**: software-engineering, testing-strategies, api-design-patterns, advanced-patterns, monorepo-management, platform-engineering, reliability-engineering, auth-identity, compliance-governance, codebase-intelligence, verification-discipline, release-engineering, delegation-quality
- **Productivity**: `handoff` (manual `/handoff` to save session state) — adapted from [mattpocock/skills](https://github.com/mattpocock/skills), context-preservation, ai-optimization, developer-tooling, jce-worker-operating-system, wasm, tailwind

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

**Agents:**

| Platform | Copy this | To this |
|---|---|---|
| Claude Code | `platforms/claude-code/agents/*.md` | `~/.claude/agents/` |
| OpenCode | `platforms/opencode/agents/*.md` | `~/.config/opencode/agents/` |
| Factory Droid | `platforms/droid/droids/*.md` | `~/.factory/droids/` |

**Skills:**

| Platform | Copy this | To this |
|---|---|---|
| Claude Code | `skills/*` (entire folder) | `~/.claude/skills/` |
| OpenCode | `skills/*` (entire folder) | `~/.config/opencode/skills/` |
| Factory Droid | `skills/*` (entire folder) | `~/.factory/skills/` |

Then restart your CLI.

### Selective install

By default the installer installs **agents + skills**. To install only one:

```powershell
# Windows - agents only
$env:NARAYA_COMPONENTS='agents'; irm https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.ps1 | iex

# Windows - skills only
$env:NARAYA_COMPONENTS='skills'; irm https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.ps1 | iex
```

```bash
# macOS/Linux - agents only
NARAYA_COMPONENTS=agents curl -fsSL https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.sh | bash
```

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

### Skills

Skills load on-demand when the task matches their description. Most are automatic. One is manual-trigger only:

**`/handoff`** — Save the current session as a transferable Markdown doc (in your OS temp dir) so a fresh agent can pick up the work:

```
/handoff finish the auth refactor and add tests
```

The handoff doc includes: what was done, current state, what's next, open decisions, gotchas, verification commands, and suggested skills for resume. Secrets are auto-redacted. Bilingual (matches the session's language).

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
├── platforms/                 # Generated per-platform agent variants
│   ├── claude-code/agents/
│   ├── opencode/agents/
│   └── droid/droids/
├── skills/                    # 65 on-demand skills (platform-agnostic)
│   ├── handoff/SKILL.md
│   ├── software-engineering/SKILL.md
│   ├── react/SKILL.md
│   └── ... (62 more)
├── install/
│   ├── install.ps1            # Windows installer
│   └── install.sh             # macOS/Linux installer
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
