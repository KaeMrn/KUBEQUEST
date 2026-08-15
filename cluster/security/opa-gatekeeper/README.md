# OPA Gatekeeper — validating admission webhook

## What is it
Gatekeeper is a Kubernetes-native policy engine built on Open Policy Agent (OPA).
It registers a `ValidatingWebhookConfiguration` that intercepts every resource
creation/update on the API server and can reject it based on Rego policy.

## Why we need it
Satisfies the project's "add a validating webhook that can validate and
control requests" requirement, and enforces two of the "best practices"
requirements automatically instead of relying on humans remembering them:
- every Deployment/StatefulSet/DaemonSet must declare CPU/memory requests
  and limits (`K8sRequiredResources`)
- every Deployment/StatefulSet/DaemonSet must carry `app.kubernetes.io/name`
  and `app.kubernetes.io/part-of` labels (`K8sRequiredLabels`)

## Installation
Two-step, because the ConstraintTemplate/Constraint CRDs don't exist until
Gatekeeper itself is up:

    kubectl apply -k cluster/security/opa-gatekeeper
    kubectl wait --for=condition=Available deployment/gatekeeper-controller-manager \
      -n gatekeeper-system --timeout=120s
    kubectl apply -k cluster/security/opa-gatekeeper/policies

(`scripts/deploy-all.sh` does this automatically, in order.)

## Verify
    kubectl get pods -n gatekeeper-system
    kubectl get constrainttemplates
    kubectl get k8srequiredresources,k8srequiredlabels

## Demo: watch it reject a bad manifest
    kubectl create deployment no-limits --image=nginx --dry-run=client -o yaml \
      | kubectl apply -f -
    # -> denied by k8srequiredresources: "container <nginx> is missing spec.resources.requests.cpu"
