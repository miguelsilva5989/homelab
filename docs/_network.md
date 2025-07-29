needed to fix because of DNS

kubectl -n kube-system edit configmap coredns

# Add or fix this line:
    forward . 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1


    restart coredns

kubectl -n kube-system rollout restart deployment/coredns



still add problems from sonarr. to solve

How to fix:
Option 1: Force fully qualified domain names (FQDN) with trailing dot in configuration
Wherever you specify external URLs (like in Sonarr, Prowlarr configs), add a trailing dot to force FQDN:

https://skyhook.sonarr.tv.

This tells the resolver: do not append search suffixes.

Option 2: Reduce ndots in pod DNS config (less preferred)
Lower ndots to 1 or 2 in /etc/resolv.conf to make queries treat names as FQDN sooner.
This requires pod spec DNS config changes:
yaml

spec:
  dnsConfig:
    options:
      - name: ndots
        value: "1"
    
Add above to your pod/Deployment spec for Sonarr and Prowlarr, then redeploy.
