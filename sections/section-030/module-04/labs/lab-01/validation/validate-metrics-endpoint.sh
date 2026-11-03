#!/usr/bin/env bash
# PASS when /metrics returns 200 with jvm metrics.
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

STATUS="$(kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}' http://keycloak:9000/metrics 2>/dev/null)"
if [ "$STATUS" != "200" ]; then
  echo "FAIL: http://keycloak:9000/metrics returned $STATUS, expected 200."
  exit 1
fi
if ! kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s http://keycloak:9000/metrics 2>/dev/null | grep -q '^jvm_'; then
  echo "FAIL: /metrics answered but lists no jvm_ metrics."
  exit 1
fi
echo "PASS: /metrics returns 200 and lists JVM metrics."
exit 0
