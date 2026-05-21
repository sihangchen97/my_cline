# my_cline - Cline Configuration Sync

A workflow for syncing Cline configuration files (Hooks, MCP, Rules, Workflows folders and `cline_mcp_settings.json`) to and from a remote git repository.

---

## For End Users

### What is my_cline?

`my_cline` is a Cline Workflow that helps you backup and synchronize your Cline configuration across multiple machines. It syncs the following:

- `Rules/` - Cline rules
- `Workflows/` - Cline workflows
- `cline_mcp_settings.json` - MCP server settings (minimal format)

### Usage

Once configured, simply tell Cline:

- **`my_cline upload`** — Push local configuration changes to the remote repository
- **`my_cline download`** — Pull remote configuration changes to the local machine

---

## For LLM: Automated Setup Instructions

When the user asks you to set up `my_cline`, follow these steps. The user should provide a remote git repository URL (e.g., `git@github.com:username/my_cline.git`).

### Step 1: Get Remote Repository URL

1. If the user provided a repository URL, use it directly.
2. If not, use `ask_followup_question` to ask for the remote git repository link.
3. Accept SSH format (`git@github.com:owner/repo.git`) or HTTPS format (`https://github.com/owner/repo.git`).

### Step 2: Convert URL to Raw URL

Convert the repository URL to a GitHub raw content URL:

- `git@github.com:owner/repo.git` → `https://raw.githubusercontent.com/owner/repo/main/`
- `https://github.com/owner/repo` → `https://raw.githubusercontent.com/owner/repo/main/`

### Step 3: Download Files

Use `curl` to download two files from the raw URL:

**`CLINE_GLOBAL_PATH` by platform:**

| Platform | Path |
|----------|------|
| macOS/Linux | `~/Documents/Cline/` |
| Windows | `$env:USERPROFILE\Cline\` |

```bash
# Ensure Workflows directory exists
mkdir -p <CLINE_GLOBAL_PATH>/Workflows

# Download my_cline.md
curl -sL <raw_url>/Workflows/my_cline.md -o <CLINE_GLOBAL_PATH>/Workflows/my_cline.md

# Download .my_cline_config
curl -sL <raw_url>/.my_cline_config -o <CLINE_GLOBAL_PATH>/.my_cline_config
```

If either download fails (non-zero exit code), report the error to the user and stop.

### Step 4: First Sync

Tell the user to run **`my_cline download`** to perform the first sync. The workflow will automatically:

1. Initialize a local git repository (if not already initialized)
2. Configure the remote `origin`
3. Pull the latest remote configuration
4. Handle conflict resolution for all config files

---

## Repository Structure

```
remote-repo/
├── README.md                      # This file
├── .my_cline_config               # Sync configuration
├── cline_mcp_settings.json        # Minimal MCP settings (sync_keys only)
├── Workflows/
│   └── my_cline.md                # The workflow definition
├── Hooks/                         # Cline hooks
├── MCP/                           # MCP server configs
├── Rules/                         # Cline rules
└── Workflows/                     # Other workflows
```

## MCP Settings Sync Behavior

### `sync_keys` — Synced to Remote

| Key | Description |
|-----|-------------|
| `command` | MCP server launch command (e.g., `npx`, `uvx`) |
| `args` | Command-line arguments for the server |
| `env` | Environment variables for the server |

### `ignore_keys` — Local Only (Not Synced)

| Key | Description |
|-----|-------------|
| `autoApprove` | User's auto-approve tool preferences |
| `disabled` | Whether the server is disabled locally |
| `timeout` | User-configured timeout settings |
| `type` | Connection type (always `stdio`) |

During **upload**, only `sync_keys` fields are pushed to the remote repository.
During **download**, `sync_keys` fields are merged into the local config while preserving `ignore_keys` values.

## Conflict Resolution

The workflow guides users through conflict resolution for:

- **New servers** — Add to remote/local or skip
- **Removed servers** — Delete from remote/local or keep
- **Modified servers** — Use local version, remote version, or merge field-by-field
- **Folder changes** — Upload/download all, skip, or select files manually

All JSON files are validated after modifications to ensure correct format before writing.
