#!/bin/bash
# Stop all Claude Trader instances (MNQ, MES, MCL).

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SESSION="micro-trader"

echo -e "${YLW}=== Stopping all Claude Trader instances ===${NC}"

# Stop background processes via each project's stop.sh
for INST in MNQ MES MCL; do
    STOP_SCRIPT="$BASE_DIR/$INST/stop.sh"
    if [ -f "$STOP_SCRIPT" ]; then
        echo -e "  Stopping $INST..."
        bash "$STOP_SCRIPT"
    else
        echo -e "  ${YLW}WARN: $STOP_SCRIPT not found, skipping.${NC}"
    fi
done

# Kill the tmux session
if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux kill-session -t "$SESSION"
    echo -e "${GRN}tmux session '$SESSION' killed.${NC}"
else
    echo "tmux session '$SESSION' was not running."
fi

echo -e "${GRN}All instances stopped.${NC}"
