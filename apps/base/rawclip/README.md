# Rawclip Relay

Cloud relay server for Rawclip — proxies API calls and SSE events between remote browsers (mods/editors) and the streamer's local agent. Never touches video.

**Stack:** Bun + Hono + Better Auth + SQLite

## Build & Push

```sh
cd ~/workspace/git/streamamus

docker build -t registry.milanchis.com/rawclip-relay:latest -f relay/Dockerfile .
docker push registry.milanchis.com/rawclip-relay:latest

docker build -t registry.milanchis.com/rawclip-web:latest -f website/Dockerfile .
docker push registry.milanchis.com/rawclip-web:latest
```

## Configuration

All config via environment variables:

| Env Var | Default | Description |
|---|---|---|
| `RELAY_PORT` | `9430` | HTTP listen port |
| `BETTER_AUTH_SECRET` | — | **Required.** Session encryption key. Generate with `openssl rand -hex 32` |
| `BETTER_AUTH_URL` | `http://localhost:9430` | Public URL of the relay (used for OAuth callbacks) |
| `TWITCH_CLIENT_ID` | — | Twitch OAuth app client ID |
| `TWITCH_CLIENT_SECRET` | — | Twitch OAuth app client secret |
| `GOOGLE_CLIENT_ID` | — | Google OAuth client ID (optional) |
| `GOOGLE_CLIENT_SECRET` | — | Google OAuth client secret (optional) |
| `KICK_CLIENT_ID` | — | Kick OAuth client ID (optional) |
| `KICK_CLIENT_SECRET` | — | Kick OAuth client secret (optional) |
| `RELAY_OWNER_EMAIL` | — | Email that always gets `owner` role (must match OAuth login email) |
| `RAWCLIP_LICENSE_SIGNING_KEY` | — | Ed25519 private key (hex). Generate with `bun relay/scripts/gen-license-key.ts` |

## Twitch OAuth Setup

1. Go to https://dev.twitch.tv/console/apps
2. Create a new application
3. Set redirect URI to `https://rawclip-relay.milanchis.com/api/auth/callback/twitch`
4. Copy the Client ID and Client Secret into the sealed secret below

## Sealed Secret

Generate the app secrets:

```sh
kubectl create secret generic streamamus-secret \
  --dry-run=client \
  --namespace=streamamus \
  --from-literal=BETTER_AUTH_SECRET="$(openssl rand -hex 32)" \
  --from-literal=TWITCH_CLIENT_ID='your-twitch-client-id' \
  --from-literal=TWITCH_CLIENT_SECRET='your-twitch-client-secret' \
  --from-literal=GOOGLE_CLIENT_ID='' \
  --from-literal=GOOGLE_CLIENT_SECRET='' \
  --from-literal=KICK_CLIENT_ID='' \
  --from-literal=KICK_CLIENT_SECRET='' \
  --from-literal=RELAY_OWNER_EMAIL='your-email@example.com' \
  --from-literal=RAWCLIP_LICENSE_SIGNING_KEY="$(bun relay/scripts/gen-license-key.ts 2>/dev/null | grep RAWCLIP_LICENSE_SIGNING_KEY | cut -d= -f2)" \
  -o yaml | \
  kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format yaml \
    --scope namespace-wide > /home/mike/workspace/git/homelab/apps/base/rawclip/sealedsecret.yaml
```

To read back values from the cluster:

```sh
kubectl get secret streamamus-secret -n streamamus -o jsonpath='{.data.BETTER_AUTH_SECRET}' | base64 -d
kubectl get secret streamamus-secret -n streamamus -o jsonpath='{.data.TWITCH_CLIENT_ID}' | base64 -d
```

## Registry Credentials

The kubelet needs auth to pull from `registry.milanchis.com`:

```sh
kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  --namespace=streamamus \
  --dry-run=client -o yaml | \
  kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format yaml \
    --scope namespace-wide > /home/mike/workspace/git/homelab/apps/base/rawclip/registry-sealedsecret.yaml
```

## DNS

Add a CNAME or A record in Cloudflare:

```
rawclip-relay.milanchis.com → cluster IP (10.69.99.69)
```

Or use the existing wildcard `*.milanchis.com` if configured.

## Kubernetes Resources

- **Namespace**: `streamamus`
- **Deployment**: single replica, image from `registry.milanchis.com/rawclip-relay:latest`
- **Service**: port 80 → 9430
- **PVC**: 200Mi Longhorn for SQLite persistence at `/app/data`
- **SealedSecret**: OAuth credentials + auth secret + owner email + license signing key
- **Ingress** (overlay): `rawclip-relay.milanchis.com` via Traefik with TLS
- **Certificate**: auto-issued by cert-manager via Cloudflare DNS-01

## Post-Deploy Verification

```sh
# Check pod is running
kubectl get pods -n streamamus

# Check logs
kubectl logs -n streamamus -l app=rawclip

# Health check
curl https://rawclip-relay.milanchis.com/api/health

# Test pairing endpoint
curl -s -X POST https://rawclip-relay.milanchis.com/api/pair/init | jq .

# Test license endpoint (should include signed token)
curl -s -X POST https://rawclip-relay.milanchis.com/api/license/activate \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com"}' | jq .
# Expect: { "premium": false, "tier": "free", ..., "token": "eyJ..." }
```

## License Signing (Ed25519)

License responses are signed with Ed25519 to prevent local SQLite tampering. The relay holds the private key; the Rust agent has the public key compiled in.

### How It Works

1. Relay signs every `/api/license/activate` and `/api/license/check` response with a JWT-like token (`header.payload.signature`)
2. Agent verifies the signature using a compiled-in 32-byte Ed25519 public key
3. Verified token is cached in `license_cache.signed_token` — on cache fallback, the signature is re-verified
4. If the signature is invalid or missing, the agent degrades to `tier=free`

### Key Rotation

If you need to rotate the signing key:

```sh
# 1. Generate new keypair
cd ~/workspace/git/streamamus
bun relay/scripts/gen-license-key.ts

# 2. Update relay env (sealed secret) with new RAWCLIP_LICENSE_SIGNING_KEY
echo -n "NEW_HEX_KEY_HERE" | kubeseal --raw --namespace streamamus \
  --name streamamus-secret --scope namespace-wide

# 3. Update Rust agent with new public key
# Paste the const RELAY_PUBLIC_KEY line into rust_agent/src/license.rs

# 4. Rebuild + redeploy both relay and agent
```

### Testing Locally

```sh
# 1. Start relay with signing key
cd ~/workspace/git/streamamus/relay
RAWCLIP_LICENSE_SIGNING_KEY=86a5874c66a2553edf669d5369f0eaa59f672aabcee335f5db3aa50a50308a9f \
  bun run dev

# 2. Seed test licenses (run once — insert into relay's SQLite)
sqlite3 data/relay.sqlite "
INSERT OR IGNORE INTO license (user_id, email, tier, active, expires_at) VALUES
  ('test-free',      'free@test.com',      'free',       1, NULL),
  ('test-pro',       'pro@test.com',       'pro',        1, NULL),
  ('test-pro-ai',    'proai@test.com',     'pro_ai',     1, NULL),
  ('test-team',      'team@test.com',      'team',       1, NULL),
  ('test-team-ai',   'teamai@test.com',    'team_ai',    1, NULL),
  ('test-agency',    'agency@test.com',    'agency',     1, NULL),
  ('test-agency-ai', 'agencyai@test.com',  'agency_ai',  1, NULL),
  ('test-expired',   'expired@test.com',   'pro',        1, '2020-01-01T00:00:00Z'),
  ('test-inactive',  'inactive@test.com',  'pro',        0, NULL);
"

# 3. Test each tier — verify correct features and signed token
for email in free@test.com pro@test.com proai@test.com team@test.com \
             teamai@test.com agency@test.com agencyai@test.com \
             expired@test.com inactive@test.com unknown@test.com; do
  echo "=== $email ==="
  curl -s -X POST http://localhost:9430/api/license/activate \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\"}" | jq '{tier, premium, features, token: (.token[:20] + "...")}'
  echo
done
```

Expected results:

| Email | Tier | Premium | Features |
|---|---|---|---|
| `free@test.com` | free | false | `[]` |
| `pro@test.com` | pro | true | `["relay", "ai_summary"]` |
| `proai@test.com` | pro_ai | true | `["relay", "ai_summary", "managed_ai", "cloud_transcription"]` |
| `team@test.com` | team | true | `["relay", "ai_summary", "team_access"]` |
| `teamai@test.com` | team_ai | true | all of team + managed_ai + cloud_transcription |
| `agency@test.com` | agency | true | team + multi_streamer + api_webhooks |
| `agencyai@test.com` | agency_ai | true | all features |
| `expired@test.com` | free | false | `[]` (+ `"expired": true`) |
| `inactive@test.com` | free | false | `[]` (active=0 filtered out) |
| `unknown@test.com` | free | false | `[]` (no license row) |

All responses should include a `token` field (base64url JWT, 3 dot-separated parts).

```sh
# 4. Decode a token to verify payload matches response
TOKEN=$(curl -s -X POST http://localhost:9430/api/license/activate \
  -H 'Content-Type: application/json' \
  -d '{"email":"pro@test.com"}' | jq -r '.token')
echo "$TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq .
# Should show: { "sub": "pro@test.com", "tier": "pro", "features": ["relay", "ai_summary"], ... }

# 5. Build and run the Rust agent against a licensed email
cd ~/workspace/git/streamamus/rust_agent
cargo build
# In .env set: RAWCLIP_LICENSE_EMAIL=pro@test.com  RAWCLIP_RELAY_URL=http://localhost:9430
# Check agent logs for:
#   "License token signature verified"
#   "License: tier=pro, features=[\"relay\", \"ai_summary\"]"

# 6. Tamper test: edit license_cache in SQLite directly
sqlite3 data/rawclip.db "UPDATE license_cache SET tier='agency_ai', features='[\"relay\",\"ai_summary\",\"managed_ai\",\"cloud_transcription\",\"team_access\",\"multi_streamer\",\"api_webhooks\"]'"
# Restart agent — should log "Cached license token invalid" and degrade to free
# (the signed token still says "pro", so the tampered columns are rejected)

# 7. Test with relay down (cache fallback)
# Stop the relay, restart agent
# Agent should log: "License check failed ... falling back to cache"
# Then: "License token signature verified" (from cached signed_token)
# Features should still be pro-level (from the verified cached token, not the tampered columns)
```
