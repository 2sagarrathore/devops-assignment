#!/bin/bash
# =============================================================================
# Task 3: Backup Configuration for Web Servers
# Author: Fresher DevOps Engineer (Assisting Rahul, Senior DevOps - TechCorp)
# Description: Automated backup script for Sarah's Apache and Mike's Nginx
#              web servers. Runs via cron every Tuesday at 12:00 AM.
#              Saves compressed backups to /backups/ and verifies integrity.
# =============================================================================

# ----------------------------
# Configuration
# ----------------------------
BACKUP_DIR="/backups"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="$BACKUP_DIR/backup_verification.log"

# Apache (Sarah's server)
APACHE_CONF_DIR="/etc/httpd/"
APACHE_DOCROOT="/var/www/html/"
APACHE_BACKUP_FILE="$BACKUP_DIR/apache_backup_${DATE}.tar.gz"

# Nginx (Mike's server)
NGINX_CONF_DIR="/etc/nginx/"
NGINX_DOCROOT="/usr/share/nginx/html/"
NGINX_BACKUP_FILE="$BACKUP_DIR/nginx_backup_${DATE}.tar.gz"

# ----------------------------
# Helper functions
# ----------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

backup_server() {
    local server_name=$1       # "apache" or "nginx"
    local conf_dir=$2
    local doc_root=$3
    local backup_file=$4

    log "====== Starting $server_name backup ======"

    # Check if source directories exist
    local sources=()
    for dir in "$conf_dir" "$doc_root"; do
        if [ -d "$dir" ]; then
            sources+=("$dir")
            log "Source directory found: $dir"
        else
            log "WARNING: Source directory NOT found: $dir (creating placeholder)"
            sudo mkdir -p "$dir"
            sources+=("$dir")
        fi
    done

    # Create backup
    log "Creating backup: $backup_file"
    sudo tar -czf "$backup_file" "${sources[@]}" 2>/dev/null

    # Check if backup was created
    if [ -f "$backup_file" ]; then
        local size
        size=$(du -sh "$backup_file" | cut -f1)
        log "Backup created successfully: $backup_file (Size: $size)"
    else
        log "ERROR: Backup file was NOT created: $backup_file"
        return 1
    fi

    # ----------------------------
    # Verify backup integrity
    # ----------------------------
    log "--- Verifying backup integrity for $server_name ---"
    {
        echo ""
        echo "  BACKUP INTEGRITY VERIFICATION"
        echo "  File   : $backup_file"
        echo "  Date   : $(date)"
        echo "  Server : $server_name"
        echo "  Size   : $size"
        echo ""
        echo "  Contents:"
        echo "  -----------------------------------------------"
        sudo tar -tzvf "$backup_file" 2>/dev/null | head -50
        echo "  -----------------------------------------------"
        echo ""
    } | tee -a "$LOG_FILE"

    # Verify tar exit code
    if sudo tar -tzf "$backup_file" &>/dev/null; then
        log "Integrity check PASSED: $backup_file is valid."
    else
        log "ERROR: Integrity check FAILED for $backup_file"
        return 1
    fi

    log "====== $server_name backup completed ======"
    return 0
}

# ----------------------------
# Setup backup directory
# ----------------------------
sudo mkdir -p "$BACKUP_DIR"
sudo chmod 750 "$BACKUP_DIR"
log "Backup directory ready: $BACKUP_DIR"

# ----------------------------
# Run backups
# ----------------------------
backup_server "apache" "$APACHE_CONF_DIR" "$APACHE_DOCROOT" "$APACHE_BACKUP_FILE"
backup_server "nginx"  "$NGINX_CONF_DIR"  "$NGINX_DOCROOT"  "$NGINX_BACKUP_FILE"

# ----------------------------
# List all backups
# ----------------------------
log "====== Current backups in $BACKUP_DIR ======"
ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tee -a "$LOG_FILE"

# ----------------------------
# Final summary
# ----------------------------
echo ""
echo "============================================================"
echo "  BACKUP SUMMARY - $(date)"
echo "============================================================"
echo "  Apache backup : $APACHE_BACKUP_FILE"
echo "  Nginx  backup : $NGINX_BACKUP_FILE"
echo "  Log file      : $LOG_FILE"
echo "============================================================"

log "====== Task 3 - Backup Configuration Complete ======"


# =============================================================================
# CRON JOB SETUP
# Run this section ONCE to install cron jobs for Sarah and Mike.
# Each cron job runs every Tuesday at 12:00 AM.
# =============================================================================
setup_cron() {
    local username=$1
    local server_type=$2   # "apache" or "nginx"
    local script_path
    script_path=$(realpath "$0")

    local cron_comment="# $server_type backup for $username (TechCorp DevOps)"
    local cron_line="0 0 * * 2 /bin/bash $script_path >> $BACKUP_DIR/${username}_cron.log 2>&1"

    log "Setting up cron job for $username ($server_type)..."

    # Add cron job for the user (avoid duplicates)
    (sudo -u "$username" crontab -l 2>/dev/null | grep -v "task3_backup"; \
     echo "$cron_comment"; echo "$cron_line") | sudo -u "$username" crontab - 2>/dev/null || \
    (crontab -l 2>/dev/null | grep -v "task3_backup"; \
     echo "$cron_comment"; echo "$cron_line") | crontab -

    log "Cron job installed for $username: runs every Tuesday at 12:00 AM"
    log "Cron entry: $cron_line"
}

# Uncomment to install cron jobs:
# setup_cron "sarah" "apache"
# setup_cron "mike"  "nginx"

# To view installed cron jobs:
# sudo -u sarah crontab -l
# sudo -u mike  crontab -l
