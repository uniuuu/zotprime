#!/usr/bin/env python3
"""Pulumi program to deploy Kopia backup solution for ZotPrime MicroK8s."""

import pulumi
import pulumi_command as command
import os
import yaml
import base64

config = pulumi.Config()

# Required configuration
backend = config.require("backend")
namespace = config.require("namespace")
backup_time = config.require("backupTime")
enable_ui = config.require_bool("enableUI")
ui_port = config.require("uiPort")
minio_data_path = config.require("minioDataPath")
db_pod_name = config.require("dbPodName")
repo_password = config.require_secret("repoPassword")

# Retention policy - either keepLatest OR granular settings
keep_latest = config.get("keepLatest")
keep_daily = config.get("keepDaily")
keep_weekly = config.get("keepWeekly")
keep_monthly = config.get("keepMonthly")
keep_yearly = config.get("keepYearly")

if not keep_latest and not (keep_daily or keep_weekly or keep_monthly or keep_yearly):
    raise Exception("Must set either keepLatest OR at least one of keepDaily/keepWeekly/keepMonthly/keepYearly")

# Paths
script_dir = os.path.dirname(os.path.abspath(__file__))
config_dir = os.path.join(script_dir, "config")
values_yaml_path = os.path.join(script_dir, "../helm-chart/values.yaml")

# Read secrets from values.yaml
with open(values_yaml_path, 'r') as f:
    values = yaml.safe_load(f)

# Decode base64 secrets
mariadb_root_password = base64.b64decode(values['dbSecret']['mariadbRootPassword']).decode('utf-8')

# Backend-specific required config
env = {
    "BACKEND": backend,
    "NAMESPACE": namespace,
    "BACKUP_TIME": backup_time,
    "ENABLE_UI": str(enable_ui).lower(),
    "UI_PORT": ui_port,
    "CONFIG_DIR": config_dir,
    "SCRIPT_DIR": script_dir,
    "REPO_PASSWORD": repo_password,
    "MARIADB_ROOT_PASSWORD": mariadb_root_password,
    "MINIO_DATA_PATH": minio_data_path,
    "DB_POD_NAME": db_pod_name,
}

# Add retention settings
if keep_latest:
    env["KEEP_LATEST"] = keep_latest
if keep_daily:
    env["KEEP_DAILY"] = keep_daily
if keep_weekly:
    env["KEEP_WEEKLY"] = keep_weekly
if keep_monthly:
    env["KEEP_MONTHLY"] = keep_monthly
if keep_yearly:
    env["KEEP_YEARLY"] = keep_yearly

# Backend-specific config
if backend == "s3":
    env.update({
        "S3_BUCKET": config.require("s3Bucket"),
        "S3_ENDPOINT": config.require("s3Endpoint"),
        "S3_ACCESS_KEY": config.require("s3AccessKey"),
        "S3_SECRET_KEY": config.require_secret("s3SecretKey"),
    })
elif backend == "sftp":
    env.update({
        "SFTP_HOST": config.require("sftpHost"),
        "SFTP_PATH": config.require("sftpPath"),
        "SFTP_USERNAME": config.require("sftpUsername"),
        "SFTP_KEYFILE": config.require("sftpKeyFile"),
    })
elif backend == "filesystem":
    env.update({
        "FILESYSTEM_PATH": config.require("filesystemPath"),
    })
else:
    raise ValueError(f"Invalid backend: {backend}. Must be 's3', 'sftp', or 'filesystem'")

# UI config if enabled
if enable_ui:
    env.update({
        "UI_USERNAME": config.require("uiUsername"),
        "UI_PASSWORD": config.require_secret("uiPassword"),
    })

# Check Kopia installation
check_kopia = command.local.Command(
    "check-kopia",
    create="which kopia || (echo 'ERROR: Kopia not installed. Please install Kopia first.' && exit 1)",
)

# Run setup script
setup = command.local.Command(
    "setup-kopia",
    create=f"python3 {script_dir}/setup-kopia.py",
    delete=f"python3 {script_dir}/cleanup-kopia.py",
    environment=env,
    opts=pulumi.ResourceOptions(depends_on=[check_kopia]),
)

# Export outputs
pulumi.export("status", setup.stdout)
pulumi.export("backup_schedule", backup_time)
pulumi.export("kopia_ui_enabled", enable_ui)
if enable_ui:
    pulumi.export("kopia_ui_url", f"http://localhost:{ui_port}")
