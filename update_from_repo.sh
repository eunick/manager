#!/bin/bash
# Pull latest changes from GitHub repo defined in .env

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

# Inject token into URL  e.g. https://TOKEN@github.com/...
AUTH_URL="${GITHUB_REPO/https:\/\//https://$GITHUB_TOKEN@}"

echo -e "${BLU}=== Pulling update from GitHub ===${NC}"
echo "  Repo: $GITHUB_REPO"

# Init repo if needed
if [ ! -d ".git" ]; then
    echo -e "${YLW}No git repo found — cloning...${NC}"
    git clone "$AUTH_URL" . || { echo -e "${RED}Clone failed.${NC}"; exit 1; }
    echo -e "${GRN}Cloned successfully.${NC}"
    exit 0
fi

# Ensure remote uses auth URL (stored locally, not committed)
git remote set-url origin "$AUTH_URL"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Warn if there are local uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YLW}WARNING: You have uncommitted local changes.${NC}"
    read -r -p "  Continue and merge anyway? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

if git pull origin "$BRANCH"; then
    echo -e "${GRN}Up to date on branch '$BRANCH'.${NC}"
else
    echo -e "${RED}Pull failed. Check conflicts or network.${NC}"
    exit 1
fi
