

kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml

kubectl create configmap --namespace kube-system kubevip --from-literal range-global=10.69.69.1-10.69.69.254 --dry-run=client -o yaml | kubectl apply -f -

