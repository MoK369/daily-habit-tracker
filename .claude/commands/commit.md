---
description: Review git changes, write or polish a Conventional Commit message, then commit (and optionally push) after confirmation
argument-hint: [--push] [optional commit message]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git rev-parse:*)
---

# Smart Commit

## Context

- Current branch: !`git branch --show-current`
- Status: !`git status --short`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Recent commits (to match the repo's existing style): !`git log --oneline -10`

## Arguments

Raw arguments: `$ARGUMENTS`

Parse them like this:
- If they contain `--push` or `-p`, remove that flag and remember that the user wants **commit + push**.
- Whatever text remains (trimmed) is the **user's draft commit message**. It may be empty.

## Step 1 — Understand the changes

1. If nothing is staged but there are unstaged or untracked changes, list them and ask:
   "Nothing is staged. Stage all changes (`git add -A`), or stop so you can stage manually?"
   Do not stage anything without an answer.
2. If there are no changes at all, say so and stop.
3. Read the actual diff of what will be committed with `git diff --cached`. For large diffs, read file by file. Base the message on what the code does, not only on file names.
4. Warn (and do not proceed without confirmation) if the staged changes include anything that looks like a secret or local-only file: `.env`, keys, tokens, credentials, `key.properties`, `google-services.json`, `GoogleService-Info.plist`, `*.jks`, `*.keystore`, build outputs, or IDE folders.
5. If the staged changes clearly mix unrelated concerns (e.g. a feature plus an unrelated refactor), point that out and suggest splitting into separate commits. Let the user decide.

## Step 2 — Write or enhance the message

Follow **Conventional Commits 1.0.0** plus the standard git message rules below.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types (pick exactly one)

| Type       | Use for                                                       |
|------------|---------------------------------------------------------------|
| `feat`     | A new feature for the user                                    |
| `fix`      | A bug fix                                                     |
| `refactor` | Code change that neither fixes a bug nor adds a feature       |
| `perf`     | Performance improvement                                       |
| `style`    | Formatting, whitespace, lint fixes (no logic change)          |
| `test`     | Adding or fixing tests                                        |
| `docs`     | Documentation only                                            |
| `build`    | Build system, dependencies (`pubspec.yaml`, gradle, packages) |
| `ci`       | CI configuration and scripts                                  |
| `chore`    | Maintenance that doesn't touch source or tests                |
| `revert`   | Reverting a previous commit                                   |

### Rules

**Header**
- `type` is lowercase.
- `scope` is optional, lowercase, a noun naming the affected area (module, feature, or layer), inferred from the changed paths, e.g. `auth`, `cart`, `checkout`, `api`, `router`. Omit it if the change spans many unrelated areas.
- Subject uses the **imperative mood**: "add", "fix", "remove" — not "added", "fixes", "removing".
- Subject starts lowercase, has **no period** at the end.
- Whole header line is **72 characters max** (aim for ~50).
- Be specific: "fix(cart): prevent negative quantity on decrement", not "fix bug" or "update files".

**Body** (include when the change isn't obvious from the header; skip for trivial changes)
- Separated from the header by one blank line.
- Explains **what** changed and **why**, not line-by-line how.
- Wrapped at 72 characters per line.
- Bullet points (`- `) are fine for multiple related changes.

**Footer** (only when relevant)
- Breaking changes: add `!` after the type/scope (`feat(api)!: ...`) **and** a footer `BREAKING CHANGE: <description of what breaks and how to migrate>`.
- Issue references: `Closes #123`, `Refs #45`, or a ticket key such as `Refs PROJ-123` if the branch name or the user's message contains one.

**Never**
- Add `Co-Authored-By`, "Generated with Claude", or any other trailer the user didn't ask for.
- Use emojis unless the repo's recent commits clearly use them.
- Invent changes that aren't in the diff.

### If the user gave a draft message

Keep their **intent and meaning**, and rewrite it to follow every rule above: add the correct type and scope, convert to imperative mood, fix casing and punctuation, shorten the header if needed, and move extra detail into the body. If their draft contradicts the diff (e.g. says "fix" but the diff adds a new feature), say so and use the type the diff supports.

### If no message was given

Write one from scratch based on the diff.

## Step 3 — Show the result and confirm (required)

Never commit before the user confirms. Present:

1. **Files to be committed** — short list with change type (added / modified / deleted).
2. **Original message** — only if the user provided one.
3. **Proposed message** — in a code block, exactly as it will be committed.
4. **What changed in the message** — only if a draft was enhanced, 1–3 short bullets (e.g. "added `fix` type and `cart` scope", "changed to imperative mood").
5. **Action** — then ask the user to choose:
    - If `--push` was passed: **Commit & push** / **Edit message** / **Cancel**
    - Otherwise: **Commit only** / **Commit & push** / **Edit message** / **Cancel**

If the user picks **Edit message** or replies with changes, apply them, keep the conventions, and show the result again for confirmation.

## Step 4 — Execute

- Commit with the exact confirmed message. For multi-line messages, pass the header and body as separate `-m` arguments, or use a heredoc, so line breaks are preserved.
- If a pre-commit hook fails, show the error, do not use `--no-verify`, and ask how to proceed.
- If pushing:
    - Push to the current branch's upstream with `git push`.
    - If the branch has no upstream, use `git push -u origin <current-branch>`.
    - If the push is rejected (remote has new commits), stop and tell the user. Do not force-push, pull, or rebase without explicit permission.
- Never push directly to `main` or `master` without first warning the user and getting a second confirmation.

## Step 5 — Report

Finish with a short summary: the commit hash (`git rev-parse --short HEAD`), the header line, and whether it was pushed and to which branch.