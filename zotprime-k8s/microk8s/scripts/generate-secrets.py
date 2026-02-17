#!/usr/bin/env python3

import os
import sys
import subprocess
import base64
import yaml
from pathlib import Path

def run_cmd(cmd):
    """Execute shell command and return output"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
    return result.stdout.strip()

def gen_hex(length):
    """Generate random hex string"""
    return run_cmd(f"openssl rand -hex {length}")

def gen_b64(length):
    """Generate random hex and base64 encode"""
    hex_val = gen_hex(length)
    return base64.b64encode(hex_val.encode()).decode()

def b64(text):
    """Base64 encode a string"""
    return base64.b64encode(text.encode()).decode()

def gen_bcrypt(password):
    """Generate bcrypt hash"""
    return run_cmd(f"php -r \"echo password_hash('{password}', PASSWORD_BCRYPT, ['cost' => 12]);\"")

def gen_bcrypt_b64(password):
    """Generate bcrypt hash and base64 encode"""
    return b64(gen_bcrypt(password))

def gen_laravel_key():
    """Generate Laravel app key in base64:XXX format"""
    return run_cmd("php -r \"echo 'base64:' . base64_encode(random_bytes(32));\"")

def check_dependencies():
    """Check required commands are available"""
    deps = ['openssl', 'php']
    missing = []
    for dep in deps:
        if subprocess.run(['which', dep], capture_output=True).returncode != 0:
            missing.append(dep)
    
    if missing:
        print(f"Error: Missing required commands: {', '.join(missing)}")
        if 'php' in missing:
            print("Install with: sudo apt install php-cli")
        sys.exit(1)

def main():
    # Check dependencies
    check_dependencies()
    
    # Paths
    script_dir = Path(__file__).parent
    helm_chart_dir = script_dir.parent / "helm-chart"
    values_example = helm_chart_dir / "values-example.yaml"
    values_file = helm_chart_dir / "values.yaml"
    credentials_file = helm_chart_dir / "credentials.txt"
    
    if not values_example.exists():
        print(f"Error: {values_example} not found")
        sys.exit(1)
    
    # Check if values.yaml exists
    if values_file.exists():
        print("values.yaml already exists.")
        response = input("Regenerate secrets in existing values.yaml? (y/n): ")
        if response.lower() != 'y':
            print("Exiting without changes.")
            sys.exit(0)
    else:
        print("Creating values.yaml from values-example.yaml...")
        import shutil
        shutil.copy(values_example, values_file)
    
    print("\nGenerating secrets...")
    
    # Load YAML
    with open(values_file, 'r') as f:
        config = yaml.safe_load(f)
    
    # Generate plaintext credentials
    api_super_token = gen_hex(32)
    webadmin_user = "webadmin"
    webadmin_pass = gen_hex(12)
    minio_user = config['minioConfig']['minioRootUser']
    minio_password = gen_hex(16)
    mariadb_root_pass = gen_hex(16)
    mariadb_pass = gen_hex(16)
    admin_pass = gen_hex(12)
    
    # Generate and populate secrets
    # authSecret
    config['authSecret']['authSalt'] = gen_b64(16)
    config['authSecret']['apiSuperToken'] = b64(api_super_token)
    config['authSecret']['apiSuperTokenHash'] = gen_bcrypt_b64(api_super_token)
    config['authSecret']['appKey'] = b64(gen_laravel_key())
    
    # webAdminConfig
    config['webAdminConfig']['username'] = webadmin_user
    
    # webAdminSecret
    config['webAdminSecret']['password'] = gen_bcrypt_b64(webadmin_pass)
    
    # minioSecret
    config['minioSecret']['secretTxt'] = b64(f"MINIO_ROOT_PASSWORD={minio_password}")
    
    # blobSecret
    config['blobSecret']['awsAccessKeyId'] = b64(minio_user)
    config['blobSecret']['awsSecretAccessKey'] = b64(minio_password)
    
    # dbSecret
    config['dbSecret']['mariadbRootPassword'] = b64(mariadb_root_pass)
    config['dbSecret']['mariadbPassword'] = b64(mariadb_pass)
    
    # zoteroSecret
    config['zoteroSecret']['adminPassword'] = b64(admin_pass)
    
    # webPortalSecret
    if 'webPortalSecret' in config:
        config['webPortalSecret']['sessionSecret'] = gen_hex(32)
    
    # Write back to file
    with open(values_file, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)
    
    # Save plaintext credentials
    with open(credentials_file, 'w') as f:
        f.write("=" * 50 + "\n")
        f.write("  ZotPrime Credentials\n")
        f.write("=" * 50 + "\n\n")
        
        f.write("Zotero Client:\n")
        f.write(f"  Username: {config['zoteroConfig']['adminUsername']}\n")
        f.write(f"  Password: {admin_pass}\n\n")
        
        f.write("Web Admin Panel:\n")
        f.write(f"  Username: {webadmin_user}\n")
        f.write(f"  Password: {webadmin_pass}\n\n")
        
        f.write("MinIO Web UI:\n")
        f.write(f"  Username: {minio_user}\n")
        f.write(f"  Password: {minio_password}\n\n")
        
        f.write("PHPMyAdmin:\n")
        f.write(f"  Username: root\n")
        f.write(f"  Password: {mariadb_root_pass}\n\n")
        
        f.write("API Super Token (for admin operations):\n")
        f.write(f"  Token: {api_super_token}\n\n")
        
        f.write("=" * 50 + "\n")
        f.write("IMPORTANT: Keep this file secure and do not commit to git!\n")
        f.write("=" * 50 + "\n")
    
    print(f"\n✓ Secrets generated and saved to {values_file}")
    print(f"✓ Plaintext credentials saved to {credentials_file}")
    print("\n⚠️  IMPORTANT: Keep credentials.txt secure!")
    print("\nNext steps:")
    print(f"1. Edit {values_file} to configure:")
    print("   - ingressHostnames")
    print("   - Storage sizes")
    print("   - Resource limits")
    print("2. Deploy: helm install zotprime-k8s helm-chart --namespace zotprime")

if __name__ == "__main__":
    main()
