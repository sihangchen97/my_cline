# Conda Environment Rules

## 1. Overview

- **Purpose**: Cross-platform Python package and environment management via Conda
- **Supported Languages**: Python only
- **Platform Support**: Windows, macOS, Linux

---

## 2. MANDATORY: Always Use Specified Conda Environment

- **ALL** Python commands (`python`, `pip`, `pytest`, etc.) MUST run inside a specified conda environment
- **NEVER** use system Python or the `base` environment
- If no conda environment is specified by the user, **ALWAYS ask** which environment to use before proceeding
- Check available environments with: `conda info --envs`

### Preferred: Use `conda run` to Execute Python

Use `conda run -n <env>` to run commands in a specific environment without activation:

```bash
conda run -n myenv python script.py
conda run -n myenv pytest tests/
```

---

## 3. MANDATORY: Never Install Packages Yourself

- **NEVER** install any packages yourself under any circumstances
- **NEVER** run `pip install`, `conda install`, `pip uninstall`, or `conda remove` commands at any time
- If packages are missing, **always** report to the user with install commands and wait for them to install manually

### Providing Install Commands to Users

When the user needs to install packages, provide the install commands in the following priority order:

1. **pip install (Priority)** — Always provide pip install command first:
   ```
   conda run -n <env> pip install <package>
   ```

2. **conda install (Fallback)** — Only if the package is not available via pip:
   ```
   conda install -n <env> <package>
   ```

### Example Format for User

When reporting missing packages, present them like this:

```
The following packages are missing from the environment:
- gradio
- transformers

Please install them using:
  conda run -n myenv pip install gradio transformers
```

---

## 4. MANDATORY: Analyze Dependencies Before Running Python

**Before running any Python script, ALWAYS analyze the script first:**

1. **Read the Python file** to identify all `import` statements
2. **Check which packages are already installed** in the target environment: `conda list -n <env>`
3. **Compare imports vs installed packages** to identify missing dependencies
4. **Present ALL missing packages to the user in a single batch** with install commands
5. **Wait for the user to install the packages manually**

**Example workflow:**

```
Before running script.py:
1. Read script.py -> found imports: torch, numpy, gradio, transformers
2. Check installed packages in env -> found: torch, numpy
3. Missing packages: gradio, transformers
4. Present to user: "The following packages are missing: gradio, transformers.
   Please install them using: conda run -n myenv pip install gradio transformers"
5. Wait for user to confirm installation
```

**Do NOT show packages one by one.** Batch all missing packages together for efficiency.

---

## 5. Handle Runtime Import Errors

**If the script fails with an `ImportError` or `ModuleNotFoundError`:**

1. Extract the missing package name(s) from the error
2. **Report the missing packages to the user** with install commands (pip优先)
3. **Wait for the user to install them manually**
4. **NEVER** install the packages yourself
5. After user confirms installation, re-run the script

---

## 6. Safe Operations (No Approval Needed)

- List environments: `conda info --envs`
- List packages: `conda list -n <env>`
- Run Python script: `conda run -n <env> python script.py`

---

## 7. Quick Reference

```bash
# List environments
conda info --envs

# List packages in environment
conda list -n myenv

# Run Python in environment
conda run -n myenv python script.py

# Run pytest in environment
conda run -n myenv pytest tests/
```

### User Install Commands (Provide to User, Do NOT Execute)

```bash
# pip install (preferred)
conda run -n myenv pip install package-name

# conda install (fallback if not available via pip)
conda install -n myenv package-name