# TechCorp Development Environment Setup

**Organization:** TechCorp
**Role:** Fresher DevOps Engineer (Assisting Rahul – Senior DevOps Engineer)
**Developers Onboarded:** Sarah & Mike

---

## Overview

This repository contains the implementation of a secure, monitored, and well-maintained development environment for two new developers at TechCorp. The assignment is divided into three tasks covering system monitoring, user management, and automated backups.

---

## Task 1 – System Monitoring Setup (`task1_monitoring.sh`)

Installs and configures monitoring tools to track server health and performance.

**What it does:**
- Installs `htop`, `nmon`, and `sysstat`
- Captures CPU, memory, disk usage (`df`, `du`), and process snapshots
- Saves timestamped reports to `/var/log/sysmonitor/`
- Sets up an **hourly cron job** for automated metric logging

**Run it:**
```bash
sudo bash task1_monitoring.sh
```

---

## Task 2 – User Management and Access Control (`task2_user_management.sh`)

Creates isolated user accounts for Sarah and Mike with strict security policies.

**What it does:**
- Creates user accounts: `sarah` and `mike`
- Sets up dedicated workspaces with `chmod 700` (owner-only access):
  - `/home/sarah/workspace`
  - `/home/mike/workspace`
- Configures PAM password complexity (min 12 chars, upper/lower/digit/special)
- Enforces 30-day password expiry via `chage`
- Forces password change on first login

**Run it:**
```bash
sudo bash task2_user_management.sh
```

---

## Task 3 – Backup Configuration for Web Servers (`task3_backup.sh`)

Automates weekly compressed backups for Apache (Sarah) and Nginx (Mike).

**What it does:**
- Backs up Apache config (`/etc/httpd/`) and document root (`/var/www/html/`)
- Backs up Nginx config (`/etc/nginx/`) and document root (`/usr/share/nginx/html/`)
- Saves backups to `/backups/` with date-stamped filenames:
  - `apache_backup_YYYY-MM-DD.tar.gz`
  - `nginx_backup_YYYY-MM-DD.tar.gz`
- Verifies backup integrity using `tar -tzvf`
- Logs all output to `/backups/backup_verification.log`
- Includes cron job setup to run **every Tuesday at 12:00 AM**

**Run it:**
```bash
sudo bash task3_backup.sh
```

**Cron schedule:**
```
0 0 * * 2  /bin/bash /path/to/task3_backup.sh
```

---

## Report

The full implementation report is available in [`DevOps_Assignment_Report.docx`](./DevOps_Assignment_Report.docx), covering:
- Step-by-step implementation for all three tasks
- Sample terminal outputs
- Password policy summary
- Backup verification logs
- Challenges encountered and how they were resolved

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| htop / nmon | Interactive process & resource monitoring |
| sysstat | Historical performance data |
| df / du | Disk usage tracking |
| useradd / chage | User management & password policy |
| PAM pwquality | Password complexity enforcement |
| tar / cron | Automated compressed backups |
| bash | Scripting language for all automation |

---

## Repository Structure

```
SDevops/
├── task1_monitoring.sh          # System monitoring setup
├── task2_user_management.sh     # User management & access control
├── task3_backup.sh              # Backup configuration for web servers
├── DevOps_Assignment_Report.docx # Full implementation report
└── README.md                    # This file
```
