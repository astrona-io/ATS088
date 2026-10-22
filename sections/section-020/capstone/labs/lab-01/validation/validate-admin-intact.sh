#!/usr/bin/env bash
# PASS when the administrator admin still exists in master and can sign in
# with its password through the built-in admin-cli client.
set -uo pipefail

NS="realmscapstone-demo"

USERNAME="$(kubectl -n "$NS" exec -i deploy/tester -- sh -s 2>/dev/null <<'SCRIPT'
token=$(curl -s -d grant_type=password -d client_id=admin-cli \
  -d username=admin -d password=admin \
  http://keycloak:8080/realms/master/protocol/openid-connect/token \
  | jq -r '.access_token // empty' 2>/dev/null)
[ -z "$token" ] && exit 0
printf '%s' "$token" | jq -R -r 'split(".")[1] | gsub("-";"+") | gsub("_";"/")
  | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | .preferred_username'
SCRIPT
)"

if [ "$USERNAME" != "admin" ]; then
  echo "FAIL: the administrator admin can no longer sign in to master with its password. Leave the admin user untouched."
  exit 1
fi

echo "PASS: the administrator admin still signs in to master."
exit 0
