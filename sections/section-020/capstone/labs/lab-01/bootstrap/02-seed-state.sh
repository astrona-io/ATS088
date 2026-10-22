#!/usr/bin/env bash
# Creates the starting state for ats-088-capstone-020.
#
# The application was started in the wrong place:
#   - the realm inventory exists, holds the realm role inventory-viewer, and is
#     disabled;
#   - the client inventory-cli and the user alice were created in master.
#
# The move to the inventory realm is NOT done here — doing it is the task.
set -euo pipefail

NAMESPACE="realmscapstone-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/seed-kcadm.config
}

signed_in=false
for _ in $(seq 1 30); do
  if kcadm config credentials --server http://localhost:8080 --realm master \
       --user admin --password admin >/dev/null 2>&1; then
    signed_in=true
    break
  fi
  sleep 5
done
if [ "$signed_in" != "true" ]; then
  echo "[lab] ERROR: the bootstrap administrator could not sign in to master." >&2
  exit 1
fi

echo "[lab] Creating the disabled inventory realm..."
kcadm create realms -s realm=inventory -s enabled=false -s displayName=Inventory
kcadm create roles -r inventory -s name=inventory-viewer \
  -s 'description=Read access to the inventory API; used by other teams'

echo "[lab] Creating the application client and user in master (the mistake)..."
kcadm create clients -r master -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create users -r master -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r master --username alice --new-password alice-password

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] The inventory application currently lives in master. Moving it is the task."
