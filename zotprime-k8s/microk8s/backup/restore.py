#!/usr/bin/env python3
"""Restore ZotPrime from Kopia backup."""

import subprocess
import sys
import argparse
from datetime import datetime

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
        return result.returncode

def list_snapshots(component=None):
    """List available snapshots."""
    cmd = "kopia snapshot list"
    if component:
        cmd += f" --tags=component:{component}"
    
    output = run_cmd(cmd, capture=True)
    return output

def get_latest_snapshot(component):
    """Get latest snapshot ID for component."""
    cmd = f"kopia snapshot list --tags=component:{component} --json"
    output = run_cmd(cmd, capture=True)
    
    if not output:
        print(f"ERROR: No snapshots found for component: {component}", file=sys.stderr)
        sys.exit(1)
    
    import json
    snapshots = json.loads(output)
    if not snapshots:
        print(f"ERROR: No snapshots found for component: {component}", file=sys.stderr)
        sys.exit(1)
    
    # Get most recent
    latest = sorted(snapshots, key=lambda x: x['startTime'], reverse=True)[0]
    return latest['id']

def restore_database(snapshot_id, namespace, dry_run=False, db_pod="zotprime-k8s-zotprime-db-0"):
    """Restore MariaDB databases."""
    print(f"[{datetime.now()}] Restoring MariaDB databases...")
    
    if dry_run:
        print(f"DRY RUN: Would restore database from snapshot {snapshot_id}")
        return True
    
    password = os.environ["MARIADB_ROOT_PASSWORD"]
    
    # Scale down dataserver to prevent writes
    print("Scaling down dataserver...")
    run_cmd(f"kubectl scale -n {namespace} deployment/zotprime-k8s-zotprime-dataserver --replicas=0")
    
    # Restore database
    cmd = f"""kopia snapshot restore {snapshot_id} - \
        | kubectl exec -i -n {namespace} {db_pod} -- \
        mysql -u root -p'{password}'"""
    
    if run_cmd(cmd, check=False) == 0:
        print("✓ Database restore complete")
        success = True
    else:
        print("✗ Database restore failed", file=sys.stderr)
        success = False
    
    # Scale back up
    print("Scaling up dataserver...")
    run_cmd(f"kubectl scale -n {namespace} deployment/zotprime-dataserver --replicas=1")
    
    return success

def restore_s3(snapshot_id, minio_path, namespace, dry_run=False):
    """Restore MinIO S3 data."""
    print(f"[{datetime.now()}] Restoring MinIO S3 data...")
    
    if dry_run:
        print(f"DRY RUN: Would restore S3 data from snapshot {snapshot_id} to {minio_path}")
        return True
    
    # Scale down minio to prevent writes
    print("Scaling down MinIO...")
    run_cmd(f"kubectl scale -n {namespace} deployment/zotprime-k8s-zotprime-minio --replicas=0")
    
    # Restore S3 data
    cmd = f"kopia snapshot restore {snapshot_id} {minio_path}"
    
    if run_cmd(cmd, check=False) == 0:
        print("✓ S3 restore complete")
        success = True
    else:
        print("✗ S3 restore failed", file=sys.stderr)
        success = False
    
    # Scale back up
    print("Scaling up MinIO...")
    run_cmd(f"kubectl scale -n {namespace} deployment/zotprime-k8s-zotprime-minio --replicas=1")
    
    return success

def main():
    """Main restore function."""
    parser = argparse.ArgumentParser(description='Restore ZotPrime from Kopia backup')
    parser.add_argument('--db', action='store_true', help='Restore database only')
    parser.add_argument('--s3', action='store_true', help='Restore S3 data only')
    parser.add_argument('--all', action='store_true', help='Restore everything')
    parser.add_argument('--snapshot-id', help='Specific snapshot ID to restore')
    parser.add_argument('--dry-run', action='store_true', help='Preview only, no actual restore')
    parser.add_argument('--namespace', default='zotprime', help='Kubernetes namespace')
    parser.add_argument('--minio-path', default='/mnt/nfs/dataminio', help='MinIO data path on host')
    parser.add_argument('--db-pod', default='zotprime-k8s-zotprime-db-0', help='MariaDB pod name')
    
    args = parser.parse_args()
    
    if not (args.db or args.s3 or args.all):
        parser.error('Must specify --db, --s3, or --all')
    
    print(f"=== Kopia Restore Started at {datetime.now()} ===\n")
    
    if args.dry_run:
        print("DRY RUN MODE - No changes will be made\n")
    
    success = True
    
    # Restore database
    if args.db or args.all:
        if args.snapshot_id:
            db_snapshot = args.snapshot_id
        else:
            print("Finding latest database snapshot...")
            db_snapshot = get_latest_snapshot('database')
        
        print(f"Database snapshot: {db_snapshot}")
        if not restore_database(db_snapshot, args.namespace, args.dry_run, args.db_pod):
            success = False
    
    # Restore S3
    if args.s3 or args.all:
        if args.snapshot_id:
            s3_snapshot = args.snapshot_id
        else:
            print("Finding latest S3 snapshot...")
            s3_snapshot = get_latest_snapshot('s3')
        
        print(f"S3 snapshot: {s3_snapshot}")
        if not restore_s3(s3_snapshot, args.minio_path, args.namespace, args.dry_run):
            success = False
    
    if success:
        print(f"\n✓ Restore completed successfully at {datetime.now()}")
        sys.exit(0)
    else:
        print(f"\n✗ Restore completed with errors at {datetime.now()}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
