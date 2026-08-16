# Authentication — Dex + oauth2-proxy

## What is it
- **Dex**: OIDC identity provider. Configured here with a static-password
  connector for local testing — swap for a real connector (GitHub org,
  Google Workspace, SAML) before relying on this beyond that.
- **oauth2-proxy**: sits in front of the Kubernetes Dashboard and Grafana,
  redirecting unauthenticated requests to Dex and only forwarding the
  request to the upstream once a valid OIDC session exists.

## Why we need it
Satisfies "add authentication to your Kubernetes API and your different
tools" — neither the dashboard nor Grafana are reachable without first
authenticating through Dex. The Kubernetes API itself is still protected by
kubeadm's default cert-based auth + the RBAC in `../rbac` (least-privilege
ServiceAccounts, not a webhook auth proxy in front of the API server itself,
which would be unusual for a kubeadm cluster).

## Installation
1. Generate secrets (never commit these — see `secret-template.yaml` for the shape):

   ```bash
   ./generate-secrets.sh                 # random demo password
   ./generate-secrets.sh my-own-password # or pick one
   ```

2. Apply:

   ```bash
   kubectl apply -k cluster/security/auth
   ```

## Access
Browse to `https://kubequest.local/dashboard` or `https://kubequest.local/grafana`
(add `kubequest.local` to `/etc/hosts` pointing at the ingress node's public IP).
Log in with the email/password printed by `generate-secrets.sh`.

## Verify
    kubectl -n auth get pods
    kubectl -n auth logs deploy/dex
    kubectl -n auth logs deploy/oauth2-proxy
