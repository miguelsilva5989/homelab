# GlyphForge

Web-based pixel font editor.

## Build & Push

```sh
cd ~/workspace/git/glyphforge

docker build -t registry.milanchis.com/glyphforge:latest .
docker push registry.milanchis.com/glyphforge:latest
```

## Registry Credentials

The kubelet needs auth to pull from `registry.milanchis.com`:

```sh
kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  --namespace=glyphforge \
  --dry-run=client -o yaml | \
  kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format yaml \
    --scope namespace-wide > /home/mike/workspace/git/homelab/apps/base/glyphforge/registry-sealedsecret.yaml
```

## Kubernetes Resources

- **Namespace**: `glyphforge`
- **Deployment**: single replica, image from `registry.milanchis.com/glyphforge:latest`
- **Service**: port 80 → 8000
- **SealedSecret**: registry pull credentials
