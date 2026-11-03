#!/usr/bin/env bash
# PASS when the newest log lines are JSON objects.
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

LINES="$(kubectl -n "$NAMESPACE" logs deploy/keycloak --tail=5 2>/dev/null)"
if [ -z "$LINES" ]; then
  echo "FAIL: the pod has no log lines yet."
  exit 1
fi
if echo "$LINES" | grep -qv '^{'; then
  echo "FAIL: some of the newest log lines are not JSON objects. Set KC_LOG_CONSOLE_OUTPUT=json and wait for the new pod."
  exit 1
fi
echo "PASS: the newest log lines are JSON objects."
exit 0
