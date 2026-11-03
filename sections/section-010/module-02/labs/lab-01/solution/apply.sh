#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="authcode-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-web --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s 'redirectUris=["https://inventory.example.test/callback"]' \
  -s 'webOrigins=["https://inventory.example.test"]'
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s 'attributes."pkce.code.challenge.method"=S256' \
  -s directAccessGrantsEnabled=false
