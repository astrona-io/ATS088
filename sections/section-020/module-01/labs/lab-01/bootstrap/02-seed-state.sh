#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-020-01.
#
# The starting state is a fresh server: only the master realm and its
# bootstrap administrator. This script waits until the administrator can sign
# in and checks that no inventory realm exists yet.
#
# The realm, user and client are NOT created here — creating them is the task.
set -euo pipefail

NAMESPACE="realms-demo"

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

if kcadm get realms/inventory >/dev/null 2>&1; then
  echo "[lab] ERROR: the realm inventory already exists; the starting state is wrong." >&2
  exit 1
fi

echo "[lab] Starting state ready: only the master realm exists."
kubectl -n "$NAMESPACE" get pods
