#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="realmscapstone-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}

kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

# 1. Enable the existing realm; do not recreate it.
kcadm update realms/inventory -s enabled=true

# 2. Create the client and the user in the application realm.
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password

# 3. Remove the application's objects from master.
CLIENT_ID="$(kcadm get clients -r master -q clientId=inventory-cli --fields id --format csv --noquotes)"
kcadm delete "clients/$CLIENT_ID" -r master
USER_ID="$(kcadm get users -r master -q username=alice -q exact=true --fields id --format csv --noquotes)"
kcadm delete "users/$USER_ID" -r master
