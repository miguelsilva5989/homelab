needed to fix

kubectl -n kube-system edit configmap coredns

# Add or fix this line:
    forward . 8.8.8.8 8.8.4.4 1.1.1.1


    restart coredns

kubectl -n kube-system rollout restart deployment/coredns
