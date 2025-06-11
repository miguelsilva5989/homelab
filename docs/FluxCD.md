
# FluxCD Setup

Check [Helm example](https://github.com/fluxcd/flux2-kustomize-helm-example)

```sh

export GITHUB_TOKEN=<gh-token>

flux bootstrap github --owner=miguelsilva5989 --repository=homelab --path=clusters/zion --personal --token-auth

# Watch for the Helm releases being installed on production
watch flux get helmreleases --all-namespaces
# Watch the production reconciliation
flux get kustomizations --watch

# kubectl apply -k ./infrastructure/controllers/zion
# kubectl -n traefik apply -k ./infrastructure/controllers/zion


```

## Secrets

https://fluxcd.io/flux/guides/sealed-secrets/