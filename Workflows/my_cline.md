---
description: "Sync Cline configuration to/from a remote git repository. Supports 'upload' and 'download' modes with automatic conflict resolution."
author: "sihangchen"
version: "2.0"
category: "Sync"
tags: ["sync", "git", "configuration", "mcp", "backup", "remote"]
---

# my_cline - Cline Configuration Sync Workflow

## Objective

Sync Cline configuration files (Hooks, MCP, Rules, Workflows folders and `cline_mcp_settings.json`) to/from a remote git repository. Two modes:

- **`upload`** — Push local configuration changes to remote
- **`download`** — Pull remote configuration changes locally

## Configuration: `.my_cline_config`

Stored at the remote repo root. Structure:

```json
{
  "remote_url": "git@github.com:username/repo.git",
  "sync_keys": ["command", "args", "env"],
  "ignore_keys": ["autoApprove", "disabled", "timeout", "type"]
}
```

- **`sync_keys`** — Fields to sync: `command` (launch command), `args` (CLI arguments), `env` (environment variables)
- **`ignore_keys`** — Local-only preferences, never synced: `autoApprove`, `disabled`, `timeout`, `type`

### Remote Repository Structure

```
remote-repo/
├── .my_cline_config           # Sync configuration
├── cline_mcp_settings.json    # Minimal MCP settings (only sync_keys)
├── Hooks/
├── MCP/
├── Rules/
└── Workflows/
```

---

## Cline Global Paths

| Platform | Global Config Dir |
|----------|------------------|
| macOS    | `~/Documents/Cline/` |
| Linux    | `~/Documents/Cline/` |
| Windows  | `%USERPROFILE%\Documents\Cline\` |

---

## Phase 1: Setup (Both Modes)

### 1.1 Check or Request Remote URL

1. Check if `.my_cline_config` exists locally (or after initial pull).
2. If missing or `remote_url` is empty: ask the user for the remote git URL via `ask_followup_question`, then create/update `.my_cline_config` with defaults.
3. If exists: read `remote_url`, `sync_keys`, `ignore_keys`.

### 1.2 Initialize Local Git Repository

1. Check if `.git` exists in the Cline config folder. If not: run `git init`

### 1.3 Configure Git Remote

1. Check remote: `git remote get-url origin`
2. If missing: `git remote add origin <remote_url>`
3. If URL differs from `.my_cline_config`: ask user whether to update via `git remote set-url origin <remote_url>`

### 1.4 Pull Latest Remote Changes

1. `git fetch origin` then `git pull origin main`
2. If merge conflicts: report conflicted files, ask user to resolve (keep theirs/ours/manual)
3. After successful pull, read `.my_cline_config` from the repo if present

---

## Phase 2A: Upload Mode

### 2A.1 Extract Minimal MCP Settings

1. Read local `cline_mcp_settings.json`
2. For each server in `mcpServers`, extract ONLY `sync_keys` fields (`command`, `args`, `env`)
3. Build minimal JSON: `{"mcpServers": {"server-name": {"command": "...", "args": [...], "env": {...}}}}`

### 2A.2 Compare Local vs Remote MCP Settings

1. Read remote `cline_mcp_settings.json` (after pull)
2. Compare server by server: identify new (local only), removed (remote only), modified, unchanged

### 2A.3 Resolve MCP Conflicts

For each difference, ask user via `ask_followup_question`:
- **New server**: `[Add to remote]` / `[Skip]`
- **Removed server**: `[Delete from remote]` / `[Keep in remote]`
- **Modified server**: `[Use local]` / `[Keep remote]` / `[Merge field-by-field]`

Build final merged `cline_mcp_settings.json` after user confirmation.

### 2A.4 Compare Other Folders

For each folder (Hooks, MCP, Rules, Workflows):
1. Use `git --no-pager diff` to detect uncommitted changes
2. Show summary of changes (added/modified/deleted)
3. Ask user: `[Upload all]` / `[Skip folder]` / `[Select files manually]`
4. For untracked new files: ask whether to add

### 2A.5 Write Merged MCP Settings

Write the final merged `cline_mcp_settings.json` (minimal format, only `sync_keys`) to the working directory.

### 2A.6 Double Check Before Push

**The user MUST review and confirm all data before pushing.**

1. Display summary of all pending changes using `git --no-pager diff`, grouped by category:
   - **MCP Settings**: server names + change types
   - **Hooks/MCP/Rules/Workflows**: file paths + change types
2. Show target branch: `origin/main` and current local branch
3. Ask user via `ask_followup_question`:
   - `[Confirm — Push to origin/main]`
   - `[Push to new branch]` — ask for branch name, then `git checkout -b <name>` + commit + push
   - `[Cancel upload]` — abort
   - `[View full diff]` — show full diff, then re-ask

### 2A.7 Stage, Commit and Push

1. `git add .`
2. Show commit summary
3. Commit: `sync: upload config - <timestamp>`
4. Push: `git push origin main`

---

## Phase 2B: Download Mode

### 2B.1 Compare Remote vs Local MCP Settings

1. Read remote `cline_mcp_settings.json` (after pull) and local version
2. Compare `sync_keys` fields only (ignore `ignore_keys`): identify new (remote only), modified, unchanged

### 2B.2 Resolve MCP Conflicts

For each difference, ask user:
- **New server (remote only)**: `[Add to local]` / `[Skip]`
- **Modified server**: `[Use remote]` / `[Keep local]` / `[Merge field-by-field]`

### 2B.3 Apply MCP Settings to Local

1. Read full local `cline_mcp_settings.json` (all fields)
2. For servers using remote version: update ONLY `sync_keys` fields, preserve `ignore_keys` from local
3. For new servers from remote: add with `sync_keys` values + defaults for `ignore_keys` (`autoApprove: []`, `disabled: false`, `timeout: 60`, `type: "stdio"`)
4. Write merged result back to local `cline_mcp_settings.json`

### 2B.4 Compare Other Folders

For each folder (Hooks, MCP, Rules, Workflows):
1. Use `git --no-pager diff` to detect differences
2. Show summary, ask user: `[Download all]` / `[Skip folder]` / `[Select files manually]`
3. Selected remote versions are already in the working directory from `git pull`

### 2B.5 Finalize

1. Run `git --no-pager status` to show final state
2. If uncommitted changes remain: ask user whether to commit and push
3. Use `attempt_completion` to summarize what was downloaded

---

## Git Command Rules

- **ALWAYS use `--no-pager`** prefix for all git commands (diff, status, log, show, etc.) to prevent pager blocking.
- **Remote file syntax**: `git --no-pager show origin/main:<file_path>` — `/` separates remote/branch, `:` separates branch/path. Never use `origin:main:path` (fatal error).

---

## Rules

- **NEVER overwrite local `cline_mcp_settings.json` entirely** — always merge at field level, preserving `ignore_keys`
- **ALWAYS ask before deleting** a server or file
- **ALWAYS show diff summary** before applying changes
- **ALWAYS validate JSON format** after modifications (matching braces, no trailing commas, proper quoting) before writing
- **Remote `cline_mcp_settings.json` must be minimal** — only `sync_keys` fields
- **Handle empty remote repository** (first-time setup) gracefully
- **If git operations fail**, report error and stop
- **If JSON validation fails**, report specific error and do NOT write the file
- **Handle merge conflicts** during pull by asking user (theirs/ours/manual)
- **If `.my_cline_config` is corrupted**, use default sync_keys and ignore_keys
