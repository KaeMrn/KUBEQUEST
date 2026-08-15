# App GitOps repo (Kustomize)

Deploys `../helm-chart` (the real app, from `app/src`) and the official
Bitnami `mysql` chart (standalone — matches `app/src/docker-compose.yaml`'s
single `db: mysql:8.0` service, no replication) together, via Kustomize's
`helmCharts` inflator — `helm` must be on `PATH` for `kubectl apply -k` /
`kustomize build --enable-helm` to work.

## Layout
- `base/` — namespace, both Helm charts (app + mysql), the backup CronJob,
  and the `app-deployer` RBAC Role/RoleBinding/ServiceAccount.
- `mysql-values.yaml` — shared DB config (persistence, resource limits).
- `overlays/staging/` — 1 app replica, relaxed HPA bounds, `app-staging`
  namespace, `staging.app.kubequest.local` host.
- `overlays/production/` — namespace `app-production`, bigger resource
  limits, HPA floor of 3, TLS via cert-manager (`app.kubequest.io` —
  **placeholder domain, swap for one you actually control** before this
  will issue a real Let's Encrypt cert).
- `backup/` — daily `mysqldump` CronJob + its own PVC.

## Before deploying
1. Build and push the real image: `../../scripts/build-and-push-app-image.sh
   <registry>/<repo> <tag>`, then set `image.repository`/`image.tag` in
   `../helm-chart/values.yaml`.
2. Generate secrets (never committed — see below).

## Secrets

    ../../scripts/generate-app-secrets.sh app-staging      # matches overlays/staging's namespace
    ../../scripts/generate-app-secrets.sh app-production   # matches overlays/production's namespace

Creates `mysql-auth` (root/app-user passwords) and `app-db-credentials`
(`APP_KEY` + `DB_PASSWORD`, same password as `mysql-auth`'s `mysql-password`)
in the target namespace, consumed by `mysql-values.yaml` and the app chart
respectively.

## Deploy

    kubectl apply -k app/gitops/overlays/staging
    kubectl -n app-staging rollout status statefulset/kubequest-db-mysql
    kubectl -n app-staging wait --for=condition=complete job -l app.kubernetes.io/component=migration
    kubectl -n app-staging rollout status deployment/kubequest-app

(`scripts/deploy-all.sh` runs all of this, in this order, automatically.)

## Why migrations aren't a Helm hook
`../helm-chart/templates/migrate-job.yaml` runs `php artisan migrate --force`
as a plain Job, not a `helm.sh/hook`-annotated one. This whole chart is
rendered via `helm template` (Kustomize's `helmCharts` inflator), which does
not execute Helm's install/upgrade lifecycle — hook annotations would be
inert. Real ordering is explicit: `scripts/deploy-all.sh` applies everything,
waits for MySQL, waits for the migration Job to complete, then waits for the
app Deployment.
