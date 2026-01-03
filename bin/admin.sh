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
    local missing=()
    [ -z "$API_SUPER_TOKEN" ] && missing+=("API_SUPER_TOKEN")
    [ -z "$MYSQLROOTPASSWORD" ] && missing+=("MYSQLROOTPASSWORD")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "ERROR: Required environment variables not set: ${missing[*]}" >&2
        exit 1
    fi
}

usage() {
    cat <<EOF
ZotPrime Admin Tool

Usage: $0 <mode> <resource> <action> [args...]

Modes:
  docker    Use Docker Compose
  k8s       Use Kubernetes (kubectl)

Resources and Actions:
  user create <username> <email> <password>   Create a new user
  user list                                   List all users
  user disable <username>                     Disable a user
  user enable <username>                      Enable a user

  group create <owner_id> <name> <type>       Create a group (type: PublicOpen|PublicClosed|Private)
  group list                                  List all groups
  group delete <group_id>                     Delete a group
  group add-user <group_id> <user_id> [role]  Add user to group (role: admin|member, default: member)
  group remove-user <group_id> <user_id>      Remove user from group
  group members <group_id>                    List group members

Examples:
  $0 docker user create alice alice@example.com secret123
  $0 docker user list
  $0 docker group create 1 "My Group" PublicOpen
  $0 k8s group add-user 123 456 admin

Environment Variables (required):
  DSHOST              Dataserver URL (e.g., http://127.0.0.1:8080/)
  API_SUPER_TOKEN     API super user token
  MYSQLROOTPASSWORD   MySQL root password
EOF
    exit 1
}

# Get container exec command based on mode
get_exec_cmd() {
    local mode=$1
    case $mode in
        docker)
            echo "docker compose exec -e MYSQLROOTPASSWORD=$MYSQLROOTPASSWORD zotprime-dataserver"
            ;;
        k8s)
            echo "kubectl exec -n zotprime deployment/zotprime-dataserver --"
            ;;
        *)
            echo "ERROR: Invalid mode '$mode'. Use 'docker' or 'k8s'" >&2
            exit 1
            ;;
    esac
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

# User commands (via container exec)
user_create() {
    local mode=$1 username=$2 email=$3 password=$4

    if [ -z "$username" ] || [ -z "$email" ] || [ -z "$password" ]; then
        echo "Usage: $0 $mode user create <username> <email> <password>" >&2
        exit 1
    fi

    local exec_cmd=$(get_exec_cmd "$mode")
    cd "$PROJECT_DIR"
    $exec_cmd /var/www/zotero/admin/create-user.sh "$username" "$email" "$password"
}

user_list() {
    local mode=$1
    local exec_cmd=$(get_exec_cmd "$mode")
    cd "$PROJECT_DIR"
    $exec_cmd /var/www/zotero/admin/list-users.sh
}

user_disable() {
    local mode=$1 username=$2

    if [ -z "$username" ]; then
        echo "Usage: $0 $mode user disable <username>" >&2
        exit 1
    fi

    local exec_cmd=$(get_exec_cmd "$mode")
    cd "$PROJECT_DIR"
    $exec_cmd /var/www/zotero/admin/disable-user.sh "$username"
}

user_enable() {
    local mode=$1 username=$2

    if [ -z "$username" ]; then
        echo "Usage: $0 $mode user enable <username>" >&2
        exit 1
    fi

    local exec_cmd=$(get_exec_cmd "$mode")
    cd "$PROJECT_DIR"
    $exec_cmd /var/www/zotero/admin/enable-user.sh "$username"
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
    local user_id=$1  # Optional parameter

    if [ -n "$user_id" ]; then
        # List groups for specific user
        local response=$(api_call GET "users/$user_id/groups?format=json")
        echo "$response" | jq -r '.[] | "ID: \(.data.id) | Name: \(.data.name) | Type: \(.data.type) | Owner: \(.data.owner)"' 2>/dev/null
    else
        # List all groups (deduplicated)
        local exec_cmd=$(get_exec_cmd "$MODE")
        local user_ids=$($exec_cmd sh -c "mysql -h mysql -P 3306 -u root -p\$MYSQLROOTPASSWORD zotero_www -sN -e 'SELECT userID FROM users'")

        echo "ID  Name                Type          Owner  Members"
        echo "--- ------------------- ------------- ------ -------"
        
        local temp_file=$(mktemp)
        for uid in $user_ids; do
            local user_groups=$(api_call GET "users/$uid/groups?format=json" 2>/dev/null)
            
            if [ -n "$user_groups" ] && echo "$user_groups" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
                echo "$user_groups" | jq -r '.[] | "\(.data.id)|\(.data.name)|\(.data.type)|\(.data.owner)|\((.data.members // [] | length) + ((.data.admins // []) | length))"' 2>/dev/null >> "$temp_file"
            fi
        done
        
        sort -t'|' -k1 -n -u "$temp_file" | while IFS='|' read -r gid gname gtype gowner gmembers; do
            [ -n "$gid" ] && printf "%-3s %-19s %-13s %-6s %s\n" "$gid" "$gname" "$gtype" "$gowner" "$gmembers"
        done
        
        rm -f "$temp_file"
    fi
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
[ $# -lt 3 ] && usage

MODE=$1
RESOURCE=$2
ACTION=$3
shift 3

check_env

case "$RESOURCE" in
    user)
        case "$ACTION" in
            create)  user_create "$MODE" "$@" ;;
            list)    user_list "$MODE" ;;
            disable) user_disable "$MODE" "$@" ;;
            enable)  user_enable "$MODE" "$@" ;;
            *)       echo "Unknown user action: $ACTION" >&2; usage ;;
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
