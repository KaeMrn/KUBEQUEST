# kubequest-app Helm chart

Converts the docker-compose application provided on Gandalf into a
deployable Helm chart: Deployment (2 replicas, anti-affinity, rolling
update with `maxUnavailable: 0` for zero-downtime), Service, Ingress, HPA,
ConfigMap, PodDisruptionBudget, dedicated ServiceAccount.

## Known gap — read before using this for the actual defense

`values.yaml` currently points at `nginxdemos/hello` as a stand-in image and
has no idea what environment variables the real app needs. **The actual
docker-compose.yml from Gandalf was never provided to generate this chart**,
so this is a structurally-complete but content-generic chart.

To finish this:
1. Pull `docker-compose.yml` from Gandalf.
2. For each service in it that isn't the database, replace `image.repository`/
   `tag` in `values.yaml`, add its env vars to `config` (non-secret) or wire
   them through `secretName` (secret), and set `containerPort` to match
   `EXPOSE`/`ports:` in the compose file.
3. If the compose file defines more than one non-DB service, this chart
   needs to become an umbrella chart (one subchart per service) rather than
   a single Deployment — ask before assuming a single-container shape.
4. Re-check `probes.readiness/liveness` paths against whatever health
   endpoint (if any) the real app exposes; `/` is a guess.

## Install standalone (for testing before wiring into GitOps)

    helm install kubequest-app . -f values.yaml --namespace app --create-namespace

In practice this chart is deployed via `../gitops` (Kustomize + `helmCharts`),
not `helm install` directly — see that folder's README.
