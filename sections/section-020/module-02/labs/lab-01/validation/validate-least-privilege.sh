#!/usr/bin/env bash
# PASS when the service account holds view-users only among the user roles.
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

ROLES="$(kcadm get-roles -r inventory --uusername service-account-inventory-auditor --cclientid realm-management --fields name 2>/dev/null)"
if ! echo "$ROLES" | grep -q 'view-users'; then
  echo "FAIL: the service account of inventory-auditor does not hold view-users."
  exit 1
fi
if echo "$ROLES" | grep -Eq 'manage-users|realm-admin'; then
  echo "FAIL: the service account holds manage-users or realm-admin. Remove it."
  exit 1
fi
echo "PASS: the service account holds view-users and nothing larger."
exit 0
