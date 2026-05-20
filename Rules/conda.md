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
conda run -n myenv pip install package-name
conda run -n myenv pytest tests/
```

---

## 3. MANDATORY: User Approval Required

The following operations **ALWAYS require explicit user approval** before execution:

### 3.1 Environment Operations (require approval)

- **Create environment**: `conda create --name myenv python=3.10`
- **Remove environment**: `conda remove --name myenv --all`

### 3.2 Package Operations via Conda (require approval)

- **Install**: `conda install -n myenv <package>`
- **Update**: `conda update -n myenv <package>`
- **Remove**: `conda remove -n myenv <package>`

### 3.3 Package Operations via Pip (require approval)

- **Install**: `conda run -n myenv pip install <package>`
- **Uninstall**: `conda run -n myenv pip uninstall <package>`

### 3.4 Safe Operations (no approval needed)

- List environments: `conda info --envs`
- List packages: `conda list -n myenv`

---

## 4. MANDATORY: Analyze Dependencies Before Running Python

**Before running any Python script, ALWAYS analyze the script first:**

1. **Read the Python file** to identify all `import` statements
2. **Check which packages are already installed** in the target environment: `conda list -n myenv`
3. **Compare imports vs installed packages** to identify missing dependencies
4. **Present ALL missing packages to the user in a single batch** for approval
5. **Install all missing packages together** after user approval

**Example workflow:**

```
Before running script.py:
1. Read script.py -> found imports: torch, numpy, gradio, transformers
2. Check installed packages in env -> found: torch, numpy
3. Missing packages: gradio, transformers
4. Present to user: "The following packages are missing: gradio, transformers. 
   Would you like me to install all of them?"
5. After approval: conda run -n myenv pip install gradio transformers
```

**Do NOT show packages one by one with separate approvals.** Batch all missing packages together for efficiency, but install them one by one for sure.

---

## 5. MANDATORY: Re-confirm for New Dependencies During Installation

**During package installation, new dependencies may be discovered dynamically.** Even if the user approved the initial batch of packages:

- If the installation process reveals **additional new packages** that were not in the original approval list, you **MUST re-confirm** with the user before installing these new packages
- Present the newly discovered packages to the user and get explicit approval before proceeding
- Example: User approves installing `gradio`, but during installation `gradio` requires `websockets` which is also missing. You must ask the user again: "During installation, the following new dependencies were discovered: websockets. Would you like me to install these as well?"

**Every batch of new dependencies requires a new user approval.** Never assume the initial approval covers dependencies discovered later during the installation process.

---

## 6. Quick Reference

```bash
# List environments
conda info --envs

# Create environment
conda create --name myenv python=3.10 -y

# Run Python in environment
conda run -n myenv python script.py

# Install package (conda)
conda install -n myenv numpy

# Install package (pip)
conda run -n myenv pip install package-name

# Remove environment
conda remove --name myenv --all