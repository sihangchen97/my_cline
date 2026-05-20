---
description: Runs a Python script in the correct conda environment with automatic dependency checking
---

# Run Python Workflow

## Objective
When the user asks to run a Python script, follow this workflow to ensure the script executes in the correct conda environment with all dependencies installed.

## Steps

### 1. Identify the Python Script
- Determine which Python script the user wants to run
- If not specified, ask the user which script to run

### 2. Read & Analyze the Script
- Read the Python file to identify all `import` statements
- Build a list of required third-party packages (exclude standard library modules)

### 3. Determine the Conda Environment
- If the user has already specified an environment, use it directly
- If not specified, ask the user which conda environment to use
- Verify the environment exists with `conda info --envs`

### 4. Check Installed Packages
- Run `conda list -n <env>` to get the list of installed packages
- Compare the required imports against installed packages
- Identify missing dependencies

### 5. Report Missing Packages to User
- Present **all** missing packages to the user in a **single batch**
- Provide the install commands for the user to execute manually, e.g.:
  ```
  conda run -n <env> pip install <pkg1> <pkg2> <pkg3>
  ```
- **Wait for the user to install the packages on their own**
- **NEVER** install packages yourself under any circumstances

### 6. Re-check Dependencies After User Installation
- After the user confirms installation is complete, run `conda list -n <env>` again
- Verify all previously missing packages are now installed
- If packages are still missing, report them to the user again and wait

### 7. Execute the Python Script
- Run the script using `conda run -n <env> python <script_path>`
- Monitor the output and report results to the user

### 8. Handle Runtime Import Errors
- If the script fails with an `ImportError` or `ModuleNotFoundError`:
  - Extract the missing package name(s) from the error
  - **Report the missing packages to the user** with install commands
  - **Wait for the user to install them manually**
  - **NEVER** install the packages yourself
- If the error is a code issue, report to the user for debugging

## Important Rules
- **NEVER** use system Python or the `base` environment
- **ALWAYS** use `conda run -n <env>` prefix for all Python commands
- **NEVER** install any packages yourself — the user must install all packages manually
- **NEVER** run `pip install` or `conda install` commands at any time
- If packages are missing (discovered before or during runtime), **always** report to the user and wait
- **ALWAYS** re-check dependencies after the user confirms installation
