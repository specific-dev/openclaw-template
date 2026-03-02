# OpenClaw Specific Template (1-command deploy)

Deploy **OpenClaw** to [Specific](https://specific.dev) with a single command:

```bash
specific deploy
```

This repo packages OpenClaw with a **/setup** web wizard so users can deploy and onboard **without running any commands** on the server.

## Deploy instructions

1. Install the Specific CLI:
   ```bash
   npm i -g @specific.dev/cli
   ```

2. Deploy:
   ```bash
   specific deploy
   ```

3. When prompted, set `setup_password` to a strong password of your choice.

4. Visit `https://<your-domain>/setup`
   - Your browser will prompt for **HTTP Basic auth**. Use any username; the password is `setup_password`.
   - Complete the onboarding wizard (choose a model provider, add API keys, optionally add chat channels).

5. Visit `https://<your-domain>/` to use OpenClaw.
   - When prompted for the gateway auth token, find the auto-generated value in the **Secrets** tab at [dashboard.specific.dev](https://dashboard.specific.dev).

## Local development

Requires [Docker](https://www.docker.com/) to be installed and running.

```bash
specific dev
```

This builds the Docker image and runs it locally with secrets injected. Visit `http://localhost:<port>/setup` to complete onboarding.

## What you get

- **OpenClaw Gateway + Control UI** (served at `/` and `/openclaw`)
- A friendly **Setup Wizard** at `/setup` (protected by a password)
- Persistent state via **Specific Volume** (so config/credentials/memory survive redeploys)
- One-click **Export backup** from `/setup`
- **Import backup** from `/setup` (advanced recovery)
- **Device approval** from `/setup` (no shell access needed)

## How it works (high level)

- The container runs a wrapper web server on the Specific-assigned `PORT`.
- The wrapper protects `/setup` (and the Control UI at `/openclaw`) with `SETUP_PASSWORD` using HTTP Basic auth.
- During setup, the wrapper runs `openclaw onboard --non-interactive ...` inside the container, writes state to the volume, and then starts the gateway on loopback.
- After setup, **`/` is OpenClaw**. The wrapper reverse-proxies all traffic (including WebSockets) to the local gateway process.

## Configuration

The `specific.hcl` defines:

| Resource | Purpose |
|----------|---------|
| `secret "setup_password"` | Password for the `/setup` wizard (user-provided) |
| `secret "openclaw_gateway_token"` | Auto-generated 64-char token for gateway auth |
| `volume "data"` | Persistent storage for config, workspace, and credentials |

Environment variables passed to the container:

| Variable | Description |
|----------|-------------|
| `PORT` | Specific-assigned port (auto) |
| `SETUP_PASSWORD` | Protects `/setup` and Control UI |
| `OPENCLAW_GATEWAY_TOKEN` | Gateway authentication token |
| `OPENCLAW_STATE_DIR` | Config/state directory on the volume |
| `OPENCLAW_WORKSPACE_DIR` | Workspace directory on the volume |

## Troubleshooting

### "disconnected (1008): pairing required" / dashboard health offline

This means the gateway is running, but no device has been approved yet.

Fix:
- Open `/setup`
- Expand the **Pairing helper** section
- Click **Refresh pending devices** and approve the pending request

Or use the **Debug Console**:
- `openclaw devices list`
- `openclaw devices approve <requestId>`

### "unauthorized: gateway token mismatch"

The Control UI connects using `gateway.remote.token` and the gateway validates `gateway.auth.token`.

Fix:
- Re-run `/setup` so the wrapper writes both tokens.
- Or set both values to the same token in config.

### "Application failed to respond" / 502 Bad Gateway

Most often this means the wrapper is up, but the gateway can't start or can't bind.

Checklist:
- Check the Specific logs for the wrapper error.
- Ensure the volume is properly mounted (check `/healthz` endpoint).

## Credits

Based on the [openclaw-railway-template](https://github.com/vignesh07/clawdbot-railway-template) by Vignesh N (@vignesh07).
