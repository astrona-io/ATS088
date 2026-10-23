#!/usr/bin/env bash
# PASS when the administrator admin still exists in master and can sign in
# with its password through the built-in admin-cli client.
set -uo pipefail

NS="realmscapstone-demo"

# admin-cli issues lightweight access tokens in Keycloak 26.8.1 (the client
# attribute client.use.lightweight.access.token.enabled is true): the token has
# no sub or preferred_username. The password grant only succeeds for an enabled
# user with the right password, so a token issued for admin is the proof.
TOKEN="$(kubectl -n "$NS" exec -i deploy/tester -- curl -s \
  -d grant_type=password -d client_id=admin-cli \
  -d username=admin -d password=admin \
  http://keycloak:8080/realms/master/protocol/openid-connect/token 2>/dev/null \
  | jq -r '.access_token // empty' 2>/dev/null)"

if [ -z "$TOKEN" ]; then
  echo "FAIL: the administrator admin can no longer sign in to master with its password. Leave the admin user untouched."
  exit 1
fi

echo "PASS: the administrator admin still signs in to master."
exit 0
