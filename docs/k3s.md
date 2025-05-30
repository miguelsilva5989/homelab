# K3S

## install

```sh
curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN sh -s - --disable traefik --cluster-init --tls-san=10.69.69.1 --tls-san=milanchis.com --tls-san=0.0.0.0 --node-taint --write-kubeconfig-mode 640 --write-kubeconfig-group sudo
```

Added --node-taint to not have pods running on master nodes

## second server

```sh
curl -sfL https://get.k3s.io | K3S_TOKEN=K3S_TOKEN sh -s - server \
    --server https://10.69.69.1:6443 \
    --tls-san=10.69.69.1 # Optional, needed if using a fixed registration address
```

```sh
k get nodes
```

## agent

```sh
curl -sfL https://get.k3s.io | K3S_URL=https://10.69.1.1:6443 K3S_TOKEN=$K3S_TOKEN sh -s -  --write-kubeconfig-mode 640 --write-kubeconfig-group sudo

# this worked to launch agent
sudo k3s agent --server https://192.168.69.13:6443 --token $K3S_TOKEN
```

## TRaefik

Install

```sh
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --namespace traefik --create-namespace --values traefik-values.yaml 
```

Helm Values - this will redirect all traffic to https, even local one. To test locally disable this by only using `ports: web: {}` and `helm upgrade`

    helm upgrade traefik traefik/traefik --namespace traefik --create-namespace --values traefik-values.yaml
---

```yaml
ports:
    web:
        redirections:
            entryPoint:
                to: websecure
                scheme: https
                permanent: true

```

Service example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
name: whoami
labels:
    app: whoami
spec:
replicas: 1
selector:
    matchLabels:
    app: whoami
template:
    metadata:
    labels:
        app: whoami
    spec:
    containers:
    - name: whoami
        image: containous/whoami
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
name: whoami
spec:
selector:
    app: whoami
ports:
    - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
name: whoami-ingress  
spec:
entryPoints:
- websecure
routes:
- match: Host(`whoami.local`)
    kind: Rule
    services:
    - name: whoami
    port: 80
#apiVersion: networking.k8s.io/v1
#kind: Ingress
#metadata:
#name: whoami-ingress
#annotations:
#    traefik.ingress.kubernetes.io/router.entrypoints: websecure
#spec:
#ingressClassName: traefik
#rules:
#- host: whoami.local
#    http:
#    paths:
#    - path: /
#        pathType: Prefix
#        backend:
#        service:
#            name: whoami
#            port:
#            number: 80
```
