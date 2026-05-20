---
description: "Sync Cline configuration to/from a remote git repository. Supports 'upload' and 'download' modes with automatic conflict resolution."
author: "sihangchen"
version: "1.0"
category: "Sync"
tags: ["sync", "git", "configuration", "mcp", "backup", "remote"]
---

# my_cline - Cline Configuration Sync Workflow

## Objective

Sync Cline configuration files (Hooks, MCP, Rules, Workflows folders and cline_mcp_settings.json) to and from a remote git repository. This workflow supports two modes:

- **`upload`** — Push local configuration changes to the remote repository
- **`download`** — Pull remote configuration changes to the local machine

The workflow handles git initialization, remote repository management, diff comparison, and conflict resolution for both modes.

---

## Configuration: `.my_cline_config`

This workflow uses a configuration file `.my_cline_config` stored at the root of the remote repository to persist settings.

### Structure

```json
{
  "remote_url": "git@github.com:username/repo.git",
  "sync_keys": [
    "command",
    "args",
    "env"
  ],
  "ignore_keys": [
    "autoApprove",
    "disabled",
    "timeout",
    "type"
  ]
}
```

### `sync_keys` — Fields to Synchronize

These are the essential MCP server configuration fields that should be synced to/from the remote repository:

| Key | Description |
|-----|-------------|
| `command` | The launch command for the MCP server (e.g., `npx`, `uvx`) |
| `args` | Command-line arguments passed to the server |
| `env` | Environment variables required by the server |

### `ignore_keys` — Local-Only Fields

These fields reflect user-local preferences and should NOT be synced:

| Key | Description |
|-----|-------------|
| `autoApprove` | User's auto-approve tool preferences |
| `disabled` | Whether the user has disabled the server locally |
| `timeout` | User-configured timeout settings |
| `type` | Connection type (always `stdio` for standard servers) |

---

## Remote Repository Structure

```
remote-repo/
├── .my_cline_config           # Sync configuration (remote_url, sync_keys, ignore_keys)
├── cline_mcp_settings.json    # Minimal MCP settings (only sync_keys)
├── Hooks/                      # Cline hooks configuration
├── MCP/                        # MCP server configurations
├── Rules/                      # Cline rules
└── Workflows/                  # Cline workflows
```

---

## Steps

### Phase 1: Setup (Both Modes)

#### Step 1.1: Check or Request Remote URL

1. Check if `.my_cline_config` exists in the current working directory after a initial pull (or locally if it was previously set up).
2. If the file does NOT exist or `remote_url` is empty:
   - Use `ask_followup_question` to ask the user for the remote git repository URL
   - Create/update `.my_cline_config` with the provided URL and default sync_keys / ignore_keys
3. If the file exists, read and parse the `remote_url`, `sync_keys`, and `ignore_keys`.

#### Step 1.2: Initialize Local Git Repository

1. Check if `.git` directory exists in the Cline configuration folder (`/Users/sihangchen/Documents/Cline` or the current working directory).
2. If `.git` does NOT exist:
   - Run `git init` to initialize a new repository
   - Create a `.gitignore` file with the following contents:
     ```
     # OS files
     .DS_Store
     Thumbs.db
     
     # IDE files
     .vscode/
     .idea/
     
     # MCP node_modules
     **/node_modules/
     **/dist/
     **/build/
     ```
3. If `.git` already exists, skip initialization.

#### Step 1.3: Configure Git Remote

1. Check if the remote `origin` is configured: `git remote get-url origin`
2. If no remote exists:
   - Add the remote: `git remote add origin <remote_url>`
3. If the remote URL differs from the one in `.my_cline_config`:
   - Use `ask_followup_question` to ask the user whether to update the remote URL
   - If yes, run: `git remote set-url origin <remote_url>`

#### Step 1.4: Pull Latest Remote Changes

1. Run `git fetch origin` to get the latest remote references
2. Run `git pull origin main` to merge remote changes
3. If there are merge conflicts at the git level:
   - Report the conflicted files to the user
   - Use `ask_followup_question` to ask how to resolve (keep theirs / keep ours / manual)
   - Resolve conflicts before proceeding
4. After a successful pull, read `.my_cline_config` from the repository if it exists

---

### Phase 2A: Upload Mode

#### Step 2A.1: Extract Minimal MCP Settings from Local

1. Read the local `cline_mcp_settings.json`
2. For each server in `mcpServers`, extract ONLY the `sync_keys` fields:
   - `command`
   - `args`
   - `env` (if present)
3. Build a minimal JSON object:
   ```json
   {
     "mcpServers": {
       "server-name": {
         "command": "...",
         "args": [...],
         "env": { ... }
       }
     }
   }
   ```

#### Step 2A.2: Compare Local vs Remote MCP Settings

1. Read the remote `cline_mcp_settings.json` from the working directory (after pull)
2. Compare the two files server by server:
   - **Servers only in local**: New servers to add
   - **Servers only in remote**: Servers removed locally
   - **Servers in both with differences**: Modified servers
   - **Servers in both with no differences**: No changes needed

#### Step 2A.3: Resolve MCP Settings Conflicts

For each difference found, use `ask_followup_question` to ask the user what to do:

- **New server (local only)**: `[Add to remote]` or `[Skip]`
- **Removed server (remote only)**: `[Delete from remote]` or `[Keep in remote]`
- **Modified server**: `[Use local version]` / `[Keep remote version]` / `[Merge field-by-field]`

After user confirmation for each server, build the final merged `cline_mcp_settings.json`.

#### Step 2A.4: Compare Other Folders (Hooks, MCP, Rules, Workflows)

For each of the four folders:

1. Use `git diff` to detect local uncommitted changes in each folder
2. For files that have changed:
   - Show a summary of what changed (added/modified/deleted)
   - Use `ask_followup_question` to ask: `[Upload all changes]` / `[Skip this folder]` / `[Select files manually]`
3. For new files not yet tracked:
   - Ask the user whether to add them

#### Step 2A.5: Write Merged MCP Settings

1. Write the final merged `cline_mcp_settings.json` to the working directory (overwriting the remote version)
2. This file should ONLY contain `sync_keys` fields (minimal format)

#### Step 2A.6: Double Check Before Push

**Before the actual git push, the user MUST review and confirm all data being uploaded.**

1. **Display a summary of all pending changes**:
   - Use `git diff` to show all uncommitted changes (before staging)
   - Group the changes by category:

| Category | What to Display |
|----------|----------------|
| **MCP Settings** | List server names with change types (added/modified/deleted) |
| **Hooks** | List file paths and change types (added/modified/deleted) |
| **MCP Folder** | List file paths and change types |
| **Rules** | List file paths and change types |
| **Workflows** | List file paths and change types |

2. **Display target branch information**:
   - Show the target remote branch: `origin/main`
   - Show the current local branch name

3. **Ask the user for final confirmation**:
   Use `ask_followup_question` to present the following options:
   - `[Confirm — Push to origin/main]` — Data is correct, proceed with upload
   - `[Push to new branch]` — Data is correct, but push to a new branch instead
   - `[Cancel upload]` — Data is incorrect or unauthorized, abort the operation
   - `[View full diff]` — Review the complete diff before deciding

4. **Execute based on user choice**:
   - **Confirm**: Proceed to Stage, Commit, and Push to `origin/main`
   - **New branch**: Ask the user for a branch name, then run `git checkout -b <branch_name>`, commit, and push with `git push -u origin <branch_name>`
   - **Cancel**: Stop the workflow, do NOT execute any git operations
   - **View full diff**: Display the full `git diff` output, then re-ask the confirmation question

#### Step 2A.7: Stage, Commit and Push

1. Stage all changes: `git add .`
2. Show a summary of what will be committed
3. Commit with message: `sync: upload config - <timestamp>`
4. Push to remote: `git push origin main`

---

### Phase 2B: Download Mode

#### Step 2B.1: Compare Remote vs Local MCP Settings

1. Read the remote `cline_mcp_settings.json` (already in working directory after pull)
2. Read the local `cline_mcp_settings.json`
3. For each server in the remote file, extract only `sync_keys` fields
4. Compare with the local version (same fields only, ignoring `ignore_keys`):
   - **Servers only in remote**: New servers to add locally
   - **Servers only in local**: Servers not on remote (no action needed)
   - **Servers in both with differences**: Modified servers
   - **Servers in both with no differences**: No changes needed

#### Step 2B.2: Resolve MCP Settings Conflicts

For each difference found, use `ask_followup_question` to ask the user:

- **New server (remote only)**: `[Add to local]` or `[Skip]`
- **Modified server**: `[Use remote version]` / `[Keep local version]` / `[Merge field-by-field]`

Based on user choices, build the merged server configuration.

#### Step 2B.3: Apply MCP Settings to Local

1. Read the full local `cline_mcp_settings.json` (all fields including `ignore_keys`)
2. For each server where the user chose to use the remote version, update ONLY the `sync_keys` fields:
   - Replace `command`, `args`, `env` with remote values
   - Preserve `autoApprove`, `disabled`, `timeout`, `type` from the local version
3. For new servers added from remote, add them with the `sync_keys` values and default values for `ignore_keys`:
   - `autoApprove: []`
   - `disabled: false`
   - `timeout: 60`
   - `type: "stdio"`
4. Write the merged result back to the local `cline_mcp_settings.json`

#### Step 2B.4: Compare Other Folders (Hooks, MCP, Rules, Workflows)

For each of the four folders:

1. Use `git diff` to detect differences between the remote version (in working directory after pull) and the local uncommitted changes
2. For files that differ:
   - Show a summary of what changed
   - Use `ask_followup_question` to ask: `[Download all]` / `[Skip this folder]` / `[Select files manually]`
3. For files chosen to download, the remote versions are already in the working directory from the `git pull`

#### Step 2B.5: Finalize

1. After all merges are complete, run `git status` to show the final state
2. If there are remaining uncommitted changes (partial downloads, etc.):
   - Ask the user whether to commit and push these changes back to remote
3. Use `attempt_completion` to summarize what was downloaded and applied

---

## JSON Format Validation

**After ANY modification to JSON files, ALWAYS validate the format before writing:**

1. **For `cline_mcp_settings.json`** (both upload and download modes):
   - Ensure proper JSON syntax (matching braces, commas, quotes)
   - Validate the structure matches: `{"mcpServers": {"server_name": {"command": "...", "args": [...], ...}}}`
   - Use `execute_command` with `python -m json.tool < file.json` or `jq . < file.json` to validate
   - If validation fails, report the error to the user and do NOT write the invalid file

2. **For `.my_cline_config`**:
   - Ensure valid JSON syntax
   - Validate required fields exist: `remote_url`, `sync_keys`, `ignore_keys`

3. **General JSON rules**:
   - No trailing commas
   - All keys and string values must be double-quoted
   - Proper escaping of special characters in strings
   - Correct nesting of objects and arrays

## Important Rules

- **NEVER overwrite the user's local `cline_mcp_settings.json` entirely** — always merge at the field level, preserving `ignore_keys` values
- **ALWAYS ask the user before deleting** a server or file
- **ALWAYS show a diff summary** before applying changes
- **ALWAYS validate JSON format** after modifications before writing to file
- **Preserve user local preferences** (`autoApprove`, `disabled`, `timeout`, `type`) during download
- **The remote `cline_mcp_settings.json` should be minimal** — only `sync_keys` fields
- **Handle the case where the remote repository is empty** (first-time setup) gracefully
- **If git operations fail**, report the error to the user and stop the workflow
- **If JSON validation fails**, report the specific error and do NOT proceed with writing the file

---

## Tools Required

| Tool | Purpose |
|------|---------|
| `read_file` | Read config files, MCP settings, folder contents |
| `write_to_file` | Write merged config files |
| `replace_in_file` | Apply targeted merges to config files |
| `execute_command` | Git operations (init, add, commit, push, pull, diff, fetch) |
| `search_files` | Find specific configurations across files |
| `list_files` | Explore folder structures |
| `ask_followup_question` | Ask user for remote URL, conflict resolution choices |
| `attempt_completion` | Present final results to the user |

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Remote URL not configured | Ask user for the URL and save to `.my_cline_config` |
| Git not installed | Report error, cannot proceed |
| Network / authentication error | Report error details to user |
| Merge conflict during pull | Ask user how to resolve (theirs/ours/manual) |
| Corrupted `.my_cline_config` | Use default sync_keys and ignore_keys |
| Empty remote repository | Proceed with upload mode logic (nothing to compare against) |
| Missing `cline_mcp_settings.json` locally | Treat as empty config, all remote servers are "new" |