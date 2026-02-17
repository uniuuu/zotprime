#!/usr/bin/env python3
"""Cleanup Kopia backup setup for ZotPrime MicroK8s."""

import subprocess
import os

def run_cmd(cmd):
    """Run shell command, ignore errors."""
    subprocess.run(cmd, shell=True, stderr=subprocess.DEVNULL)

def main():
    """Cleanup function."""
    print("=== Cleaning up Kopia Backup ===\n")
    
    # Stop and disable services
    print("Stopping services...")
    run_cmd("systemctl stop kopia-backup.timer")
    run_cmd("systemctl stop kopia-backup.service")
    run_cmd("systemctl stop kopia-ui.service")
    
    run_cmd("systemctl disable kopia-backup.timer")
    run_cmd("systemctl disable kopia-ui.service")
    
    # Remove systemd files
    print("Removing systemd files...")
    run_cmd("rm -f /etc/systemd/system/kopia-backup.service")
    run_cmd("rm -f /etc/systemd/system/kopia-backup.timer")
    run_cmd("rm -f /etc/systemd/system/kopia-ui.service")
    
    run_cmd("systemctl daemon-reload")
    
    print("✓ Cleanup complete!")
    print("\nNote: Kopia repository and backups are preserved.")
    print("To disconnect repository: kopia repository disconnect")
    print("To delete backups: manually delete remote storage")

if __name__ == "__main__":
    main()
