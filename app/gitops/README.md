# App GitOps repo (Kustomize)

Deploys `../helm-chart` (the converted app) and the official Bitnami
`postgresql` chart (replication mode: 1 primary + 2 read replicas, per
bootstrap.pdf's "add 2 slaves") together, via Kustomize's `helmCharts`
inflator — `helm` must be on `PATH` for `kubectl apply -k` /
`kustomize build --enable-helm` to work.

## Layout
- `base/` — namespace, both Helm charts (app + postgresql), the backup
  CronJob, and the `app-deployer` RBAC Role/RoleBinding/ServiceAccount.
- `postgresql-values.yaml` — shared DB config (persistence, replication,
  resource limits, max_connections/statement_timeout).
- `overlays/staging/` — 1 app replica, relaxed HPA bounds, `app-staging`
  namespace, `staging.app.kubequest.local` host.
- `overlays/production/` — namespace `app-production`, bigger resource
  limits, HPA floor of 3, TLS via cert-manager (`app.kubequest.io` —
  **placeholder domain, swap for one you actually control** before this
  will issue a real Let's Encrypt cert).
- `backup/` — daily `pg_dump` CronJob + its own PVC.

## Secrets
Never committed. Run once per environment before deploying:

    ./../../scripts/generate-app-secrets.sh app             # for base/staging testing
    ./../../scripts/generate-app-secrets.sh app-staging      # matches overlays/staging's namespace
    ./../../scripts/generate-app-secrets.sh app-production   # matches overlays/production's namespace

This creates `postgresql-auth` (DB admin/user/replication passwords) and
`app-db-credentials` (a `DATABASE_URL` built from the same password) in the
target namespace, consumed by `postgresql-values.yaml` and the app chart
respectively.

## Deploy

    kubectl apply -k app/gitops/overlays/staging
    kubectl -n app-staging rollout status deployment/kubequest-app
    kubectl -n app-staging rollout status statefulset/kubequest-db-postgresql-primary

(`scripts/deploy-all.sh` runs this in the right order automatically.)

## Known gap
The app chart itself is still generic (see `../helm-chart/README.md`) — the
real docker-compose app from Gandalf was never supplied, so this whole
GitOps repo is deploy-ready but content-generic until that's swapped in.
