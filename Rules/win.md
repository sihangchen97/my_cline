# Windows Environment Rules

## 1. System Overview

- **Operating System**: Windows 11
- **Default Shell**: PowerShell (`C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe`)

> **MANDATORY**: All commands MUST be executed using **PowerShell** syntax. If the detected environment is NOT PowerShell, you must warn the user before proceeding.

---

## 2. Path Handling Rules

### 2.1 Slash Convention

- Use **forward slashes** `/` or **escaped backslashes** `\\` in strings to avoid escape character issues
- Never use a single unescaped backslash `\` in path strings, as it acts as an escape character (e.g., `\n` becomes a newline)
- Example: `C:\\Users\\sihang\\project` or `C:/Users/sihang/project`

### 2.2 Drive Letters

- Windows paths include a drive letter prefix (e.g., `D:\`, `C:\`)
- Always include the drive letter when using absolute paths
- The current working directory is pinned — do not `cd` into a different directory. Prepend with `cd <dir> && <cmd>` if a command must run elsewhere

### 2.3 Home Directory References

- Do NOT use `~` or `$HOME` to refer to the home directory
- Use the full path instead: `C:\Users\sihang`
- PowerShell equivalent: `$env:USERPROFILE`

### 2.4 Path Separators in Code

- In Python, prefer `pathlib.Path` for cross-platform path handling
- When writing hardcoded paths, use raw strings: `r"C:\path\to\file"` or double backslashes

---

## 3. PowerShell Command Rules

### 3.1 Mandatory PowerShell Usage

- **All CLI commands must use PowerShell syntax**
- Before executing any command, verify the shell is PowerShell
- If the environment is CMD, Git Bash, WSL, or any other shell, **notify the user first**

### 3.2 Command Chaining

- Use `;` to run commands sequentially regardless of success
- Use `&&` to run a command only if the previous one succeeded
- Example: `python script.py && code output.md`

### 3.3 Avoid Interactive Commands

- Use flags to disable pagers: `--no-pager` (e.g., `git --no-pager log`)
- Auto-confirm prompts when safe: `-y`, `-Force`, `-Confirm:$false`
- Provide input via arguments/flags rather than stdin
- Example: `Remove-Item -Path "file.txt" -Force`

### 3.4 Error Handling

- Redirect stderr to stdout for commands that may fail: `command 2>&1`
- Check exit status `$LASTEXITCODE` after running external commands
- Example:
  ```powershell
  python train.py 2>&1
  if ($LASTEXITCODE -ne 0) { Write-Error "Training failed with code $LASTEXITCODE" }
  ```

### 3.5 Common PowerShell Cmdlets

| Operation | PowerShell Cmdlet |
|-----------|------------------|
| List files | `Get-ChildItem` / `ls` |
| Change directory | `Set-Location` / `cd` |
| Remove file/dir | `Remove-Item` / `rm` |
| Copy file/dir | `Copy-Item` / `cp` |
| Move file/dir | `Move-Item` / `mv` |
| Create directory | `New-Item -ItemType Directory` / `mkdir` |
| Search in files | `Select-String` / `select-string` |
| View file content | `Get-Content` / `cat` |

---

## 4. Environment Variables

### 4.1 PowerShell Syntax

- Access: `$env:VAR_NAME`
- Set (session-only): `$env:VAR_NAME = "value"`
- Set (persistent): `[System.Environment]::SetEnvironmentVariable("VAR_NAME", "value", "User")`

### 4.2 Common Environment Variables

| Variable | Description |
|----------|-------------|
| `$env:USERPROFILE` | Current user's home directory (`C:\Users\sihang`) |
| `$env:TEMP` / `$env:TMP` | Temporary directory |
| `$env:PROGRAMFILES` | Program Files directory (`C:\Program Files`) |
| `$env:PROGRAMFILES(X86)` | Program Files (x86) directory |
| `$env:PATH` | System PATH |
| `$env:COMPUTERNAME` | Computer name |
| `$env:USERNAME` | Current username |

### 4.3 CMD Syntax (Reference Only)

- CMD uses `%VAR_NAME%` syntax — be aware when reading legacy documentation
- Do NOT use CMD syntax in PowerShell commands

---

## 5. File System Characteristics

### 5.1 Case Insensitivity

- Windows file systems (NTFS, ReFS) are **case-insensitive** by default
- `File.txt`, `file.txt`, and `FILE.TXT` refer to the same file
- Be cautious when referencing files with similar names differing only in case

### 5.2 Reserved File Names

The following names are reserved and cannot be used as file or directory names:
- `CON`, `PRN`, `AUX`, `NUL`
- `COM1`–`COM9`, `LPT1`–`LPT9`
- Example: You cannot create a file named `CON.txt`

### 5.3 MAX_PATH Limitation

- Default maximum path length: **260 characters**
- Long paths may cause errors in some tools
- Enable long path support via registry or Group Policy if needed
- Workaround: Use `cd` to a parent directory or enable `$env:POSSHELL_ENABLE_LONG_PATHS`

### 5.4 File Permissions

- Some operations require **Administrator privileges** (e.g., writing to `C:\Program Files`)
- Run PowerShell as Administrator when permission denied errors occur
- Check file locks: other processes may prevent file access
- Use `Get-Acl` to view permissions, `Set-Acl` to modify

---

## 6. Common Issues

(TBD — to be updated as issues are encountered)