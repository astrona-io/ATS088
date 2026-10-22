#!/usr/bin/env bash
# PASS when the Keycloak Deployment is fully rolled out and /health/ready on the
# management port answers UP to the tester pod.
set -uo pipefail

NS="image-demo"
READY="$(kubectl -n "$NS" get deployment keycloak -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
UPDATED="$(kubectl -n "$NS" get deployment keycloak -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)"
if [ "${READY:-0}" -lt 1 ] || [ "${UPDATED:-0}" -lt 1 ]; then
  echo "FAIL: deployment/keycloak has no ready pod from its current template (ready=${READY:-0}, updated=${UPDATED:-0})."
  exit 1
fi

STATUS="$(kubectl -n "$NS" exec deploy/tester -- \
  curl -s --max-time 10 http://keycloak:9000/health/ready 2>/dev/null)"
if ! printf '%s' "$STATUS" | grep -q '"UP"'; then
  echo "FAIL: http://keycloak:9000/health/ready did not answer UP. Got: ${STATUS:-no response}"
  exit 1
fi

echo "PASS: Keycloak is ready and /health/ready answers UP."
exit 0
