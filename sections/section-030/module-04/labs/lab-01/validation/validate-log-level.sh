#!/usr/bin/env bash
# PASS when KC_LOG_LEVEL has the right root level and category.
set -uo pipefail

NAMESPACE="ops-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

LEVEL="$(kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="KC_LOG_LEVEL")].value}' 2>/dev/null)"
if [ -z "$LEVEL" ]; then
  echo "FAIL: KC_LOG_LEVEL is not set on the Deployment."
  exit 1
fi
case "$LEVEL" in
  info,*|info) ;;
  *) echo "FAIL: KC_LOG_LEVEL is '$LEVEL', expected the root level to be info."; exit 1 ;;
esac
if ! echo ",$LEVEL," | grep -q ',org.keycloak.events:debug,'; then
  echo "FAIL: KC_LOG_LEVEL is '$LEVEL', expected it to contain org.keycloak.events:debug."
  exit 1
fi
HEALTH="$(kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="KC_HEALTH_ENABLED")].value}' 2>/dev/null)"
if [ "$HEALTH" != "true" ]; then
  echo "FAIL: KC_HEALTH_ENABLED must stay true."
  exit 1
fi
echo "PASS: the root level is info, org.keycloak.events logs at debug and health stays on."
exit 0
