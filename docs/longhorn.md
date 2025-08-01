# Longhorn

## Installation

CLI

https://longhorn.io/docs/1.9.0/deploy/install/#longhorn-command-line-tool

preflight check

    ./longhornctl check preflight --kube-config /etc/rancher/k3s/k3s.yaml
    ./longhornctl check preflight --kube-config ~/.kube/config

to install the missing dependencies

    ./longhornctl install preflight --kube-config /etc/rancher/k3s/k3s.yaml
    ./longhornctl install preflight --kube-config ~/.kube/config


