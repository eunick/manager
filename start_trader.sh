#!/bin/bash
# Start all three Claude Trader instances (MNQ, MES, MCL) in a tmux session.

RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[1;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SESSION="micro-trader"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${RED}tmux session '$SESSION' already exists.${NC}"
    read -r -p "  Kill it and restart all? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    tmux kill-session -t "$SESSION"
fi

echo -e "${BLU}=== Starting all Claude Trader instances ===${NC}"

tmux new-session  -d -s "$SESSION" -n "MNQ" "bash $BASE_DIR/MNQ/start_bg.sh; exec bash"
tmux new-window      -t "$SESSION"  -n "MES" "bash $BASE_DIR/MES/start_bg.sh; exec bash"
tmux new-window      -t "$SESSION"  -n "MCL" "bash $BASE_DIR/MCL/start_bg.sh; exec bash"

# LOGS window: 3 panes, one tail per trader
tmux new-window -t "$SESSION" -n "LOGS"
tmux send-keys  -t "$SESSION:LOGS" "tail -f /mnt/c/Claude_Trader/mnq/trader_agent_MNQ.log" Enter
tmux split-window -t "$SESSION:LOGS" -h "tail -f /mnt/c/Claude_Trader/mes/trader_agent_MES.log"
tmux split-window -t "$SESSION:LOGS" -v "tail -f /mnt/c/Claude_Trader/mcl/trader_agent_MCL.log"
tmux select-layout -t "$SESSION:LOGS" even-horizontal

tmux select-window -t "$SESSION:LOGS"
tmux attach-session -t "$SESSION"

echo -e "${GRN}All instances launched in tmux session '$SESSION'.${NC}"
echo "  Switch windows : Ctrl+B then 0/1/2  (or Ctrl+B n/p)"
echo "  Detach         : Ctrl+B d"
echo "  Re-attach      : tmux attach -t $SESSION"
