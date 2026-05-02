# PR Test Server Implementation Summary

## Purpose

`pr_test_server` is a standalone local automation server for testing GitHub pull requests before a full AI test runner is implemented.

The current POC receives a PR request, fetches the PR from GitHub, merges it into a dedicated local clone, runs a read-only AI code review, and comments the result back on the pull request.

## Implemented

- Created a standalone server in `pr_test_server`.
- Kept it separate from `gym_buddy_server`.
- Added manual trigger endpoint:
  - `POST /automation/pr-test`
- Added GitHub webhook endpoint:
  - `POST /webhooks/github`
- Added GitHub API integration using `GITHUB_TOKEN`.
- Added webhook signature verification using `GITHUB_WEBHOOK_SECRET`.
- Added support for GitHub `pull_request` webhook events.
- Processed only these pull request actions:
  - `opened`
  - `synchronize`
  - `reopened`
- Ignored unsupported webhook events/actions with `200 OK`.
- Returned `202 Accepted` immediately for supported webhook events.
- Ran PR test work asynchronously in the background after webhook acceptance.
- Added a dedicated runner clone:
  - `D:\Projects\Automation\gym_buddy_runner`
- Added Git workspace operations:
  - fetch base branch
  - checkout base branch
  - reset to `origin/<base>`
  - fetch PR head
  - merge PR head into base
  - cleanup/reset workspace afterward
- Added read-only AI review runner with provider interface.
- Added first AI review provider:
  - `ollama`
- Added AI review context collection:
  - PR diff
  - changed file paths
  - changed file contents
- Added review context limits:
  - `AI_REVIEW_MAX_DIFF_CHARS`
  - `AI_REVIEW_MAX_FILE_CHARS`
  - `AI_REVIEW_MAX_FILES`
- Added PR comments for success and failure.
- Added in-memory lock to prevent concurrent PR runs.
- Added `.env.example` for server configuration.
- Added README usage notes for manual endpoint, webhook setup, and tunnel usage.

## Not Implemented Yet

- GitHub App authentication.
- GitHub Checks API / Check Run integration.
- Commit status integration.
- AI code review is implemented through Ollama.
- AI test runner that executes tests is not implemented.
- Real project test commands such as `npm test`, `flutter test`, or custom scripts.
- Persistent job queue.
- Persistent run history.
- Retry logic for failed jobs.
- Multi-repository support.
- Dashboard or log viewer.
- Stable public deployment.
- Stable tunnel domain.
- Automatic tunnel restart.
- Automatic GitHub webhook URL update when the tunnel URL changes.
- Durable idempotency using `X-GitHub-Delivery`.
- Database-backed locking or queueing.

## Current Manual Workflow

```text
Caller sends POST /automation/pr-test
→ server validates request body
→ server fetches PR details from GitHub
→ server checks out the PR base branch in the runner clone
→ server resets the base branch to origin
→ server fetches the PR head ref
→ server merges the PR head into the base branch
→ server collects PR diff and changed file contents
→ server sends read-only review context to the configured AI provider
→ server receives Markdown AI review output
→ server posts a success or failure comment to the PR
→ server resets the runner clone back to the base branch
→ server returns API response to caller
```

Request body:

```json
{
  "repo": "PhuHuynhMS/gym_buddy",
  "prNumber": 1
}
```

## Current Webhook Workflow

```text
GitHub emits pull_request event
→ public tunnel forwards request to local server
→ server receives POST /webhooks/github
→ server verifies X-Hub-Signature-256 using GITHUB_WEBHOOK_SECRET
→ server checks X-GitHub-Event
→ server parses pull_request payload
→ server ignores unsupported actions
→ server returns 202 Accepted for opened/synchronize/reopened
→ background task calls runPrTest
→ runPrTest fetches, merges, collects review context, calls AI reviewer, and comments on the PR
```

Supported webhook actions:

```text
opened
synchronize
reopened
```

## Current Endpoints

```text
GET /
POST /automation/pr-test
POST /webhooks/github
```

## Environment Variables

Values commonly kept in `.env`:

```env
PORT=5050
GITHUB_API_BASE_URL=https://api.github.com
TARGET_REPO_PATH=D:\Projects\Automation\gym_buddy_runner
AI_REVIEW_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen2.5-coder:7b
AI_REVIEW_MAX_DIFF_CHARS=60000
AI_REVIEW_MAX_FILE_CHARS=20000
AI_REVIEW_MAX_FILES=20
```

Values expected from the operating system environment:

```text
GITHUB_TOKEN
GITHUB_WEBHOOK_SECRET
```

## Tunnel State

The current local development setup uses a temporary public tunnel through `localhost.run`.

Example payload URL:

```text
https://<generated-domain>.lhr.life/webhooks/github
```

This URL is temporary. If the SSH tunnel drops or restarts, the public URL can change. When that happens, the GitHub webhook payload URL must be updated.

## Known Operational Issues

- Temporary tunnels can return `503 Server Unavailable` even when the local server is healthy.
- GitHub webhook deliveries fail when the public tunnel URL is dead.
- Signature mismatch happens when GitHub's webhook secret does not match the server's `GITHUB_WEBHOOK_SECRET`.
- The local server process must be restarted after changing environment variables unless they are injected into the current process.
- The in-memory lock rejects concurrent runs instead of queueing them.

## Verified Behavior

- Manual endpoint works.
- Webhook endpoint verifies signatures.
- Invalid signatures return `401`.
- Unsupported events/actions are ignored.
- Supported PR webhook events return `202 Accepted`.
- Background job can fetch, merge, collect diff/changed-file context, call Ollama, and comment AI review output on a PR.
- The flow was verified using real GitHub PRs in `PhuHuynhMS/gym_buddy`.
