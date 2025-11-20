#!/bin/bash

# ----------------------------------------------------------------------
# Codespaces User Creation Script
# Usage: ./create_user.sh <username> <password>
#
# This script creates a new user, adds them to the specified groups (sudo, adm, trek),
# and sets a non-interactive password. It uses a temporary directory for the home
# path to avoid Codespaces permission issues.
# ----------------------------------------------------------------------

# --- 1. Argument Validation ---
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <password>"
    echo "Example: $0 kirk abc123"
    exit 1
fi

USERNAME=$1
PASSWORD=$2
GROUPS="sudo,adm,trek" # The list of groups to add the user to
HOME_DIR="/tmp/${USERNAME}_home" # Codespaces workaround for home directory

echo "Starting user creation script for user: ${USERNAME}"

# --- 2. Check if User Exists ---
# 'id -u' returns 0 if the user exists, and non-zero (1) if they don't.
if id -u "${USERNAME}" &> /dev/null; then
    echo "🛑 User '${USERNAME}' already exists. Exiting."
    exit 2
fi

# --- 3. User Creation ---

# Create the user:
# -m: Create the home directory (in /tmp/...)
# -d: Specify the custom home directory (the Codespaces workaround)
# -G: Specify secondary groups (sudo, adm, trek)
# -s: Specify the login shell (/bin/bash)
# Note: Using 'sudo' is mandatory for these administrative commands.

echo "1. Creating user '${USERNAME}' with home directory at ${HOME_DIR}..."
sudo useradd \
    -m \
    -d "${HOME_DIR}" \
    -G "${GROUPS}" \
    -s /bin/bash \
    "${USERNAME}"

if [ $? -ne 0 ]; then
    echo "🛑 Error: Failed to create user. Check sudo permissions."
    exit 3
fi

# --- 4. Password Setting (Non-Interactive) ---

# Use chpasswd to set the password without prompting.
echo "2. Setting non-interactive password..."
echo "${USERNAME}:${PASSWORD}" | sudo chpasswd

if [ $? -ne 0 ]; then
    echo "🛑 Error: Failed to set password. Check chpasswd command."
    # Clean up the user if password fails
    sudo userdel -r "${USERNAME}" &> /dev/null
    exit 4
fi

# --- 5. Confirmation ---

echo ""
echo "✅ SUCCESS: User '${USERNAME}' created and configured."
echo "   - Groups: ${GROUPS}"
echo "   - Home: ${HOME_DIR}"
echo ""
echo "Try logging in: su - ${USERNAME}"
