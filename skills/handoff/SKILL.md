---
name: handoff
description: Manual trigger only. Compact the current conversation into a handoff document so a fresh agent can pick up the work. Invoke when user says "handoff", "buat handoff", "/handoff", or explicitly asks to summarize the session for transfer.
---

# Skill: Handoff

> Adapted from [mattpocock/skills — productivity/handoff](https://github.com/mattpocock/skills/blob/main/skills/productivity/handoff/SKILL.md).
> Extended for NARAYA: manual-only triggers, bilingual (ID/EN), fixed output structure, OS-aware paths, explicit secret redaction.

## Trigger (Manual Only)

Invoke this skill ONLY when the user explicitly asks. Do NOT auto-trigger.

Recognized triggers (any language):
- "handoff", "buat handoff", "create handoff", "save handoff"
- "/handoff", "/handoff <description>"
- "ringkas sesi ini untuk dilanjutkan", "summarize this session for a fresh agent"
- "transfer context to next session"

If the user passes an argument after the trigger (e.g., `/handoff finish the auth refactor`), treat it as the **focus of the next session** and tailor the document accordingly.

## What This Skill Does

Write a single Markdown handoff document that lets a fresh agent (in a new session, possibly without context) continue exactly where this one stops.

**Output location** (use OS temp directory, NEVER the workspace):
- Windows: `$env:TEMP\handoff-<YYYY-MM-DD-HHMM>.md` (e.g., `C:\Users\<user>\AppData\Local\Temp\handoff-2026-05-30-1432.md`)
- macOS: `$TMPDIR/handoff-<YYYY-MM-DD-HHMM>.md` (or `/tmp/` fallback)
- Linux: `/tmp/handoff-<YYYY-MM-DD-HHMM>.md`

Print the full absolute path at the end so the user can copy-paste it.

## Document Structure

Use exactly this structure. Match the user's language (Bahasa Indonesia or English).

```markdown
# Handoff — <one-line summary of what was being worked on>

**Date**: <YYYY-MM-DD HH:MM local>
**Workspace**: <absolute path to project root>
**Next session focus**: <from user argument, or "continue current work">

## Context

<2-4 sentences describing the project, what we were doing, and why.
Skip if the project is obvious from the workspace path.>

## What Was Done This Session

- <bullet — specific, verifiable change>
- <bullet — with file paths when files changed>
- <bullet — verification evidence: command + result>

Reference artifacts (don't duplicate them):
- PRD/spec: <path or URL>
- Plan: <path or URL>
- Issue / PR: <number + URL>
- Commits: <SHA list>
- Key diffs: <file:line ranges>

## Current State

- **Branch**: <git branch name>
- **Uncommitted changes**: <yes/no — if yes, list files>
- **Build status**: <last known result — passing / failing / unverified>
- **Test status**: <last known result>
- **Blockers**: <none, or specific blocker + evidence>

## What's Next

Ordered list of concrete next actions. Each item must be small enough to start within minutes.

1. <action — exact command or file edit when applicable>
2. <action>
3. <action>

## Open Decisions

Things the next agent should NOT silently decide. Surface them:

- <question> — options: <A> / <B>. Recommendation: <X> because <reason>.
- <question>

## Gotchas / Hard-Earned Lessons

Stuff that wasted time this session and the next agent shouldn't re-discover:

- <pattern that didn't work and why>
- <hidden coupling, weird API behavior, env quirk>
- <test that's flaky for a known reason>

## Suggested Skills

Skills the next agent should load on resume:

- `<skill-name>` — <why>
- `<skill-name>` — <why>

(Pick from available skills the project uses. Common: software-engineering, the language skill (typescript/python/rust/etc.), the framework skill (react/nextjs/laravel/etc.), context-preservation, systematic-debugging.)

## Files Worth Reading First

Order matters — read in this sequence:

1. `<path>` — <why>
2. `<path>` — <why>

## Verification Commands

Commands the next agent should run to confirm the state before continuing:

```bash
<command 1>   # expected: <result>
<command 2>   # expected: <result>
```

## Sensitive Data

This document has been redacted of:
- API keys, tokens, passwords
- Personal identifiers (emails, phone numbers, addresses)
- Internal URLs that shouldn't leave the team

If you need credentials, see <credential source — e.g., 1Password vault, .env.local>.
```

## Rules

1. **Manual only** — never write a handoff unless the user asked. No proactive handoffs at end of session.
2. **OS temp directory, never workspace** — handoffs are ephemeral, must not pollute the repo.
3. **No duplication** — reference PRDs, plans, ADRs, issues, commits, and diffs by path or URL. Don't paste their content.
4. **Redact secrets** — scan for API key patterns (`sk-`, `ghp_`, `xoxb-`, `eyJ`, etc.), passwords, tokens, PII. Replace with `<REDACTED>` and note what was redacted.
5. **Concrete next actions** — vague "continue working" is worthless. Each next action must be small enough to start immediately.
6. **Match user language** — if the session was in Bahasa Indonesia, write the handoff in Bahasa Indonesia. If English, English. Don't mix.
7. **Print the path** — final line of your response must be the absolute path to the handoff file, on its own line, so the user can copy it.

## After Writing

Report to the user in this format:

```
Handoff saved.

  Path: <absolute path>
  Size: <bytes or lines>
  Focus: <from argument, or "continue current work">

To resume in a new session:
  1. Open the file above.
  2. Tell the next agent: "Read the handoff at <path> and continue."
```

## What NOT to Include

- Verbose summaries of code you already wrote (the diff is the truth — reference it).
- Speculation about what user might want next (only what user said or implied).
- Praise for the session ("great progress today!"). Just facts.
- Marketing/filler ("comprehensive", "robust", "production-ready").
- Re-explanations of project basics that any agent can discover in 30 seconds.

## Example Trigger Handling

**User**: `/handoff finish the auth refactor and add tests`

→ Set "Next session focus" to "Finish the auth refactor and add tests."
→ Bias "What's Next" toward auth refactor + testing.
→ Include test commands in "Verification Commands".

**User**: `buat handoff bro, gw mau lanjut besok`

→ Write the handoff in Bahasa Indonesia.
→ "Next session focus": "Continue current work" (no specific focus given).
→ Use casual but precise Indonesian (consistent with how user spoke this session).

**User**: `handoff`

→ No argument. Generic handoff, "Next session focus" = "continue current work".
