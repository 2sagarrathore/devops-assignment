#!/bin/bash
# =============================================================================
# Task 2: User Management and Access Control
# Author: Fresher DevOps Engineer (Assisting Rahul, Senior DevOps - TechCorp)
# Description: Creates user accounts for Sarah and Mike, sets up isolated
#              workspaces with strict permissions, and enforces password policy.
# =============================================================================

# ----------------------------
# Configuration
# ----------------------------
SARAH_USER="sarah"
MIKE_USER="mike"

SARAH_DIR="/home/sarah/workspace"
MIKE_DIR="/home/mike/workspace"

# Passwords (in production, use a secure vault or prompt)
# Format: hashed via openssl or use passwd interactively
SARAH_PASS="Sarah@Secure#2024"
MIKE_PASS="Mike@Secure#2024"

PASSWORD_MAX_DAYS=30
PASSWORD_MIN_DAYS=1
PASSWORD_WARN_DAYS=7

LOG_FILE="/var/log/user_management.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
}

# ----------------------------
# 1. Install PAM password quality enforcement
# ----------------------------
log "Installing password complexity tools..."
if command -v apt-get &>/dev/null; then
    sudo apt-get install -y libpam-pwquality 2>/dev/null || true
elif command -v yum &>/dev/null; then
    sudo yum install -y libpwquality 2>/dev/null || true
fi

# Configure PAM password complexity (if pwquality.conf exists)
if [ -f /etc/security/pwquality.conf ]; then
    log "Configuring password complexity policy..."
    sudo bash -c 'cat > /etc/security/pwquality.conf <<EOF
# Minimum password length
minlen = 12
# Require at least 1 uppercase
ucredit = -1
# Require at least 1 lowercase
lcredit = -1
# Require at least 1 digit
dcredit = -1
# Require at least 1 special character
ocredit = -1
# Reject passwords that contain the username
usercheck = 1
EOF'
    log "Password complexity policy configured."
fi

# ----------------------------
# 2. Create user accounts
# ----------------------------
create_user() {
    local username=$1
    local password=$2
    local workspace=$3

    if id "$username" &>/dev/null; then
        log "User '$username' already exists. Skipping creation."
    else
        log "Creating user: $username"
        sudo useradd -m -s /bin/bash "$username"
        echo "$username:$password" | sudo chpasswd
        log "User '$username' created successfully."
    fi

    # ----------------------------
    # 3. Set up isolated workspace directory
    # ----------------------------
    log "Setting up workspace for $username: $workspace"
    sudo mkdir -p "$workspace"
    sudo chown "$username":"$username" "$workspace"
    # Only the owner can read/write/execute; group and others have NO access
    sudo chmod 700 "$workspace"
    log "Workspace $workspace created with permissions 700 (owner-only)."

    # ----------------------------
    # 4. Enforce password policy (expiry)
    # ----------------------------
    log "Applying password policy for $username..."
    sudo chage -M "$PASSWORD_MAX_DAYS" \
               -m "$PASSWORD_MIN_DAYS" \
               -W "$PASSWORD_WARN_DAYS" \
               "$username"
    log "Password policy applied: max_days=$PASSWORD_MAX_DAYS, warn_days=$PASSWORD_WARN_DAYS"

    # Force password change on first login
    sudo chage -d 0 "$username"
    log "User $username must change password on first login."
}

# ----------------------------
# Run for Sarah and Mike
# ----------------------------
log "====== Starting User Management Setup ======"

create_user "$SARAH_USER" "$SARAH_PASS" "$SARAH_DIR"
create_user "$MIKE_USER"  "$MIKE_PASS"  "$MIKE_DIR"

# ----------------------------
# 5. Verify setup
# ----------------------------
log "====== Verification ======"
log "--- User info for Sarah ---"
sudo id sarah 2>/dev/null | sudo tee -a "$LOG_FILE"
sudo ls -ld "$SARAH_DIR" 2>/dev/null | sudo tee -a "$LOG_FILE"
sudo chage -l sarah 2>/dev/null | sudo tee -a "$LOG_FILE"

log "--- User info for Mike ---"
sudo id mike 2>/dev/null | sudo tee -a "$LOG_FILE"
sudo ls -ld "$MIKE_DIR" 2>/dev/null | sudo tee -a "$LOG_FILE"
sudo chage -l mike 2>/dev/null | sudo tee -a "$LOG_FILE"

# ----------------------------
# 6. Print summary
# ----------------------------
echo ""
echo "============================================================"
echo "  USER MANAGEMENT SUMMARY"
echo "============================================================"
echo "Users created  : sarah, mike"
echo "Sarah workspace: $SARAH_DIR (chmod 700)"
echo "Mike workspace : $MIKE_DIR (chmod 700)"
echo "Password policy:"
echo "  - Max age : $PASSWORD_MAX_DAYS days"
echo "  - Min age : $PASSWORD_MIN_DAYS day"
echo "  - Warning : $PASSWORD_WARN_DAYS days before expiry"
echo "  - Complexity: min 12 chars, upper+lower+digit+special"
echo "  - First login: forced password change"
echo "Log file       : $LOG_FILE"
echo "============================================================"

log "====== Task 2 - User Management Setup Complete ======"
