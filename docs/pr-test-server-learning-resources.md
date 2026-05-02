# PR Test Server Learning Resources

## GitHub Webhooks

Useful search keywords:

```text
GitHub webhook pull_request opened synchronize reopened
GitHub webhook X-Hub-Signature-256
GitHub webhook redeliver delivery logs
GitHub webhook respond within 10 seconds
GitHub webhook async processing queue
```

Recommended docs:

- GitHub webhook events and payloads: https://docs.github.com/webhooks-and-events/webhooks/webhook-events-and-payloads
- Validating webhook deliveries: https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries
- Best practices for using webhooks: https://docs.github.com/webhooks/using-webhooks/best-practices-for-using-webhooks

Important concepts:

- `X-GitHub-Event`
- `X-GitHub-Delivery`
- `X-Hub-Signature-256`
- webhook redelivery
- webhook idempotency
- returning a `2xx` response quickly
- background job processing

## Webhook Security

Useful search keywords:

```text
HMAC SHA256 webhook signature verification
constant time comparison timingSafeEqual
raw request body webhook verification Express
replay attack webhook X-GitHub-Delivery
webhook secret rotation
```

Node.js / Express topics:

```text
Express raw body webhook signature
body-parser raw application/json
crypto.createHmac sha256 Node.js
crypto.timingSafeEqual Node.js
```

Key ideas:

- Verify the raw request body, not a parsed/re-serialized JSON body.
- Use HMAC SHA-256 with the webhook secret.
- Compare signatures using constant-time comparison.
- Rotate secrets if they are exposed.
- Consider tracking `X-GitHub-Delivery` to prevent duplicate processing.

## Local Tunnel / Reverse Tunnel

Useful search keywords:

```text
reverse tunnel for local development
local webhook testing tunnel
localhost.run ssh reverse tunnel
ngrok reserved domain
cloudflare tunnel named tunnel
```

Recommended docs:

- localhost.run basics: https://localhost.run/docs/
- localhost.run CLI: https://localhost.run/docs/cli/
- Cloudflare Tunnel get started: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/
- ngrok reserved domains: https://ngrok.mintlify.dev/docs/api/resources/reserved-domains

Important concepts:

- reverse tunnel
- ephemeral URL
- reserved domain
- named tunnel
- keepalive
- NAT traversal
- reverse proxy
- TLS termination

## Why Temporary Tunnels Break

Useful search keywords:

```text
ephemeral tunnel URL
tunnel session timeout
ssh reverse tunnel keep alive
webhook tunnel 503 unavailable
ngrok stable domain
cloudflare tunnel persistent domain
```

Typical causes:

- SSH session drops.
- Laptop sleeps.
- Wi-Fi or NAT changes.
- Firewall resets the tunnel connection.
- Free anonymous tunnel providers recycle sessions.
- Generated public URL changes after reconnect.
- No watchdog process restarts the tunnel.
- GitHub webhook still points to an old tunnel URL.

## More Stable Deployment Options

Recommended directions:

- Deploy the webhook server to a VPS or cloud VM.
- Use Cloudflare Tunnel with a named tunnel and a stable domain.
- Use ngrok with a reserved domain.
- Add a watchdog script that restarts the tunnel and updates the GitHub webhook URL.

Useful search keywords:

```text
deploy webhook receiver VPS
Cloudflare Tunnel named tunnel domain
ngrok reserved domain webhook development
systemd service node webhook server
Windows scheduled task node server restart
```

## GitHub Automation Next Steps

Useful search keywords:

```text
GitHub Checks API create check run
GitHub commit status API pull request
GitHub App installation token
GitHub App webhooks checks API
GitHub REST API create pull request comment
```

Recommended learning path:

1. Learn GitHub webhook basics.
2. Learn HMAC signature verification.
3. Learn reverse tunnels and why temporary tunnel URLs are unstable.
4. Set up Cloudflare Tunnel or ngrok reserved domain.
5. Add async job queueing.
6. Replace PR comments with GitHub Checks API.
7. Replace PAT auth with GitHub App auth.

## Queue And Reliability Topics

Useful search keywords:

```text
BullMQ Redis webhook queue Node.js
webhook idempotency X-GitHub-Delivery
background jobs Node.js Express
retry failed webhook jobs
deduplicate webhook deliveries
```

Ideas to explore:

- Store each webhook delivery ID.
- Ignore duplicate deliveries.
- Queue jobs instead of running directly in memory.
- Persist run status.
- Retry failed jobs with backoff.
- Add a maximum concurrency limit.
- Add logs for every run.
