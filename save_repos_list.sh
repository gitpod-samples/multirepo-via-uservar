#!/bin/bash
# Detects cloned git repositories in /workspaces and updates the MY_ADDITIONAL_REPOS
# user secret in the Ona user profile.

set -e

WORKSPACES_DIR="/workspaces"
MAIN_REPO="multi-repo-via-env-var"
SECRET_NAME="MY_ADDITIONAL_REPOS"

# Check if logged in as a user (not environment principal)
check_login() {
    local user_type
    user_type=$(gitpod whoami 2>/dev/null | grep "User name:" | awk '{print $3}')
    if [ "$user_type" = "PRINCIPAL_ENVIRONMENT" ] || [ -z "$user_type" ]; then
        return 1
    fi
    return 0
}

# Login if necessary
if ! check_login; then
    echo "Not logged in as a user. Running 'gitpod login'..."
    gitpod login
fi

# Collect git repository URLs from /workspaces
repos=()
for dir in "$WORKSPACES_DIR"/*/; do
    dir_name=$(basename "$dir")
    
    # Skip the main repository
    if [ "$dir_name" = "$MAIN_REPO" ]; then
        continue
    fi
    
    # Check if it's a git repository
    if [ -d "$dir/.git" ]; then
        # Get the remote URL
        remote_url=$(git -C "$dir" remote get-url origin 2>/dev/null || true)
        if [ -n "$remote_url" ]; then
            repos+=("$remote_url")
            echo "Found repository: $dir_name -> $remote_url"
        fi
    fi
done

if [ ${#repos[@]} -eq 0 ]; then
    echo "No additional repositories found in $WORKSPACES_DIR"
    echo "Nothing to save."
    exit 0
fi

# Join repos with semicolon
repos_value=$(IFS=';'; echo "${repos[*]}")
echo ""
echo "Repository list: $repos_value"

# Check if secret already exists
existing_secret_id=$(gitpod user secret list --format json 2>/dev/null | jq -r ".[] | select(.name == \"$SECRET_NAME\") | .id" || true)

if [ -n "$existing_secret_id" ] && [ "$existing_secret_id" != "null" ]; then
    echo "Updating existing secret $SECRET_NAME (ID: $existing_secret_id)..."
    gitpod user secret update "$existing_secret_id" --value "$repos_value"
else
    echo "Creating new secret $SECRET_NAME..."
    gitpod user secret create --name "$SECRET_NAME" --value "$repos_value" --env-var
fi

echo ""
echo "Successfully saved repository list to user secret $SECRET_NAME"
