#!/bin/bash

# ============================================================
# MCP Settings Sync Script
# Usage: ./mcp_settings.sh [track|apply] [c|ci]
#   track  - Copy IDE config to Git and show Diff
#   apply  - Pull latest from cloud, merge, then overwrite IDE
#   c      - VS Code
#   ci     - VS Code Insiders
# ============================================================

set -e

# ---------------------- CONFIG ----------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The git-tracked file name
GIT_FILE="$SCRIPT_DIR/cline_mcp_settings.json"

# IDE config file paths
CODE_PATH="$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
CODE_INSIDERS_PATH="$HOME/Library/Application Support/Code - Insiders/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
# ----------------------------------------------------

cd "$SCRIPT_DIR"

# ---------------------- HELPERS ---------------------
print_info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
print_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo ""
    echo "Usage: ./mcp_settings.sh [action] [env]"
    echo "--------------------------------------------"
    echo "  Action:  track  - Copy IDE config to Git and show Diff"
    echo "          apply  - Pull latest from cloud, merge, then overwrite IDE"
    echo ""
    echo "  Env:     c   - VS Code"
    echo "          ci  - VS Code Insiders"
    echo ""
    echo "Examples:"
    echo "  ./mcp_settings.sh track c    # Capture VS Code config changes"
    echo "  ./mcp_settings.sh apply ci   # Apply cloud config to Insiders"
    echo "--------------------------------------------"
    exit 1
}

get_env_config() {
    local env="$1"
    case "$env" in
        c)
            BRANCH="c"
            IDE_PATH="$CODE_PATH"
            IDE_NAME="VS Code"
            ;;
        ci)
            BRANCH="ci"
            IDE_PATH="$CODE_INSIDERS_PATH"
            IDE_NAME="VS Code Insiders"
            ;;
        *)
            print_error "Unknown environment: $env (only c or ci supported)"
            usage
            ;;
    esac
}

check_ide_file_exists() {
    if [ ! -f "$IDE_PATH" ]; then
        print_error "Config not found for $IDE_NAME: $IDE_PATH"
        print_warn "Is the Cline plugin installed in $IDE_NAME?"
        exit 1
    fi
}

ensure_branch() {
    git fetch origin main "$BRANCH" 2>/dev/null || true

    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        if ! git merge-base --is-ancestor main "$BRANCH" 2>/dev/null; then
            print_info "Merging main into $BRANCH..."
            git checkout "$BRANCH" 2>/dev/null
            git merge main --no-edit 2>/dev/null || {
                print_warn "Merge had conflicts. Please resolve manually."
                git merge --abort 2>/dev/null || true
            }
        else
            git checkout "$BRANCH" 2>/dev/null
        fi
    else
        print_info "Creating branch $BRANCH from main..."
        git checkout -b "$BRANCH" main 2>/dev/null
    fi
}

copy_ide_to_git() {
    cp "$IDE_PATH" "$GIT_FILE"
    print_info "Copied $IDE_NAME config to cline_mcp_settings.json"
}

copy_git_to_ide() {
    cp "$GIT_FILE" "$IDE_PATH"
    print_ok "$IDE_NAME config updated!"
}
# ----------------------------------------------------

# ---------------------- VALIDATE -------------------
if [ $# -lt 2 ]; then
    usage
fi

ACTION="$1"
ENV="$2"

if [[ "$ACTION" != "track" && "$ACTION" != "apply" ]]; then
    print_error "Unknown action: $ACTION (only track or apply supported)"
    usage
fi

get_env_config "$ENV"
check_ide_file_exists
# ----------------------------------------------------

print_info "Env: $IDE_NAME | Branch: $BRANCH | Action: $ACTION"
echo "---------------------------------------------------"

# Ensure correct branch
ensure_branch

# Always copy IDE config to git file after switching branch
copy_ide_to_git

case "$ACTION" in
    track)
        git --no-pager diff --color -- "$GIT_FILE"
        git status --short -- "$GIT_FILE"
        print_info "Manually commit / merge these changes when ready."
        ;;

    apply)
        print_info "Pulling latest from cloud for branch $BRANCH..."
        git pull origin "$BRANCH" 2>/dev/null || print_warn "Cloud branch $BRANCH not found, using local."

        # Save local IDE config, restore cloud version for comparison
        git stash 2>/dev/null || true
        copy_ide_to_git
        cp "$GIT_FILE" "${GIT_FILE}.local"
        git checkout HEAD -- "$GIT_FILE" 2>/dev/null

        print_info "Merging cloud + local config..."
        if git merge-file "$GIT_FILE" "${GIT_FILE}.local" "$(git show HEAD:"cline_mcp_settings.json" 2>/dev/null || echo '{}')" 2>/dev/null; then
            rm -f "${GIT_FILE}.local" "${GIT_FILE}.orig"
            git --no-pager diff --color -- "$GIT_FILE" || true
            copy_git_to_ide
            print_ok "Merge successful, $IDE_NAME config updated!"
        else
            rm -f "${GIT_FILE}.local"
            echo ""
            print_error "Merge conflict!"
            echo -e "   Resolve with: ${YELLOW}./mcp_settings.sh track $ENV${NC}"
            echo ""
            git checkout HEAD -- "$GIT_FILE" 2>/dev/null || true
            exit 1
        fi
        ;;
esac

echo ""
echo "---------------------------------------------------"
print_ok "Done!"