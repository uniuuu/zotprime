#!/usr/bin/env python3
"""Setup Kopia backup for ZotPrime MicroK8s."""

import os
import sys
import subprocess
import shutil

def run_cmd(cmd, check=True, capture=False):
    """Run shell command."""
    if capture:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if check and result.returncode != 0:
            print(f"ERROR: {result.stderr}", file=sys.stderr)
            sys.exit(1)
        return result.stdout.strip()
    else:
        result = subprocess.run(cmd, shell=True)
        if check and result.returncode != 0:
            sys.exit(1)

def check_kopia():
    """Check if Kopia is installed."""
    result = subprocess.run("which kopia", shell=True, capture_output=True)
    if result.returncode != 0:
        print("ERROR: Kopia not installed. Please install Kopia first.", file=sys.stderr)
        print("See: https://kopia.io/docs/installation/", file=sys.stderr)
        sys.exit(1)
    
    version = run_cmd("kopia --version", capture=True)
    print(f"✓ Kopia installed: {version}")

def init_repository():
    """Initialize Kopia repository (idempotent)."""
    backend = os.environ["BACKEND"]
    repo_password = os.environ["REPO_PASSWORD"]
    
    # Check if already connected
    result = subprocess.run("kopia repository status", shell=True, capture_output=True, stderr=subprocess.DEVNULL)
    if result.returncode == 0:
        print("✓ Kopia repository already connected")
        return
    
    print(f"Initializing Kopia repository (backend: {backend})...")
    
    env = os.environ.copy()
    env["KOPIA_PASSWORD"] = repo_password
    
    if backend == "s3":
        cmd = f"""kopia repository create s3 \
            --bucket={os.environ['S3_BUCKET']} \
            --endpoint={os.environ['S3_ENDPOINT']} \
            --access-key={os.environ['S3_ACCESS_KEY']} \
            --secret-access-key={os.environ['S3_SECRET_KEY']}"""
    elif backend == "sftp":
        cmd = f"""kopia repository create sftp \
            --path={os.environ['SFTP_PATH']} \
            --host={os.environ['SFTP_HOST']} \
            --username={os.environ['SFTP_USERNAME']} \
            --keyfile={os.environ['SFTP_KEYFILE']}"""
    elif backend == "filesystem":
        path = os.environ['FILESYSTEM_PATH']
        os.makedirs(path, exist_ok=True)
        cmd = f"kopia repository create filesystem --path={path}"
    else:
        print(f"ERROR: Invalid backend: {backend}", file=sys.stderr)
        sys.exit(1)
    
    result = subprocess.run(cmd, shell=True, env=env, capture_output=True, text=True)
    if result.returncode != 0:
        # Check if already exists
        if "already exists" in result.stderr.lower() or "already connected" in result.stderr.lower():
            print("✓ Kopia repository already exists, connecting...")
            connect_cmd = cmd.replace("create", "connect")
            result = subprocess.run(connect_cmd, shell=True, env=env)
            if result.returncode != 0:
                print("ERROR: Failed to connect to Kopia repository", file=sys.stderr)
                sys.exit(1)
        else:
            print(f"ERROR: Failed to initialize Kopia repository: {result.stderr}", file=sys.stderr)
            sys.exit(1)
    
    print("✓ Kopia repository initialized")

def set_policy():
    """Set Kopia retention policy (idempotent)."""
    print("Setting retention policy...")
    
    cmd = f"""kopia policy set --global \
        --keep-daily={os.environ['KEEP_DAILY']} \
        --keep-weekly={os.environ['KEEP_WEEKLY']} \
        --keep-monthly={os.environ['KEEP_MONTHLY']} \
        --keep-yearly={os.environ['KEEP_YEARLY']} \
        --compression=zstd \
        --keep-latest=3"""
    
    run_cmd(cmd)
    print("✓ Retention policy set")

def create_systemd_files():
    """Create systemd service and timer files (idempotent)."""
    config_dir = os.environ["CONFIG_DIR"]
    script_dir = os.environ["SCRIPT_DIR"]
    backup_time = os.environ["BACKUP_TIME"]
    
    os.makedirs(config_dir, exist_ok=True)
    
    # Create backup service
    service_content = f"""[Unit]
Description=Kopia Backup for ZotPrime
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 {script_dir}/run-backup.py
Environment="NAMESPACE={os.environ['NAMESPACE']}"
Environment="MARIADB_ROOT_PASSWORD={os.environ['MARIADB_ROOT_PASSWORD']}"
Environment="MINIO_DATA_PATH={os.environ['MINIO_DATA_PATH']}"
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
"""
    
    service_path = f"{config_dir}/kopia-backup.service"
    with open(service_path, 'w') as f:
        f.write(service_content)
    
    # Create backup timer
    timer_content = f"""[Unit]
Description=Kopia Backup Timer for ZotPrime
Requires=kopia-backup.service

[Timer]
OnCalendar=*-*-* {backup_time}:00
Persistent=true

[Install]
WantedBy=timers.target
"""
    
    timer_path = f"{config_dir}/kopia-backup.timer"
    with open(timer_path, 'w') as f:
        f.write(timer_content)
    
    # Copy to systemd directory
    shutil.copy(service_path, "/etc/systemd/system/kopia-backup.service")
    shutil.copy(timer_path, "/etc/systemd/system/kopia-backup.timer")
    
    print("✓ Systemd files created")

def create_ui_service():
    """Create Kopia UI systemd service (idempotent)."""
    if os.environ["ENABLE_UI"] != "true":
        return
    
    config_dir = os.environ["CONFIG_DIR"]
    ui_port = os.environ["UI_PORT"]
    ui_username = os.environ["UI_USERNAME"]
    ui_password = os.environ["UI_PASSWORD"]
    
    service_content = f"""[Unit]
Description=Kopia UI Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/kopia server start \
    --address=0.0.0.0:{ui_port} \
    --server-username={ui_username} \
    --server-password={ui_password}
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
"""
    
    service_path = f"{config_dir}/kopia-ui.service"
    with open(service_path, 'w') as f:
        f.write(service_content)
    
    shutil.copy(service_path, "/etc/systemd/system/kopia-ui.service")
    print("✓ Kopia UI service created")

def enable_services():
    """Enable and start systemd services (idempotent)."""
    run_cmd("systemctl daemon-reload")
    
    # Stop first to ensure clean state
    subprocess.run("systemctl stop kopia-backup.timer", shell=True, stderr=subprocess.DEVNULL)
    
    run_cmd("systemctl enable kopia-backup.timer")
    run_cmd("systemctl start kopia-backup.timer")
    print("✓ Backup timer enabled and started")
    
    if os.environ["ENABLE_UI"] == "true":
        subprocess.run("systemctl stop kopia-ui.service", shell=True, stderr=subprocess.DEVNULL)
        run_cmd("systemctl enable kopia-ui.service")
        run_cmd("systemctl start kopia-ui.service")
        print("✓ Kopia UI service enabled and started")

def main():
    """Main setup function."""
    print("=== Kopia Backup Setup for ZotPrime ===\n")
    
    check_kopia()
    init_repository()
    set_policy()
    create_systemd_files()
    create_ui_service()
    enable_services()
    
    print("\n✓ Setup complete!")
    print(f"\nBackup schedule: Daily at {os.environ['BACKUP_TIME']}")
    print("Check status: systemctl status kopia-backup.timer")
    print("View logs: journalctl -u kopia-backup.service -f")
    
    if os.environ["ENABLE_UI"] == "true":
        print(f"\nKopia UI: http://localhost:{os.environ['UI_PORT']}")

if __name__ == "__main__":
    main()
