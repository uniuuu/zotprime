#!/usr/bin/env python3
"""ZotPrime Admin Tool - Manage users and groups via REST API"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import Optional
import xml.etree.ElementTree as ET

try:
    import requests
except ImportError:
    print("ERROR: requests library not found. Install with: pip install requests", file=sys.stderr)
    sys.exit(1)

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_DIR = SCRIPT_DIR.parent

def load_env():
    """Load .env file if it exists"""
    env_file = PROJECT_DIR / ".env"
    if env_file.exists():
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, _, value = line.partition('=')
                    os.environ[key.strip()] = value.strip().strip("'\"")

def check_env():
    """Validate required environment variables"""
    if not os.getenv('API_SUPER_TOKEN'):
        print("ERROR: API_SUPER_TOKEN not set", file=sys.stderr)
        sys.exit(1)

def print_usage():
    """Print usage information"""
    print("""ZotPrime Admin Tool

Usage: admin.py [--host <url>] <resource> <action> [args...]

Options:
  --host <url>    Dataserver URL (default: http://127.0.0.1:8080)

Resources and Actions:
  user create <username> <email> <password>   Create a new user
  user list                                   List all users
  user disable <username>                     Disable a user
  user enable <username>                      Enable a user
  user quota <user_id>                        Show user storage quota
  user set-quota <user_id> <quota_mb>         Set user storage quota (in MB)

  group create <owner_id> <name> <type>       Create a group (type: PublicOpen|PublicClosed|Private)
  group list                                  List all groups
  group delete <group_id>                     Delete a group
  group add-user <group_id> <user_id> [role]  Add user to group (role: admin|member, default: member)
  group remove-user <group_id> <user_id>      Remove user from group
  group members <group_id>                    List group members

Examples:
  admin.py user create alice alice@example.com secret123
  admin.py user list
  admin.py group create 1 "My Group" PublicOpen
  admin.py group add-user 123 456 admin

Environment Variables (required):
  SERVER_IP           Server IP address (default: 127.0.0.1)
  API_SUPER_TOKEN     API super user token
""")

def api_call(method: str, endpoint: str, dshost: str, data: Optional[str] = None, content_type: str = 'text/xml') -> requests.Response:
    """Make API call using requests"""
    url = f"{dshost.rstrip('/')}/{endpoint}"
    headers = {'Authorization': f"Bearer {os.getenv('API_SUPER_TOKEN')}"}
    
    if data:
        headers['Content-Type'] = content_type
    
    try:
        response = requests.request(method, url, headers=headers, data=data, timeout=30)
        return response
    except requests.RequestException as e:
        print(f"ERROR: API request failed: {e}", file=sys.stderr)
        sys.exit(1)

def user_create(username: str, email: str, password: str, dshost: str):
    """Create a new user"""
    data = json.dumps({"username": username, "email": email, "password": password})
    response = api_call('POST', 'admin/users', dshost, data, 'application/json')
    
    if response.status_code == 201:
        result = response.json()
        print("User created successfully!")
        print(f"  UserID: {result['userID']}")
        print(f"  Username: {result['username']}")
        print(f"  Email: {result['email']}")
        print(f"  LibraryID: {result['libraryID']}")
    else:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def user_list(dshost: str):
    """List all users"""
    response = api_call('GET', 'admin/users', dshost)
    
    if response.status_code != 200:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)
    
    users = response.json()
    
    print(f"{'UserID':<6}  {'Username':<18}  {'Email':<26}  {'Status':<8}")
    print(f"{'------':<6}  {'------------------':<18}  {'--------------------------':<26}  {'--------':<8}")
    
    for user in users:
        status = "enabled" if user.get('enabled', True) else "disabled"
        print(f"{user['userID']:<6}  {user['username']:<18}  {user['email']:<26}  {status:<8}")

def get_user_id(username: str, dshost: str) -> Optional[int]:
    """Get user ID from username"""
    response = api_call('GET', 'admin/users', dshost)
    
    if response.status_code != 200:
        return None
    
    users = response.json()
    for user in users:
        if user['username'] == username:
            return user['userID']
    return None

def user_disable(username: str, dshost: str):
    """Disable a user"""
    user_id = get_user_id(username, dshost)
    if not user_id:
        print(f"ERROR: User '{username}' not found", file=sys.stderr)
        sys.exit(1)
    
    data = json.dumps({"enabled": False})
    response = api_call('PUT', f"admin/users/{user_id}/status", dshost, data, 'application/json')
    
    if response.status_code == 204:
        print(f"User '{username}' (ID: {user_id}) disabled")
    else:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def user_enable(username: str, dshost: str):
    """Enable a user"""
    user_id = get_user_id(username, dshost)
    if not user_id:
        print(f"ERROR: User '{username}' not found", file=sys.stderr)
        sys.exit(1)
    
    data = json.dumps({"enabled": True})
    response = api_call('PUT', f"admin/users/{user_id}/status", dshost, data, 'application/json')
    
    if response.status_code == 204:
        print(f"User '{username}' (ID: {user_id}) enabled")
    else:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def user_quota(user_id: int, dshost: str):
    """Show user storage quota"""
    response = api_call('GET', f"users/{user_id}/storageadmin", dshost)
    
    if response.status_code != 200:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)
    
    try:
        root = ET.fromstring(response.text)
        quota = root.find('.//quota')
        inst_quota = root.find('.//instQuota')
        usage = root.find('.//usage')
        
        print(f"User ID: {user_id}")
        print(f"  Quota: {quota.text if quota is not None else 'N/A'} MB")
        print(f"  Institutional Quota: {inst_quota.text if inst_quota is not None else 'N/A'} MB")
        print(f"  Usage: {usage.text if usage is not None else 'N/A'} MB")
    except ET.ParseError:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def user_set_quota(user_id: int, quota_mb: int, dshost: str):
    """Set user storage quota"""
    data = f"quota={quota_mb}&expiration=0"
    response = api_call('POST', f"users/{user_id}/storageadmin", dshost, data, 'application/x-www-form-urlencoded')
    
    if response.status_code == 200 and '<quota>' in response.text:
        print(f"Quota set successfully for user {user_id}")
        user_quota(user_id, dshost)
    else:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def group_create(owner_id: int, name: str, gtype: str, dshost: str):
    """Create a group"""
    valid_types = ['PublicOpen', 'PublicClosed', 'Private']
    if gtype not in valid_types:
        print(f"ERROR: Invalid group type '{gtype}'. Use: {', '.join(valid_types)}", file=sys.stderr)
        sys.exit(1)
    
    file_editing = "none" if gtype == "PublicOpen" else "members"
    xml = f'<group owner="{owner_id}" name="{name}" type="{gtype}" libraryEditing="members" libraryReading="all" fileEditing="{file_editing}"/>'
    
    response = api_call('POST', 'groups', dshost, xml)
    
    if response.status_code in [200, 201]:
        try:
            root = ET.fromstring(response.text)
            group_id = root.find('.//{http://zotero.org/ns/api}groupID')
            if group_id is not None:
                print("Group created successfully!")
                print(f"  ID: {group_id.text}")
                print(f"  Name: {name}")
                print(f"  Type: {gtype}")
                print(f"  Owner: {owner_id}")
            else:
                print("ERROR: Failed to create group. Check server logs for details.", file=sys.stderr)
                sys.exit(1)
        except ET.ParseError:
            print("ERROR: Failed to create group. Check server logs for details.", file=sys.stderr)
            sys.exit(1)
    else:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def group_list(dshost: str):
    """List all groups"""
    response = api_call('GET', 'admin/groups', dshost)
    
    if response.status_code != 200:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)
    
    groups = response.json()
    
    print(f"{'ID':<4} {'Name':<19} {'Type':<13} {'Owner':<6} {'LibraryID':<9}")
    print(f"{'----':<4} {'-------------------':<19} {'-------------':<13} {'------':<6} {'---------':<9}")
    
    for group in groups:
        print(f"{group['id']:<4} {group['name']:<19} {group['type']:<13} {group['owner']:<6} {group['libraryID']:<9}")

def group_delete(group_id: int, dshost: str):
    """Delete a group"""
    response = api_call('DELETE', f"groups/{group_id}", dshost)
    
    if response.status_code in [200, 204]:
        print(f"Group {group_id} deleted")
    else:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def group_add_user(group_id: int, user_id: int, role: str, dshost: str):
    """Add user to group"""
    if role not in ['admin', 'member']:
        print(f"ERROR: Invalid role '{role}'. Use: admin or member", file=sys.stderr)
        sys.exit(1)
    
    xml = f'<user id="{user_id}" role="{role}"/>'
    response = api_call('PUT', f"groups/{group_id}/users/{user_id}", dshost, xml)
    
    if response.status_code in [200, 204] or '<title>' in response.text:
        print(f"User {user_id} added to group {group_id} as {role}")
    else:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def group_remove_user(group_id: int, user_id: int, dshost: str):
    """Remove user from group"""
    response = api_call('DELETE', f"groups/{group_id}/users/{user_id}", dshost)
    
    if response.status_code in [200, 204]:
        print(f"User {user_id} removed from group {group_id}")
    else:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)

def group_members(group_id: int, dshost: str):
    """List group members"""
    response = api_call('GET', f"groups/{group_id}/users", dshost)
    
    if response.status_code != 200:
        print(f"ERROR: {response.text}", file=sys.stderr)
        sys.exit(1)
    
    # Get all users
    users_response = api_call('GET', 'admin/users', dshost)
    if users_response.status_code != 200:
        print(f"ERROR: Failed to fetch users", file=sys.stderr)
        sys.exit(1)
    
    users = {u['userID']: u['username'] for u in users_response.json()}
    
    print(f"{'UserID':<6}  {'Username':<18}  {'Role':<6}")
    print(f"{'------':<6}  {'------------------':<18}  {'------':<6}")
    
    try:
        root = ET.fromstring(response.text)
        for user in root.findall('.//{http://zotero.org/ns/transfer}user'):
            uid = int(user.get('id'))
            role = user.get('role')
            username = users.get(uid, 'Unknown')
            print(f"{uid:<6}  {username:<18}  {role:<6}")
    except ET.ParseError:
        pass

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ['-h', '--help', 'help']:
        print_usage()
        sys.exit(0)
    
    # Parse --host flag
    args = sys.argv[1:]
    dshost = None
    
    if args[0] == '--host':
        if len(args) < 2:
            print("ERROR: --host requires a URL argument", file=sys.stderr)
            sys.exit(1)
        dshost = args[1]
        args = args[2:]
    
    if len(args) < 2:
        print_usage()
        sys.exit(1)
    
    resource = args[0]
    action = args[1]
    action_args = args[2:]
    
    load_env()
    check_env()
    
    if dshost is None:
        dshost = f"http://{os.getenv('SERVER_IP', '127.0.0.1')}:8080"
    
    try:
        if resource == 'user':
            if action == 'create':
                if len(action_args) != 3:
                    print("Usage: admin.py user create <username> <email> <password>", file=sys.stderr)
                    sys.exit(1)
                user_create(action_args[0], action_args[1], action_args[2], dshost)
            elif action == 'list':
                user_list(dshost)
            elif action == 'disable':
                if len(action_args) != 1:
                    print("Usage: admin.py user disable <username>", file=sys.stderr)
                    sys.exit(1)
                user_disable(action_args[0], dshost)
            elif action == 'enable':
                if len(action_args) != 1:
                    print("Usage: admin.py user enable <username>", file=sys.stderr)
                    sys.exit(1)
                user_enable(action_args[0], dshost)
            elif action == 'quota':
                if len(action_args) != 1:
                    print("Usage: admin.py user quota <user_id>", file=sys.stderr)
                    sys.exit(1)
                user_quota(int(action_args[0]), dshost)
            elif action == 'set-quota':
                if len(action_args) != 2:
                    print("Usage: admin.py user set-quota <user_id> <quota_mb>", file=sys.stderr)
                    sys.exit(1)
                user_set_quota(int(action_args[0]), int(action_args[1]), dshost)
            else:
                print(f"Unknown user action: {action}", file=sys.stderr)
                print_usage()
                sys.exit(1)
        
        elif resource == 'group':
            if action == 'create':
                if len(action_args) != 3:
                    print("Usage: admin.py group create <owner_id> <name> <type>", file=sys.stderr)
                    sys.exit(1)
                group_create(int(action_args[0]), action_args[1], action_args[2], dshost)
            elif action == 'list':
                group_list(dshost)
            elif action == 'delete':
                if len(action_args) != 1:
                    print("Usage: admin.py group delete <group_id>", file=sys.stderr)
                    sys.exit(1)
                group_delete(int(action_args[0]), dshost)
            elif action == 'add-user':
                if len(action_args) < 2 or len(action_args) > 3:
                    print("Usage: admin.py group add-user <group_id> <user_id> [role]", file=sys.stderr)
                    sys.exit(1)
                role = action_args[2] if len(action_args) == 3 else 'member'
                group_add_user(int(action_args[0]), int(action_args[1]), role, dshost)
            elif action == 'remove-user':
                if len(action_args) != 2:
                    print("Usage: admin.py group remove-user <group_id> <user_id>", file=sys.stderr)
                    sys.exit(1)
                group_remove_user(int(action_args[0]), int(action_args[1]), dshost)
            elif action == 'members':
                if len(action_args) != 1:
                    print("Usage: admin.py group members <group_id>", file=sys.stderr)
                    sys.exit(1)
                group_members(int(action_args[0]), dshost)
            else:
                print(f"Unknown group action: {action}", file=sys.stderr)
                print_usage()
                sys.exit(1)
        
        else:
            print(f"Unknown resource: {resource}", file=sys.stderr)
            print_usage()
            sys.exit(1)
    
    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
