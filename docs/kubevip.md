
# KubeVip

## DaemonSet

On the master server 10.69.5.1

```sh
sudo su

export VIP=10.69.69.1 # this is not the IP of the master node :) this is the IP for the kube vip control plane

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

## cloud provider

```sh
kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml

kubectl create configmap --namespace kube-system kubevip --from-literal range-global=10.69.250.1-10.69.255.254 --dry-run=client -o yaml | kubectl apply -f -
```
