#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-030-01.
#
# Replaces the healthy development-mode Deployment with one that runs `start`
# (production mode) and sets no hostname and no HTTP or TLS options. Keycloak
# exits during startup and the pod goes into CrashLoopBackOff.
#
# The corrected Deployment is NOT applied here - producing it is the task.
set -euo pipefail

NAMESPACE="image-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Switching Keycloak to production mode without its required settings..."
kubectl apply -f "$MANIFESTS/deployment-keycloak-broken.yaml"

# Recreate strategy: wait until the old development-mode pod is gone, so the
# only Keycloak pod left is the failing one.
for _ in $(seq 1 60); do
  RUNNING_DEV="$(kubectl -n "$NAMESPACE" get pods -l app=keycloak \
    -o jsonpath='{range .items[*]}{.spec.containers[0].args}{"\n"}{end}' | grep -c 'start-dev' || true)"
  [ "$RUNNING_DEV" = "0" ] && break
  sleep 2
done

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] Keycloak no longer starts. Diagnosing that is the task."
