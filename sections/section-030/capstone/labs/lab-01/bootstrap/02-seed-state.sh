#!/usr/bin/env bash
# Creates the starting state for ats-088-capstone-030.
#
# Adds the inventory realm as a ConfigMap that nothing mounts, then replaces the
# healthy Deployment with one copied from a laptop test: development mode,
# dev-file, and KC_HEALTH_ENABLED removed. With health off, Keycloak closes the
# management port 9000, so every probe fails and the pod never becomes ready.
#
# The corrected Deployment is NOT applied here - producing it is the task.
set -euo pipefail

NAMESPACE="runcapstone-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Adding the inventory realm file as a ConfigMap..."
kubectl apply -f "$MANIFESTS/configmap-inventory-realm.yaml"

echo "[lab] Applying the Deployment copied from a laptop test..."
kubectl apply -f "$MANIFESTS/deployment-keycloak-broken.yaml"

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] Keycloak never becomes ready and has no inventory realm. Diagnosing that is the task."
