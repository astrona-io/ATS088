#!/usr/bin/env bash
# PASS when master holds no client inventory-cli and no user alice, and a
# password grant against master through inventory-cli is refused.
set -uo pipefail

NS="realmscapstone-demo"
kcadm() {
  kubectl -n "$NS" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/grader-kcadm.config
}

if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: the grader could not sign in to master as admin."
  exit 1
fi

CLIENT="$(kcadm get clients -r master -q clientId=inventory-cli --fields clientId --format csv --noquotes 2>/dev/null | tr -d '[:space:]')"
if [ -n "$CLIENT" ]; then
  echo "FAIL: the master realm still holds the client inventory-cli."
  exit 1
fi

FOUND_USER="$(kcadm get users -r master -q username=alice -q exact=true --fields username --format csv --noquotes 2>/dev/null | tr -d '[:space:]')"
if [ -n "$FOUND_USER" ]; then
  echo "FAIL: the master realm still holds the user alice."
  exit 1
fi

TOKEN="$(kubectl -n "$NS" exec deploy/tester -- sh -c \
  'curl -s -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=alice-password http://keycloak:8080/realms/master/protocol/openid-connect/token | jq -r ".access_token // empty"' 2>/dev/null)"
if [ -n "$TOKEN" ]; then
  echo "FAIL: master still issues a token for alice through inventory-cli."
  exit 1
fi

echo "PASS: master holds no application client or user, and refuses the application's token request."
exit 0
