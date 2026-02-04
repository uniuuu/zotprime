#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if it exists
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(grep -v '^#' "$PROJECT_DIR/.env" | xargs)
fi

# Derive DSHOST from SERVER_IP
DSHOST="http://${SERVER_IP:-127.0.0.1}:8080"

# Validate required env vars
check_env() {
    if [ -z "$API_SUPER_TOKEN" ]; then
        echo "ERROR: API_SUPER_TOKEN not set" >&2
        exit 1
    fi
}

usage() {
    cat <<EOF
ZotPrime Admin Tool

Usage: $0 <resource> <action> [args...]

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
  $0 user create alice alice@example.com secret123
  $0 user list
  $0 group create 1 "My Group" PublicOpen
  $0 group add-user 123 456 admin

Environment Variables (required):
  SERVER_IP           Server IP address (default: 127.0.0.1)
  API_SUPER_TOKEN     API super user token
EOF
    exit 1
}

# API call helper
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3

    local url="${DSHOST%/}/$endpoint"

    local args=(-s -X "$method" -H "Authorization: Bearer $API_SUPER_TOKEN")

    if [ -n "$data" ]; then
        args+=(-H "Content-Type: text/xml" -d "$data")
    fi

    curl "${args[@]}" "$url"
}

# User commands (via API)
user_create() {
    local username=$1 email=$2 password=$3

    if [ -z "$username" ] || [ -z "$email" ] || [ -z "$password" ]; then
        echo "Usage: $0 user create <username> <email> <password>" >&2
        exit 1
    fi

    local json="{\"username\":\"$username\",\"email\":\"$email\",\"password\":\"$password\"}"
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $API_SUPER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$json" \
        "${DSHOST}/admin/users")
    
    if echo "$response" | jq -e '.userID' >/dev/null 2>&1; then
        echo "User created successfully!"
        echo "$response" | jq -r '"  UserID: \(.userID)\n  Username: \(.username)\n  Email: \(.email)\n  LibraryID: \(.libraryID)"'
    else
        echo "ERROR: $response" >&2
        exit 1
    fi
}

user_list() {
    local response=$(curl -s -H "Authorization: Bearer $API_SUPER_TOKEN" \
        "${DSHOST}/admin/users")
    
    echo "UserID  Username            Email                       Status"
    echo "------  ------------------  --------------------------  --------"
    echo "$response" | jq -r '.[] | "\(.userID)|\(.username)|\(.email)|\(if .enabled then "enabled" else "disabled" end)"' | \
        while IFS='|' read -r uid uname email status; do
            printf "%-6s  %-18s  %-26s  %s\n" "$uid" "$uname" "$email" "$status"
        done
}

user_disable() {
    local username=$1

    if [ -z "$username" ]; then
        echo "Usage: $0 user disable <username>" >&2
        exit 1
    fi

    # Get user ID from username
    local response=$(curl -s -H "Authorization: Bearer $API_SUPER_TOKEN" \
        "${DSHOST}/admin/users")
    
    local user_id=$(echo "$response" | jq -r ".[] | select(.username==\"$username\") | .userID")
    
    if [ -z "$user_id" ]; then
        echo "ERROR: User '$username' not found" >&2
        exit 1
    fi

    curl -s -X PUT \
        -H "Authorization: Bearer $API_SUPER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"enabled":false}' \
        "${DSHOST}/admin/users/${user_id}/status"
    
    echo "User '$username' (ID: $user_id) disabled"
}

user_enable() {
    local username=$1

    if [ -z "$username" ]; then
        echo "Usage: $0 user enable <username>" >&2
        exit 1
    fi

    # Get user ID from username
    local response=$(curl -s -H "Authorization: Bearer $API_SUPER_TOKEN" \
        "${DSHOST}/admin/users")
    
    local user_id=$(echo "$response" | jq -r ".[] | select(.username==\"$username\") | .userID")
    
    if [ -z "$user_id" ]; then
        echo "ERROR: User '$username' not found" >&2
        exit 1
    fi

    curl -s -X PUT \
        -H "Authorization: Bearer $API_SUPER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"enabled":true}' \
        "${DSHOST}/admin/users/${user_id}/status"
    
    echo "User '$username' (ID: $user_id) enabled"
}

user_quota() {
    local mode=$1 user_id=$2

    if [ -z "$user_id" ]; then
        echo "Usage: $0 $mode user quota <user_id>" >&2
        exit 1
    fi

    # API call from host
    local response=$(curl -s -H "Authorization: Bearer $API_SUPER_TOKEN" \
        "${DSHOST}/users/${user_id}/storageadmin")
    
    if echo "$response" | grep -q "<quota>"; then
        local quota=$(echo "$response" | grep -oP '(?<=<quota>)[^<]+')
        local inst_quota=$(echo "$response" | grep -oP '(?<=<instQuota>)[^<]+')
        local usage=$(echo "$response" | grep -oP '(?<=<usage>)[^<]+')
        
        echo "User ID: $user_id"
        echo "  Quota: ${quota} MB"
        echo "  Institutional Quota: ${inst_quota} MB"
        echo "  Usage: ${usage} MB"
    else
        echo "ERROR: $response" >&2
        exit 1
    fi
}

user_set_quota() {
    local user_id=$1 quota_mb=$2

    if [ -z "$user_id" ] || [ -z "$quota_mb" ]; then
        echo "Usage: $0 user set-quota <user_id> <quota_mb>" >&2
        exit 1
    fi

    # API call from host
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $API_SUPER_TOKEN" \
        -d "quota=${quota_mb}" \
        -d "expiration=0" \
        "${DSHOST}/users/${user_id}/storageadmin")
    
    if echo "$response" | grep -q "<quota>"; then
        echo "Quota set successfully for user $user_id"
        user_quota "$user_id"
    else
        echo "ERROR: $response" >&2
        exit 1
    fi
}

# Group commands (via REST API)
group_create() {
    local owner_id=$1 name=$2 type=$3

    if [ -z "$owner_id" ] || [ -z "$name" ] || [ -z "$type" ]; then
        echo "Usage: $0 <mode> group create <owner_id> <name> <type>" >&2
        echo "Types: PublicOpen, PublicClosed, Private" >&2
        exit 1
    fi

    # Validate type
    case $type in
        PublicOpen|PublicClosed|Private) ;;
        *)
            echo "ERROR: Invalid group type '$type'. Use: PublicOpen, PublicClosed, or Private" >&2
            exit 1
            ;;
    esac

    # Set fileEditing based on type (PublicOpen groups cannot have file editing)
    if [ "$type" = "PublicOpen" ]; then
        local file_editing="none"
    else
        local file_editing="members"
    fi

    local xml="<group owner=\"$owner_id\" name=\"$name\" type=\"$type\" libraryEditing=\"members\" libraryReading=\"all\" fileEditing=\"$file_editing\"/>"

    local response=$(api_call POST "groups" "$xml")
    
    # Extract group ID and name from XML response
    local group_id=$(echo "$response" | grep -oP '<zapi:groupID>\K[^<]+' || echo "")
    if [ -n "$group_id" ]; then
        echo "Group created successfully!"
        echo "  ID: $group_id"
        echo "  Name: $name"
        echo "  Type: $type"
        echo "  Owner: $owner_id"
    else
        echo "ERROR: Failed to create group. Check server logs for details." >&2
        exit 1
    fi
}

group_list() {
    local response=$(curl -s -H "Authorization: Bearer $API_SUPER_TOKEN" \
        "${DSHOST}/admin/groups")
    
    echo "ID   Name                Type          Owner  LibraryID"
    echo "---- ------------------- ------------- ------ ---------"
    echo "$response" | jq -r '.[] | "\(.id)|\(.name)|\(.type)|\(.owner)|\(.libraryID)"' | \
        while IFS='|' read -r gid gname gtype gowner libid; do
            printf "%-4s %-19s %-13s %-6s %s\n" "$gid" "$gname" "$gtype" "$gowner" "$libid"
        done
}

group_delete() {
    local group_id=$1

    if [ -z "$group_id" ]; then
        echo "Usage: $0 <mode> group delete <group_id>" >&2
        exit 1
    fi

    api_call DELETE "groups/$group_id"
    echo "Group $group_id deleted"
}

group_add_user() {
    local group_id=$1 user_id=$2 role=${3:-member}

    if [ -z "$group_id" ] || [ -z "$user_id" ]; then
        echo "Usage: $0 <mode> group add-user <group_id> <user_id> [role]" >&2
        echo "Roles: admin, member (default: member)" >&2
        exit 1
    fi

    # Validate role
    case $role in
        admin|member) ;;
        *)
            echo "ERROR: Invalid role '$role'. Use: admin or member" >&2
            exit 1
            ;;
    esac

    local xml="<user id=\"$user_id\" role=\"$role\"/>"

    local response=$(api_call PUT "groups/$group_id/users/$user_id" "$xml")
    
    if echo "$response" | grep -q "<title>"; then
        echo "User $user_id added to group $group_id as $role"
    else
        echo "$response"
    fi
}

group_remove_user() {
    local group_id=$1 user_id=$2

    if [ -z "$group_id" ] || [ -z "$user_id" ]; then
        echo "Usage: $0 <mode> group remove-user <group_id> <user_id>" >&2
        exit 1
    fi

    api_call DELETE "groups/$group_id/users/$user_id"
    echo "User $user_id removed from group $group_id"
}

group_members() {
    local group_id=$1

    if [ -z "$group_id" ]; then
        echo "Usage: $0 <mode> group members <group_id>" >&2
        exit 1
    fi

    local response=$(api_call GET "groups/$group_id/users")
    
    echo "UserID  Role"
    echo "------  ------"
    echo "$response" | grep -oP '<xfer:user id="\K[^"]+' | while read uid; do
        local role=$(echo "$response" | grep "id=\"$uid\"" | grep -oP 'role="\K[^"]+')
        printf "%-6s  %s\n" "$uid" "$role"
    done
}

# Main
[ $# -lt 2 ] && usage

RESOURCE=$1
ACTION=$2
shift 2

check_env

case "$RESOURCE" in
    user)
        case "$ACTION" in
            create)     user_create "$@" ;;
            list)       user_list ;;
            disable)    user_disable "$@" ;;
            enable)     user_enable "$@" ;;
            quota)      user_quota "$@" ;;
            set-quota)  user_set_quota "$@" ;;
            *)          echo "Unknown user action: $ACTION" >&2; usage ;;
        esac
        ;;
    group)
        case "$ACTION" in
            create)      group_create "$@" ;;
            list)        group_list ;;
            delete)      group_delete "$@" ;;
            add-user)    group_add_user "$@" ;;
            remove-user) group_remove_user "$@" ;;
            members)     group_members "$@" ;;
            *)           echo "Unknown group action: $ACTION" >&2; usage ;;
        esac
        ;;
    *)
        echo "Unknown resource: $RESOURCE" >&2
        usage
        ;;
esac
