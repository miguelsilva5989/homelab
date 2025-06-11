# Cert Manager

check if issuer is working for a particular app

```sh
kubectl get certificaterequest -A

kubectl describe certificaterequest -n test-app zion-test-app-ingressroute-certificate-1

kubectl get order -n test-app

kubectl describe order -n test-app zion-test-app-ingressroute-certificate-1-2213349728

kubectl get certificates.cert-manager.io -n test-app
```
