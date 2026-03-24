#!/bin/bash
# Push local changes to GitHub repo defined in .env

RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[1;34m'
YLW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

cd "$SCRIPT_DIR" || { echo -e "${RED}ERROR: Cannot cd to $SCRIPT_DIR${NC}"; exit 1; }

# Load .env
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}ERROR: .env not found at $ENV_FILE${NC}"
    exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

[ -z "${GITHUB_REPO:-}" ]  && { echo -e "${RED}ERROR: GITHUB_REPO not set in .env${NC}"; exit 1; }
[ -z "${GITHUB_TOKEN:-}" ] && { echo -e "${RED}ERROR: GITHUB_TOKEN not set in .env${NC}"; exit 1; }

# Inject token into URL
AUTH_URL="${GITHUB_REPO/https:\/\//https://$GITHUB_TOKEN@}"

# Init git repo if not already one
if [ ! -d ".git" ]; then
    echo -e "${BLU}Initialising git repository...${NC}"
    git init
    git remote add origin "$AUTH_URL"
fi

# Ensure remote uses auth URL (stored locally, not committed)
git remote set-url origin "$AUTH_URL"

echo -e "${BLU}=== Pushing update to GitHub ===${NC}"
echo "  Repo: $GITHUB_REPO"

# Ensure .env and sensitive files are ignored
if [ ! -f ".gitignore" ] || ! grep -q "^\.env$" ".gitignore" 2>/dev/null; then
    echo ".env" >> .gitignore
    echo -e "${YLW}Added .env to .gitignore${NC}"
fi

# Stage all changes
git add -A

# Check if there's anything to commit
if git diff --cached --quiet; then
    echo -e "${YLW}Nothing to commit — working tree clean.${NC}"
else
    if [ -n "$1" ]; then
        MSG="$1"
    else
        read -r -p "  Commit message (leave blank for default): " MSG
        [ -z "$MSG" ] && MSG="Update $(date '+%Y-%m-%d %H:%M')"
    fi
    git commit -m "$MSG"
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
if git push origin "$BRANCH" 2>/dev/null; then
    echo -e "${GRN}Pushed to origin/$BRANCH successfully.${NC}"
else
    echo -e "${YLW}Setting upstream and pushing...${NC}"
    git push --set-upstream origin "$BRANCH"
fi
