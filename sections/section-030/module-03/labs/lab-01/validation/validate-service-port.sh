#!/usr/bin/env bash
# PASS when the Service port exists and the Deployment is available.
set -uo pipefail

NAMESPACE="edge-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

PORTS="$(kubectl -n "$NAMESPACE" get svc keycloak -o jsonpath='{range .spec.ports[*]}{.name}:{.port}{"\n"}{end}' 2>/dev/null)"
if ! echo "$PORTS" | grep -qxF 'https:8443'; then
  echo "FAIL: the Service keycloak has no port 8443 named https."
  exit 1
fi
AVAILABLE="$(kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "${AVAILABLE:-0}" -lt 1 ]; then
  echo "FAIL: the Deployment keycloak has no available replica."
  exit 1
fi
echo "PASS: the Service exposes https:8443 and the Deployment is available."
exit 0
