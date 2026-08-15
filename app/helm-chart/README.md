# kubequest-app Helm chart

Deploys the real app from `app/src` — a Laravel 8 "counter" demo (PHP
8.2.8-apache, `GET /` renders a view summing a `counters` table, `GET
/api/counter/add` and `GET /api/counter/count` are the JSON API, per
`app/src/routes/web.php` and `app/src/routes/api.php`).

Resources: Deployment (2 replicas, anti-affinity, rolling update with
`maxUnavailable: 0` for zero-downtime), Service, Ingress, HPA, ConfigMap,
PodDisruptionBudget, a migration Job, and a dedicated ServiceAccount.

## Before deploying — build and push the image

The chart doesn't build the image; it just references one. Build it from
the real Dockerfile (linux/amd64, matching the EC2 nodes) and load it
onto the cluster — no public registry required:

    scripts/build-and-push-app-image.sh kubequest-app v1 --local
    scripts/load-app-image-to-nodes.sh kubequest-app:v1

`values.yaml` already points at `kubequest-app:v1`. If you do have a
registry, omit `--local` and set `image.repository`/`image.tag` to match.

## Database migrations

`app/src` needs `php artisan migrate` run against the DB before the app
works (empty `counters`/`users` tables otherwise → `/` and the API 500).
`templates/migrate-job.yaml` runs it as a Kubernetes Job — **not** a Helm
lifecycle hook, since this chart is rendered via `helm template` under
Kustomize (`app/gitops/base`), which doesn't execute Helm's install/upgrade
hook ordering. `scripts/deploy-all.sh` applies the manifests then explicitly
waits on this Job (`kubectl wait --for=condition=complete`) before treating
the deploy as done.

## Database

Real app requires MySQL (`app/src/docker-compose.yaml`'s `db` service,
`mysql:8.0`) — **not** PostgreSQL. `../gitops` deploys the official
`bitnami/mysql` chart for this reason, referenced by `DB_HOST` in
`values.yaml`'s `config` block.

## Install standalone (for testing before wiring into GitOps)

    helm install kubequest-app . -f values.yaml --namespace app --create-namespace \
      --set image.repository=<registry>/<repo> --set image.tag=<tag>

In practice this chart is deployed via `../gitops` (Kustomize + `helmCharts`),
not `helm install` directly — see that folder's README.
