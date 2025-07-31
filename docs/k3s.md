# K3S

## High Availability Cluster

An HA K3s cluster with embedded etcd is composed of:

- `Three` or more server nodes that will serve the Kubernetes API and run other control plane services, as well as host the embedded etcd datastore.
- Optional: Zero or more agent nodes that are designated to run your apps and services
- Optional: A fixed registration address for agent nodes to register with the cluster

## K3sup

check k3sup

https://www.youtube.com/watch?v=Yt_PWpn-97g

the nodes need to be added afterwards!

https://github.com/alexellis/k3sup

### Installation

```sh
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

k3sup --help
```

### Configuration

`10.69.69.1` will be our cluster virtual IP address used by kubevip for LB

```sh
ssh-copy-id mike@10.69.5.1
ssh-copy-id mike@10.69.5.2
ssh-copy-id mike@10.69.5.3
ssh-copy-id mike@10.69.5.11
ssh-copy-id mike@10.69.5.12

ssh-copy-id mike@10.69.6.13

# Master
k3sup install --ip 10.69.5.1 --tls-san=10.69.69.1 --cluster --user mike --local-path ~/.kube/config --context k3s-ha --k3s-extra-args '--disable servicelb --disable traefik --write-kubeconfig-mode 640 --write-kubeconfig-group sudo'
```

### Kubevip

Configure Kubevip by applying the RBAC manifest (Kubevip runs as a DaemonSet under k3s)

```sh
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
```

On the master node `ssh mike@10.69.5.1`

```sh
sudo su
export VIP=10.69.69.1 # this is not the IP of the master node. It's the TLS san we setup before :) this is the IP for the kube vip control plane
export INTERFACE=eth0
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
alias kube-vip="ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"

# sudo touch /var/lib/rancher/k3s/server/manifests/kube-vip.yaml
# sudo chown mike /var/lib/rancher/k3s/server/manifests/kube-vip.yaml

kube-vip manifest daemonset \
    --interface $INTERFACE \
    --address $VIP \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection | tee /var/lib/rancher/k3s/server/manifests/kube-vip.yaml
```

Back to the development machine, let's test the DaemonSet by pinging `10.69.69.1` and it should be reachable

```sh
ping 10.69.69.1
# PING 10.69.69.1 (10.69.69.1) 56(84) bytes of data.
# 64 bytes from 10.69.69.1: icmp_seq=1 ttl=63 time=0.412 ms
# 64 bytes from 10.69.69.1: icmp_seq=2 ttl=63 time=0.358 ms
kubectl get ds -A
# NAMESPACE     NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
# kube-system   kube-vip-ds   1         1         1       1            1           <none>          90s
```

Join the remaining control nodes

```sh
# 2nd Server
# notice servce-ip is the virtual IP
k3sup join --ip 10.69.5.2 --user mike --sudo --k3s-channel stable --server --server-ip 10.69.69.1 --server-user mike --sudo --k3s-extra-args '--node-ip=10.69.5.2 --disable servicelb --disable traefik --write-kubeconfig-mode 640 --write-kubeconfig-group sudo'
```

```sh
# 3rd Server
k3sup join --ip 10.69.5.3 --user mike --sudo --k3s-channel stable --server --server-ip 10.69.69.1 --server-user mike --sudo --k3s-extra-args '--node-ip=10.69.5.3 --disable servicelb --disable traefik --write-kubeconfig-mode 640 --write-kubeconfig-group sudo'
```

Check the nodes `kubectl get nodes`

Change the local kube config to point to the virtual IP

```sh
sed -i 's/10.69.5.1/10.69.69.1/' ~/.kube/config
kubectl get nodes # this should still work after the change
```

Join the agents

```sh
k3sup join --ip 10.69.5.11 --server-ip 10.69.69.1 --user mike
k3sup join --ip 10.69.5.12 --server-ip 10.69.69.1 --user mike
k3sup join --ip 10.69.6.13 --server-ip 10.69.69.1 --user root --server-user mike
```

Check the nodes `kubectl get nodes`

## Other development machines

If required when changing to another development machine, add this to dev server to connect directly to k3s clusters.
We just need to have `kubectl` installed.

On a master node

```cat /etc/rancher/k3s/k3s.yaml```

On the dev machine

```sh
KUBECONFIG=~/.kube/k3s.yaml
set -x KUBECONFIG ~/.kube/k3s.yaml # fish shell
vim $KUBECONFIG #paste the k3s config from the previous step
sed -i 's/127.0.0.1/10.69.69.1/' ~/.kube/k3s.yaml
```

## Traefik

Install

```sh
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --namespace traefik --create-namespace --values values.yaml 
```

Helm Values - this will redirect all traffic to https, even local one. To test locally disable this by only using `ports: web: {}` and `helm upgrade`

```sh
helm upgrade traefik traefik/traefik --namespace traefik --create-namespace --values values.yaml
```

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
