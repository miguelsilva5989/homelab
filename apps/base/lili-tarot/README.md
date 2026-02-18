# Lili Tarot

Astro SSR tarot site deployed at `tarot.milanchis.com`.

## Build & Push

```sh
cd ~/workspace/git/lili-tarot

docker build --build-arg GIT_HASH=$(git rev-parse --short HEAD) -t registry.milanchis.com/lili-tarot:latest .

docker push registry.milanchis.com/lili-tarot:latest
```

## Registry Credentials

To regenerate the registry sealed secret for this namespace:

```sh
kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  --namespace=lili-tarot \
  --dry-run=client -o yaml | \
  kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format yaml \
    --scope namespace-wide > ~/workspace/git/homelab/apps/base/lili-tarot/registry-sealedsecret.yaml
```

## Kubernetes Resources

- **Namespace**: `lili-tarot`
- **Deployment**: single replica, image from `registry.milanchis.com/lili-tarot:latest`
- **Service**: port 80 -> 4321
- **Ingress** (overlay): `tarot.milanchis.com` via Traefik with TLS
