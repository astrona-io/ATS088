#!/usr/bin/env bash
# PASS when the auditor cannot create users.
set -uo pipefail

NAMESPACE="adminapi-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

TOKEN="$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-auditor \
    -d client_secret=inventory-auditor-secret 2>/dev/null | jq -r .access_token 2>/dev/null)"
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "FAIL: could not get a token for inventory-auditor with the secret inventory-auditor-secret."
  exit 1
fi
api_status() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}' -X "$1" \
    -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
    ${2:+-d "$2"} http://keycloak:8080/admin/realms/inventory/users 2>/dev/null
}
STATUS="$(api_status POST '{"username":"probe-user"}')"
if [ "$STATUS" != "403" ]; then
  echo "FAIL: POST /admin/realms/inventory/users returned $STATUS for inventory-auditor, expected 403."
  exit 1
fi
echo "PASS: inventory-auditor cannot create users."
exit 0
