#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="protocols-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-reporter --fields id --format csv --noquotes | tr -d '\r')

# Make the client confidential with a service account. Keep every other grant off.
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s publicClient=false -s clientAuthenticatorType=client-secret \
  -s serviceAccountsEnabled=true \
  -s directAccessGrantsEnabled=false -s standardFlowEnabled=false

# Generate a client secret and read it back.
kcadm create "clients/$CLIENT_ID/client-secret" -r inventory >/dev/null
CLIENT_SECRET=$(kcadm get "clients/$CLIENT_ID/client-secret" -r inventory --fields value --format csv --noquotes | tr -d '\r')

kubectl -n "$NAMESPACE" create secret generic inventory-reporter-credentials \
  --from-literal=client-secret="$CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -
