# Flatproof

Next.js proofing SaaS deployed at `flatproof.app`.

## Image

```sh
docker build -t registry.milanchis.com/flatproof:latest .
docker push registry.milanchis.com/flatproof:latest
```

## Required Secrets

Create a `flatproof-secret` sealed secret in the `flatproof` namespace. The zion overlay applies the `zion-`
name prefix, so the deployment reads `zion-flatproof-secret`.

Use `template.secret.yaml` as the key list only. Do not commit plaintext secret values.

The namespace also needs a registry pull secret named `zion-regcred`. Generate a namespace-scoped sealed secret
for `flatproof` before enabling the overlay if the registry requires auth.
