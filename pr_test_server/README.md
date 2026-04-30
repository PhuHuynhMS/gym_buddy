# PR Test Server

Local POC server that accepts a manual PR test request, merges the pull request into the configured repository working copy, runs a placeholder test, and comments the result back to GitHub.

## Setup

```powershell
cd pr_test_server
npm install
Copy-Item .env.example .env
npm run dev
```

Configure `.env`:

```text
PORT=5050
GITHUB_TOKEN=ghp_your_token_here
TARGET_REPO_PATH=D:\Projects\Android\gym_buddy
GITHUB_API_BASE_URL=https://api.github.com
```

## Usage

```powershell
Invoke-RestMethod `
  -Method Post `
  -Uri http://localhost:5050/automation/pr-test `
  -ContentType 'application/json' `
  -Body '{"repo":"owner/name","prNumber":123}'
```

## Important Local Repo Note

This POC can point `TARGET_REPO_PATH` at the current `gym_buddy` repository, but the server runs git checkout/reset commands against that path. Before using it on active local work, commit or stash your changes. For safer real usage, point `TARGET_REPO_PATH` to a separate clone or worktree dedicated to automation runs.
