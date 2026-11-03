#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-030-04.
# Nothing to seed: Keycloak starts with health checks only. Metrics and JSON logs are the task.
set -euo pipefail

NAMESPACE="ops-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[lab] Starting state ready. Keycloak serves health checks only, with text logs."
