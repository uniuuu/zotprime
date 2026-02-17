#!/usr/bin/env python3
"""Run Kopia backup for ZotPrime."""

import subprocess
import sys
import os
from datetime import datetime

def run_cmd(cmd, check=True):
    """Run shell command."""
    result = subprocess.run(cmd, shell=True)
    if check and result.returncode != 0:
        print(f"ERROR: Command failed: {cmd}", file=sys.stderr)
        sys.exit(1)
    return result.returncode

def backup_database():
    """Backup MariaDB databases."""
    namespace = os.environ["NAMESPACE"]
    password = os.environ["MARIADB_ROOT_PASSWORD"]
    
    print(f"[{datetime.now()}] Backing up MariaDB databases...")
    
    cmd = f"""kubectl exec -n {namespace} mariadb-0 -- \
        mysqldump -u root -p'{password}' --all-databases --single-transaction --quick \
        | kopia snapshot create --stdin \
        --stdin-filename=zotprime-databases.sql \
        --tags=component:database,app:zotprime"""
    
    if run_cmd(cmd) == 0:
        print("✓ Database backup complete")
    else:
        print("✗ Database backup failed", file=sys.stderr)
        return False
    
    return True

def backup_s3():
    """Backup MinIO S3 data."""
    minio_path = os.environ["MINIO_DATA_PATH"]
    
    if not os.path.exists(minio_path):
        print(f"WARNING: MinIO data path not found: {minio_path}", file=sys.stderr)
        return True
    
    print(f"[{datetime.now()}] Backing up MinIO S3 data...")
    
    cmd = f"""kopia snapshot create {minio_path} \
        --tags=component:s3,app:zotprime"""
    
    if run_cmd(cmd) == 0:
        print("✓ S3 backup complete")
    else:
        print("✗ S3 backup failed", file=sys.stderr)
        return False
    
    return True

def maintenance():
    """Run Kopia maintenance."""
    print(f"[{datetime.now()}] Running maintenance...")
    
    # Quick maintenance (not full)
    cmd = "kopia maintenance run --safety=none"
    run_cmd(cmd, check=False)
    
    print("✓ Maintenance complete")

def main():
    """Main backup function."""
    print(f"=== Kopia Backup Started at {datetime.now()} ===\n")
    
    success = True
    
    if not backup_database():
        success = False
    
    if not backup_s3():
        success = False
    
    maintenance()
    
    if success:
        print(f"\n✓ Backup completed successfully at {datetime.now()}")
        sys.exit(0)
    else:
        print(f"\n✗ Backup completed with errors at {datetime.now()}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
