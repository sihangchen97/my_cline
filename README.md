# my_cline - Cline Configuration Sync

A workflow for syncing Cline configuration files (Hooks, MCP, Rules, Workflows folders and `cline_mcp_settings.json`) to and from a remote git repository.

---

## For End Users

### What is my_cline?

`my_cline` is a Cline Workflow that helps you backup and synchronize your Cline configuration across multiple machines. It syncs the following:

- `Hooks/` - Cline hooks configuration
- `MCP/` - MCP server configurations
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

### Step 1: Obtain the Remote Repository URL

1. If the user provided a repository URL, use it directly
2. If the user did NOT provide a URL, use `ask_followup_question` to ask for the remote git repository link
3. Accept both SSH format (`git@github.com:owner/repo.git`) and HTTPS format (`https://github.com/owner/repo.git`)

### Step 2: Fetch Workflow File from Remote

Convert the repository URL to a raw content URL and fetch the workflow file:

**SSH to raw URL conversion:**
- `git@github.com:owner/repo.git` → `https://raw.githubusercontent.com/owner/repo/main/`
- `git@github.com:owner/repo.git` → `https://raw.githubusercontent.com/owner/repo/master/` (try main first, then master)

**HTTPS to raw URL conversion:**
- `https://github.com/owner/repo` → `https://raw.githubusercontent.com/owner/repo/main/`

**Fetch the workflow file:**
Use `fetch_txt` or `fetch_readable` to get `Workflows/my_cline.md` from the raw URL:

```
https://raw.githubusercontent.com/owner/repo/main/Workflows/my_cline.md
```

If the file cannot be fetched (404 or error), report the error to the user and stop.

### Step 3: Configure `.my_cline_config`

Create or update the `.my_cline_config` file at the root of the Cline configuration directory with the following content:

```json
{
  "remote_url": "<the_repository_url_provided_by_user>",
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

Replace `<the_repository_url_provided_by_user>` with the actual URL the user provided.

### Step 4: Install the Workflow

Write the fetched `my_cline.md` content to the local `Workflows/` directory:

```
<cline_config_dir>/Workflows/my_cline.md
```

If the `Workflows/` directory does not exist, create it first.

### Step 5: First Sync

After installation is complete, tell the user to run **`my_cline download`** to perform the first sync. The workflow will automatically:

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