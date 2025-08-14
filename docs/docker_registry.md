# Registry

to pull images from the self hosted docker registry

https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

```sh
docker login https://registry.milanchis.com

cat ~/.docker/config.json

kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  --dry-run=client -o yaml > /home/mike/git/homelab/apps/base/docker-registry/registry-secret.yaml

kubeseal --format yaml --scope cluster-wide --cert ~/git/pub-cert.pem < /home/mike/git/homelab/apps/base/docker-registry/registry-secret.yaml > /home/mike/git/homelab/apps/base/docker-registry/registry-sealedsecret.yaml
```

now can be used in 

imagePullSecrets:
- name: zion-regcred


