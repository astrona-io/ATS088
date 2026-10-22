#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="protocolscapstone-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
ALICE_ID=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')

# Fault 1: the client may not use the password grant.
kcadm update "clients/$CLI_ID" -r inventory -s directAccessGrantsEnabled=true

# Faults 2 and 3: the user is disabled and must change the password first.
kcadm update "users/$ALICE_ID" -r inventory -s enabled=true -s 'requiredActions=[]'
