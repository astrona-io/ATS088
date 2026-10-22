#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# `astrona test` bootstraps and applies in one go. Keycloak can report ready on
# /health/ready a few seconds before the bootstrap administrator can sign in,
# and a kcadm.sh call in that window fails with an error that looks like a
# wrong password. Wait until the administrator signs in.
set -eu

NAMESPACE="realmscapstone-demo"

kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s

for _ in $(seq 1 60); do
  if kubectl -n "$NAMESPACE" exec deploy/keycloak -- \
       /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
       --realm master --user admin --password admin --config /tmp/wait-kcadm.config \
       >/dev/null 2>&1; then
    exit 0
  fi
  sleep 3
done
echo "Keycloak administrator could not sign in in time." >&2
exit 1
