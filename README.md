# Multi-Repo via User Variable

Dynamically manage multiple git repositories in your Gitpod dev environment.

## Problem

As a developer, I want to add/remove git repos from my dev environment as needed, and have that selection persist across new environments.

## How It Works

1. **On environment start**: All repos listed in `MY_ADDITIONAL_REPOS` are cloned to `/workspaces/`
2. **During development**: Add or remove git working copies in `/workspaces/` as needed
3. **To persist changes**: Run `save_repos_list.sh` to save your current repo selection

The repo list is stored as a semicolon-separated user secret (`MY_ADDITIONAL_REPOS`) that gets injected as an environment variable.

## Usage

### Adding a repo

```bash
cd /workspaces
git clone https://github.com/owner/repo.git
save_repos_list.sh  # persist for future environments
```

### Removing a repo

```bash
rm -rf /workspaces/repo-name
save_repos_list.sh  # persist for future environments
```

### Viewing current repos

```bash
echo $MY_ADDITIONAL_REPOS
```

## Files

- `.devcontainer/clone_repos.sh` - Clones repos from `MY_ADDITIONAL_REPOS` on environment start
- `.devcontainer/save_repos_list.sh` - Saves current `/workspaces/` repos to user secret