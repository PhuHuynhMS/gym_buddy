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
GITHUB_TOKEN=
GITHUB_WEBHOOK_SECRET=change_me_to_a_random_secret
TARGET_REPO_PATH=D:\Projects\Android\gym_buddy
GITHUB_API_BASE_URL=https://api.github.com
```

Prefer setting `GITHUB_TOKEN` as an OS environment variable instead of storing a PAT in `.env`.

On Windows PowerShell, after setting the user environment variable, open a new terminal before running the server. For the current terminal session, you can inject it explicitly:

```powershell
$env:GITHUB_TOKEN = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN', 'User')
npm start
```

## Usage

```powershell
Invoke-RestMethod `
  -Method Post `
  -Uri http://localhost:5050/automation/pr-test `
  -ContentType 'application/json' `
  -Body '{"repo":"owner/name","prNumber":123}'
```

## GitHub Webhook

Expose the local server with a tunnel:

```powershell
ngrok http 5050
```

In GitHub repository settings, create a webhook:

```text
Payload URL: https://your-ngrok-url.ngrok-free.app/webhooks/github
Content type: application/json
Secret: same value as GITHUB_WEBHOOK_SECRET
Events: Pull requests
```

The server accepts these pull request actions:

```text
opened
synchronize
reopened
```

For supported actions, GitHub receives `202 Accepted` immediately and the PR test run continues in the background. The result is posted back to the pull request as a comment.

## Important Local Repo Note

This POC can point `TARGET_REPO_PATH` at the current `gym_buddy` repository, but the server runs git checkout/reset commands against that path. Before using it on active local work, commit or stash your changes. For safer real usage, point `TARGET_REPO_PATH` to a separate clone or worktree dedicated to automation runs.
