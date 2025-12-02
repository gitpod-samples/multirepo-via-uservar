#!/bin/bash
# Saves cloned repos in /workspaces to MY_ADDITIONAL_REPOS user secret.
set -e

# Detect main repo from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(basename "$(dirname "$SCRIPT_DIR")")"

# Login if needed
if gitpod whoami 2>/dev/null | grep -q "PRINCIPAL_ENVIRONMENT"; then
    gitpod login
fi

# Collect repo URLs (excluding main repo)
repos=()
for dir in /workspaces/*/; do
    name=$(basename "$dir")
    [ "$name" = "$MAIN_REPO" ] && continue
    [ -d "$dir/.git" ] && repos+=($(git -C "$dir" remote get-url origin 2>/dev/null))
done

[ ${#repos[@]} -eq 0 ] && echo "No additional repos found." && exit 0

value=$(IFS=';'; echo "${repos[*]}")
echo "Repos: $value"

# Create or update secret
id=$(gitpod user secret list --format json | jq -r '.[] | select(.name=="MY_ADDITIONAL_REPOS") | .id')
if [ -n "$id" ] && [ "$id" != "null" ]; then
    gitpod user secret update "$id" --value "$value"
else
    gitpod user secret create --name MY_ADDITIONAL_REPOS --value "$value" --env-var
fi
