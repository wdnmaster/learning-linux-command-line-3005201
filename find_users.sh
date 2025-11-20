#!/bin/bash

# ----------------------------------------------------------------------
# Pattern Matching Lab Setup Script
# Usage: sudo ./find_users.sh <user1,user2,...> <group_name>
#
# Creates users, assigns them to groups, and injects random security issues
# to be found by the 'grep' and 'find' commands.
# ----------------------------------------------------------------------

# --- Configuration ---
# The string we'll search for with grep
SUSPECT_KEYWORD="[UNAUTHORIZED_MODIFICATION_ALERT_X9]"
# The permission we'll search for with find
VULNERABLE_PERM="777"
DEFAULT_PERM="755"
DEFAULT_PASSWORD="abc123"


# --- 1. Input Validation ---
if [ "$#" -ne 2 ]; then
    echo "Error: Two arguments are required."
    echo "Usage: sudo $0 <user1,user2,...> <group_name>"
    echo "Example: sudo $0 kirk,spock,uhura trek"
    exit 1
fi

USER_CSV="$1"
GROUP_NAME="$2"
QUOTE_MESSAGE="I'm in the ${GROUP_NAME} group!"

echo "--- Starting Setup for Group: ${GROUP_NAME} ---"

# --- 2. Group Management (Silent Creation) ---
# The -f (force) flag prevents an error if the group already exists.
groupadd -f "${GROUP_NAME}" 2> /dev/null
if [ $? -eq 0 ]; then
    echo "Group '${GROUP_NAME}' checked/created successfully."
fi

# --- 3. User Creation and Injection Loop ---
IFS=',' read -ra USERS_ARRAY <<< "$USER_CSV"
CREATED_COUNT=0

for USER in "${USERS_ARRAY[@]}"; do
    echo "Processing user: ${USER}"

    # A) Pre-creation Cleanup (User Deletion)
    if id "${USER}" &> /dev/null; then
        echo "  -> WARNING: User ${USER} already exists. Deleting user and home directory..."
        userdel -r "${USER}" 2> /dev/null
    fi

    # B) User Creation
    # -m: Create home directory
    # -d /tmp/${USER}_home: Use a temporary path for Codespaces compatibility
    # -G sudo,adm,${GROUP_NAME}: Add user to necessary groups
    # -s /bin/bash: Set default shell
    useradd -m -d "/tmp/${USER}_home" -G sudo,adm,"${GROUP_NAME}" -s /bin/bash "${USER}"

    # C) Set Password (Non-interactive)
    echo "${USER}:${DEFAULT_PASSWORD}" | chpasswd

    # D) Home Directory Setup (quotes.txt)
    USER_HOME="/tmp/${USER}_home"
    QUOTE_FILE="${USER_HOME}/${USER}_quotes.txt"
    echo "${QUOTE_MESSAGE}" > "$QUOTE_FILE"
    
    # Ensure ownership is correct
    chown "${USER}:${USER}" "$QUOTE_FILE"
    chmod "${DEFAULT_PERM}" "$QUOTE_FILE"

    echo "  -> Created user, set password, and created ${QUOTE_FILE}"

    # E) Random Vulnerability Injection (60% chance for Grep)
    # $RANDOM % 100 generates a number from 0 to 99.
    if [ $(( RANDOM % 100 )) -lt 60 ]; then
        echo "${SUSPECT_KEYWORD}" >> "$QUOTE_FILE"
        echo "  -> VULNERABILITY INJECTED (Grep search target)."
        grep_target_count=$((grep_target_count + 1))
    fi

    # F) Random Permission Setting (50% chance for Find)
    if [ $(( RANDOM % 100 )) -lt 50 ]; then
        chmod "${VULNERABLE_PERM}" "$QUOTE_FILE"
        echo "  -> PERMISSION SET TO ${VULNERABLE_PERM} (Find search target)."
        find_target_count=$((find_target_count + 1))
    fi

    CREATED_COUNT=$((CREATED_COUNT + 1))
done

# --- 4. Completion Summary ---
echo "----------------------------------------------------"
echo "Setup Complete for ${CREATED_COUNT} Users in Group ${GROUP_NAME}."
echo "Login password for all users: ${DEFAULT_PASSWORD}"
echo "Injected Keyword Search Targets: ${grep_target_count} files."
echo "World-Writable Permission Targets: ${find_target_count} files."
echo "----------------------------------------------------"
echo "Let the search begin!"
