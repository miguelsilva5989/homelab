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
- **SealedSecret**: OAuth credentials + auth secret + owner email
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
```
