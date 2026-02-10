# Discordamus

Audio-only voice chat server. Custom Zig binary + SvelteKit frontend, pushed to the self-hosted registry.

## Build & Push

```sh
cd ~/workspace/git/discordamus

docker build -t registry.milanchis.com/discordamus:latest .

docker push registry.milanchis.com/discordamus:latest
```

## Sealed Secret

```sh
kubectl create secret generic discordamus-secret \
  --dry-run=client \
  --namespace=discordamus \
  --from-literal=DISCORDAMUS_PASSWORD='<new-password>' \
  -o yaml | \
  kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format yaml \
    --scope namespace-wide > apps/base/discordamus/sealedsecret.yaml
```

## Access

https://discordamus.milanchis.com
