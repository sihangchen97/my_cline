---
description: "Sync Cline configuration to/from a remote git repository. Supports 'upload' and 'download' modes with automatic conflict resolution."
author: "sihangchen"
version: "2.0"
category: "Sync"
tags: ["sync", "git", "configuration", "mcp", "backup", "remote"]
---

# my_cline - Cline Configuration Sync Workflow

## Objective

Sync Cline configuration files (Hooks, MCP, Rules, Workflows folders and MCP settings) to/from a remote git repository. Two modes:

- **`upload`** — Push local configuration changes to remote
- **`download`** — Pull remote configuration changes locally

## Configuration: `.my_cline_config`

Stored at the remote repo root.

- **`remote_url`** — The git remote repository URL (e.g., `git@github.com:username/repo.git`)
- **`sync_keys`** — Fields to sync: `command`, `args`, `env`
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

## Path Variables

### CLINE_GLOBAL_PATH

| Platform | Path |
|----------|------|
| macOS/Linux | `~/Documents/Cline/` |
| Windows | PowerShell: `(Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Personal").Personal + "\Cline\"` |

### CLINE_MCP_SETTINGS_PATH

| Platform | Path |
|----------|------|
| macOS | `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` |
| Windows | `%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json` |
| Linux | `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` |

**Path Variants**: Replace `Code` in the path above:
- VS Code Insiders → `Code - Insiders`
- VSCodium → `VSCodium`

---

## Phase 1: Setup (Both Modes)

### 1.0 Fast Path Check (Optional Optimization)

**If ALL of the following are true, skip directly to Step 1.4:**
- `.my_cline_config` exists and contains a valid `remote_url`
- `.git` directory exists in the Cline config folder
- `origin` remote is already configured and matches `remote_url` in `.my_cline_config`

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

1. Run `git pull origin main 2>&1` (combined fetch + pull in a single command for speed)
2. If merge conflicts: report conflicted files, ask user to resolve (keep theirs/ours/manual)
3. After successful pull, read `.my_cline_config` from the repo if present

---

## Phase 2A: Upload Mode

### 2A.1 Compare and Confirm MCP Settings

**This step combines extraction, comparison, and confirmation into a single workflow.**

1. Read `.my_cline_config` to get the `sync_keys` and `ignore_keys` lists
2. Read the full local `$CLINE_MCP_SETTINGS_PATH` (all fields) and remote `cline_mcp_settings.json` (after pull)
3. For each local server, extract fields according to `sync_keys` from the local config
4. **Unknown fields handling**: If a field exists in the local config but is NOT in `sync_keys` or `ignore_keys`, use `ask_followup_question` to ask the user whether to add it to `sync_keys`, `ignore_keys`, or ignore it — then update `.my_cline_config` accordingly
5. Compare server by server and categorize each:
   - **New** (exists locally but not on remote)
   - **Removed** (exists on remote but not locally)
   - **Modified** (sync_keys fields differ)
   - **Unchanged**

6. **CRITICAL: For EACH difference, ask user via `ask_followup_question` one by one. Do NOT batch multiple changes.**
   - **New server**: `[Add to remote]` / `[Skip]`
   - **Removed server**: `[Delete from remote]` / `[Keep in remote]`
   - **Modified server**: `[Use local]` / `[Keep remote]` / `[Merge field-by-field]`

7. Write the merged result to `cline_mcp_settings.json.tmp` based on user confirmations (minimal format, only `sync_keys`). **Do NOT write to `cline_mcp_settings.json` directly.**

**IMPORTANT: If no differences detected, state "No MCP settings changes detected" before proceeding.**

### 2A.2 Compare Other Folders

**CRITICAL: You MUST present the changes for EACH folder and wait for user confirmation. Do NOT skip this step even if there are no changes — explicitly state "No changes in [folder name]" if that's the case.**

For each folder (Hooks, MCP, Rules, Workflows):
1. Use `git --no-pager diff` to detect uncommitted changes
2. Show summary of changes (added/modified/deleted files)
3. Ask user via `ask_followup_question`: `[Upload all]` / `[Skip folder]` / `[Select files manually]`
4. For untracked new files: ask whether to add each one individually

**IMPORTANT: If a folder has no changes, still mention it (e.g., "Hooks: No changes") so the user has full visibility.**

### 2A.6 Double Check Before Push

**CRITICAL: This step is MANDATORY and MUST NEVER be skipped under any circumstances.**
**Even if there are NO pending changes, you MUST still display the summary and ask the user for final confirmation.**

1. Display a complete summary of ALL pending changes using `git --no-pager diff`, grouped by category:
   - **MCP Settings**: list each server name + change type (Add/Remove/Modify/Unchanged)
   - **Hooks**: file paths + change types (Added/Modified/Deleted)
   - **MCP**: file paths + change types
   - **Rules**: file paths + change types
   - **Workflows**: file paths + change types
2. Show target branch: `origin/main` and current local branch name
3. If NO changes are detected, explicitly state: "**No changes to push. Working directory is clean.**"
4. Ask user via `ask_followup_question` with these exact options:
   - `[Confirm — Push to origin/main]`
   - `[Push to new branch]` — then ask for branch name, `git checkout -b <name>`, commit + push
   - `[Cancel upload]` — abort without pushing
   - `[View full diff]` — show full `git --no-pager diff` output, then re-ask this question

**DO NOT proceed to Step 2A.7 (Stage, Commit and Push) without explicit user confirmation from this step.**

### 2A.7 Move TMP, Stage, Commit and Push

1. Move the tmp file to the real one: rename `cline_mcp_settings.json.tmp` → `cline_mcp_settings.json`
2. `git add .`
3. Show commit summary
4. Commit: `sync: upload config - <timestamp>`
5. Push: `git push origin main`
6. **Update local MCP settings**: Write the confirmed merged result to `$CLINE_MCP_SETTINGS_PATH`

---

## Phase 2B: Download Mode

### 2B.1 Compare Remote vs Local MCP Settings

1. Read remote `cline_mcp_settings.json` (after pull) and local `$CLINE_MCP_SETTINGS_PATH`
2. Compare `sync_keys` fields only (ignore `ignore_keys`): identify new (remote only), modified, unchanged

### 2B.2 Resolve MCP Conflicts

For each difference, ask user:
- **New server (remote only)**: `[Add to local]` / `[Skip]`
- **Modified server**: `[Use remote]` / `[Keep local]` / `[Merge field-by-field]`

### 2B.3 Apply MCP Settings to Local

1. Read full local `$CLINE_MCP_SETTINGS_PATH` (all fields)
2. For servers using remote version: update ONLY `sync_keys` fields, preserve `ignore_keys` from local
3. For new servers from remote: add with `sync_keys` values + defaults for `ignore_keys` (`autoApprove: []`, `disabled: false`, `timeout: 60`, `type: "stdio"`)
4. Write merged result back to `$CLINE_MCP_SETTINGS_PATH`

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

- **MANDATORY**: All git commands must use the `--no-pager` prefix, no exceptions
- **Format**: `git --no-pager <command> <args>` (e.g., `git --no-pager diff`, `git --no-pager status`)
- **Remote file syntax**: `git --no-pager show origin/main:<file_path>` — `/` separates remote/branch, `:` separates branch/path. Never use `origin:main:path` (fatal error).

---

## Rules

- **NEVER overwrite `$CLINE_MCP_SETTINGS_PATH` entirely** — always merge at field level, preserving `ignore_keys`
- **ALWAYS ask before deleting** a server or file
- **ALWAYS show diff summary** before applying changes
- **ALWAYS validate JSON format** after modifications (matching braces, no trailing commas, proper quoting) before writing
- **Remote `cline_mcp_settings.json` must be minimal** — only `sync_keys` fields
- **Handle empty remote repository** (first-time setup) gracefully
- **If git operations fail**, report error and stop
- **If JSON validation fails**, report specific error and do NOT write the file
- **Handle merge conflicts** during pull by asking user (theirs/ours/manual)
- **If `.my_cline_config` is corrupted**, use default sync_keys and ignore_keys
