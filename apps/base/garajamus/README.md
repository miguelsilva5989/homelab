# Garajamus hub

This is the central web interface and asynchronous history service for Garajamus.
Hardware access remains on client devices. The hub stores asynchronous client
events and does not provide a prerequisite for offline client operation.

The `zion` overlay publishes `https://garajamus.milanchis.com` through Traefik and
a certificate issued by `cloudflare-clusterissuer`. Authentication is enforced by
the application using scoped credentials; this route does not use Authentik.

## Runtime

- One application replica with `Recreate` deployment strategy.
- SQLite database at `/data/hub.sqlite3` on a dedicated 1 GiB Longhorn RWO PVC.
- Container runs as UID/GID 10001 with a read-only root filesystem.
- A bounded `/tmp` emptyDir supplies temporary writable storage.
- `/healthz` is the startup/liveness probe; `/readyz` also checks readiness.
- The application container is built from the application repository and published
  to `registry.milanchis.com/garajamus` with a versioned tag pinned by image digest.
- A workstation agent connects outward to the hub. This deployment receives no
  USB devices or privileged hardware access.

## Secrets

Two Secrets must exist in the `garajamus` namespace before rollout:

- `zion-regcred`: the registry pull credential, following the existing app pattern.
- `zion-garajamus-keys`: a `keys.json` entry containing `admin_sha256`,
  `worker_sha256`, and `pairing_code_sha256`. Only SHA-256 hashes belong in this
  file; raw tokens are provisioned to the relevant clients outside Git.

The environment points `GARAJAMUS_HUB_KEYS_FILE` to `/run/secrets/keys.json` and
`GARAJAMUS_HUB_DB` to the persistent database. `GARAJAMUS_PUBLIC_URL` is the HTTPS
origin above. Do not commit credentials or put tokens into an image, manifest,
URL, or public frontend bundle.

## Rollout

Publish and verify the image before changing its reference in `deployment.yaml`.
Render the overlay with `kubectl kustomize apps/overlays/zion/garajamus`, then use
server-side dry run to validate it. The top-level `apps/overlays/zion` resource
list controls Flux reconciliation. Check the Deployment rollout, readiness,
Certificate status, and authenticated application endpoints after an update.

Longhorn persistence is not a backup policy. Back up SQLite consistently before
schema changes; copying a live main database file alone can omit WAL contents.
Deleting the PVC can delete its dynamically provisioned volume, so preserve it
when rolling back application code.
