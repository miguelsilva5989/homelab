# Discordamus

Audio-only voice chat (Discord-style) for up to 5 users. Zig backend + WebRTC peer-to-peer audio in browser.

## Build & Push

```sh
cd ~/workspace/git/discordamus

docker build -t registry.milanchis.com/discordamus:latest .

docker push registry.milanchis.com/discordamus:latest
```

## Configuration

All config via environment variables (CLI args override):

| Env Var | CLI Arg | Default | Description |
|---|---|---|---|
| `DISCORDAMUS_PORT` | `--port=` | `8080` | HTTP listen port |
| `DISCORDAMUS_PASSWORD` | `--password=` | `secret` | Room password |
| `DISCORDAMUS_DB_PATH` | `--db-path=` | `discordamus.db` | SQLite database path |
| `DISCORDAMUS_STATIC_DIR` | `--static-dir=` | `frontend/build` | Static files directory |

## Sealed Secret

To regenerate the password:

```sh
kubectl create secret generic discordamus-secret \
  --dry-run=client \
  --namespace=discordamus \
  --from-literal=DISCORDAMUS_PASSWORD='<your-new-password>' \
  -o yaml | \
  kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format yaml \
    --scope namespace-wide > /home/mike/workspace/git/homelab/apps/base/discordamus/sealedsecret.yaml
```

To read back the current password from the cluster:

```sh
kubectl get secret discordamus-secret -n discordamus -o jsonpath='{.data.DISCORDAMUS_PASSWORD}' | base64 -d
```

## Kubernetes Resources

- **Namespace**: `discordamus`
- **Deployment**: single replica, image from `registry.milanchis.com/discordamus:latest`
- **Service**: port 80 -> 8080
- **PVC**: 200Mi Longhorn for SQLite persistence at `/app/data`
- **SealedSecret**: `DISCORDAMUS_PASSWORD`
- **Ingress** (overlay): `discordamus.milanchis.com` via Traefik with TLS
