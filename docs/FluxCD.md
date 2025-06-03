
# FluxCD Setup

check https://github.com/fluxcd/flux2-kustomize-helm-example

```sh

export GITHUB_TOKEN=<gh-token>

flux bootstrap github --owner=miguelsilva5989 --repository=homelab --path=clusters/zion --personal --token-auth



# kubectl apply -k ./infrastructure/controllers/zion
# kubectl -n traefik apply -k ./infrastructure/controllers/zion


```
