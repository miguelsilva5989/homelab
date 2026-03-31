# RAID 9.3 (AIP 2.3) - k3s Deployment

RAID 9.3 deployed via official AIP Helm charts + kustomize for infrastructure.

## Architecture

```
xupa.milanchis.com
       |
   Traefik IngressRoute (TLS)
       |
       /                  -> Portal (3001)
       /keycloak           -> Keycloak (8080)
       /page-manager       -> Page Manager (40353)
       /rafm               -> RAFM (40353)
```

| Component | Deploy Method | Image |
|-----------|--------------|-------|
| PostgreSQL 16.13 | Kustomize StatefulSet | `postgres:16.13-alpine` |
| Keycloak 25.0.6 | Kustomize Deployment | `quay.io/keycloak/keycloak:25.0.6` |
| Page Manager 4.0.1 | Helm chart | `registry.milanchis.com/aip/page-manager:4.0.1` |
| Portal 8.0.1 | Helm chart | `registry.milanchis.com/aip/portal:8.0.1` |
| RAFM 8.0.1 | Helm chart | `registry.milanchis.com/aip/rafm:8.0.1` |

## Prerequisites

### Push AIP images to local registry

Port-forward the registry (Traefik has a body size limit):

```bash
kubectl -n registry port-forward svc/zion-registry 5000:80
docker login localhost:5000
```

Tag and push:

```bash
for img in aip/base:0.6.5 aip/page-manager:4.0.1 aip/portal:8.0.1 aip/rafm:8.0.1; do
  docker tag "$img" "localhost:5000/$img"
  docker push "localhost:5000/$img"
done
```

### Copy regcred secret to xupa namespace

```bash
kubectl get secret zion-regcred -n discordamus -o yaml \
  | sed 's/namespace: discordamus/namespace: xupa/' \
  | sed '/resourceVersion\|uid\|creationTimestamp\|selfLink\|ownerReferences/d' \
  | sed '/- apiVersion/,/^ *uid/d' \
  | kubectl apply -f -
```

## Deploy

### 1. Infrastructure (via FluxCD)

Commit and push the kustomize files. FluxCD applies them automatically, creating:
- Namespace `xupa`
- PostgreSQL StatefulSet + init SQL (keycloak DB, ras_* schemas, pm_* schemas)
- Keycloak Deployment + realm import
- Certificate + IngressRoute

### 2. License secret

```bash
kubectl -n xupa create secret generic xupa-license \
  --from-file=license.lic=<path-to>/license/license.lic
```

### 3. Helm charts (install order matters)

```bash
helm install page-manager helm/charts/page-manager-4.0.1.tgz \
  -n xupa -f helm/values-page-manager.yaml

helm install portal helm/charts/portal-8.0.1.tgz \
  -n xupa -f helm/values-portal.yaml

helm install rafm helm/charts/rafm-8.0.1.tgz \
  -n xupa -f helm/values-rafm.yaml
```

RAFM auto-registers itself in Page Manager (`performRegistration: true`).

## Verify

```bash
kubectl -n xupa get pods
kubectl -n xupa logs statefulset/rafm | grep -i registration
```

Then open `https://xupa.milanchis.com/` and login with `adm` / `Password1`.

Keycloak admin: `https://xupa.milanchis.com/keycloak/admin/` with `admin` / `admin`.

## Default credentials

| Component | User | Password |
|-----------|------|----------|
| RAID (Portal/RAFM) | adm | Password1 |
| RAID (internal) | internal | Password1 |
| Keycloak admin | admin | admin |
| PostgreSQL | raid | raid |

## File layout

```
xupa/
├── README.md
├── namespace.yaml
├── kustomization.yaml
├── db/
│   ├── statefulset.yaml
│   ├── service.yaml
│   ├── configmap.yaml          # init.xupa.sql
│   └── kustomization.yaml
├── keycloak/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml          # RAID_default_realm.json
│   └── kustomization.yaml
└── helm/
    ├── charts/*.tgz            # AIP Helm charts from aipctl pull
    ├── values-page-manager.yaml
    ├── values-portal.yaml
    └── values-rafm.yaml
```

## Cleanup

```bash
helm uninstall rafm portal page-manager -n xupa
kubectl delete -k apps/overlays/zion/xupa/
```
