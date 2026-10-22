#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# The lab starts with a Keycloak Deployment that is broken on purpose, so this
# does not wait for Keycloak to be ready. It waits for everything the reference
# solution depends on: the tester pod and PostgreSQL.
set -eu

NAMESPACE="runcapstone-demo"
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/postgres --timeout=300s
kubectl -n "$NAMESPACE" get deployment keycloak >/dev/null
