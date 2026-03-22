#!/bin/bash
# =============================================================================
# Task 1: System Monitoring Setup
# Author: Fresher DevOps Engineer (Assisting Rahul, Senior DevOps - TechCorp)
# Description: Installs and configures htop/nmon, sets up disk and process
#              monitoring, and logs system metrics to a report file.
# =============================================================================

LOG_DIR="/var/log/sysmonitor"
LOG_FILE="$LOG_DIR/metrics_$(date +%Y-%m-%d).log"
REPORT_FILE="$LOG_DIR/system_report_$(date +%Y-%m-%d_%H-%M-%S).log"

# ----------------------------
# 1. Create log directory
# ----------------------------
echo "[INFO] Creating log directory: $LOG_DIR"
sudo mkdir -p "$LOG_DIR"
sudo chmod 755 "$LOG_DIR"

# ----------------------------
# 2. Install monitoring tools
# ----------------------------
echo "[INFO] Installing htop and nmon..."

if command -v apt-get &>/dev/null; then
    sudo apt-get update -y
    sudo apt-get install -y htop nmon sysstat
elif command -v yum &>/dev/null; then
    sudo yum install -y htop nmon sysstat
elif command -v dnf &>/dev/null; then
    sudo dnf install -y htop nmon sysstat
else
    echo "[WARN] Package manager not detected. Please install htop and nmon manually."
fi

echo "[INFO] htop version: $(htop --version 2>/dev/null | head -1)"
echo "[INFO] nmon version: $(nmon -V 2>/dev/null | head -1)"

# ----------------------------
# 3. Capture system metrics
# ----------------------------
echo "[INFO] Capturing system metrics to: $REPORT_FILE"

{
    echo "============================================================"
    echo "  SYSTEM MONITORING REPORT - TechCorp DevOps"
    echo "  Generated: $(date)"
    echo "  Hostname : $(hostname)"
    echo "============================================================"
    echo ""

    # --- CPU Info ---
    echo ">>> CPU INFORMATION"
    echo "------------------------------------------------------------"
    lscpu | grep -E "Architecture|CPU\(s\)|Model name|CPU MHz|Cache"
    echo ""

    # --- Memory Usage ---
    echo ">>> MEMORY USAGE"
    echo "------------------------------------------------------------"
    free -h
    echo ""

    # --- CPU & Memory via top (batch mode, 1 snapshot) ---
    echo ">>> TOP PROCESSES (CPU & Memory snapshot)"
    echo "------------------------------------------------------------"
    top -b -n 1 | head -20
    echo ""

    # --- Disk Usage (df) ---
    echo ">>> DISK USAGE (df -h)"
    echo "------------------------------------------------------------"
    df -h
    echo ""

    # --- Directory Size (du) for common paths ---
    echo ">>> DIRECTORY SIZES (du -sh)"
    echo "------------------------------------------------------------"
    for dir in /home /var /tmp /etc /usr; do
        if [ -d "$dir" ]; then
            sudo du -sh "$dir" 2>/dev/null
        fi
    done
    echo ""

    # --- Running Processes ---
    echo ">>> ALL RUNNING PROCESSES (ps aux)"
    echo "------------------------------------------------------------"
    ps aux --sort=-%cpu | head -20
    echo ""

    # --- Top 5 CPU-intensive processes ---
    echo ">>> TOP 5 CPU-INTENSIVE PROCESSES"
    echo "------------------------------------------------------------"
    ps aux --sort=-%cpu | awk 'NR<=6 {print}' | column -t
    echo ""

    # --- Top 5 Memory-intensive processes ---
    echo ">>> TOP 5 MEMORY-INTENSIVE PROCESSES"
    echo "------------------------------------------------------------"
    ps aux --sort=-%mem | awk 'NR<=6 {print}' | column -t
    echo ""

    # --- Network interfaces ---
    echo ">>> NETWORK INTERFACES"
    echo "------------------------------------------------------------"
    ip addr show 2>/dev/null || ifconfig 2>/dev/null
    echo ""

    # --- Uptime ---
    echo ">>> SYSTEM UPTIME"
    echo "------------------------------------------------------------"
    uptime
    echo ""

    echo "============================================================"
    echo "  END OF REPORT"
    echo "============================================================"

} | sudo tee "$REPORT_FILE" > /dev/null

echo "[SUCCESS] System report saved to: $REPORT_FILE"
cat "$REPORT_FILE"

# ----------------------------
# 4. Set up cron for automated logging (every hour)
# ----------------------------
CRON_JOB="0 * * * * /bin/bash $(realpath $0) >> $LOG_DIR/cron.log 2>&1"
(sudo crontab -l 2>/dev/null | grep -v "task1_monitoring"; echo "$CRON_JOB") | sudo crontab -
echo "[INFO] Cron job set: Monitoring runs every hour."
echo "[DONE] Task 1 - System Monitoring Setup Complete."
