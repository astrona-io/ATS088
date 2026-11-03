# Solution: Give An Auditor Read-Only Access To Users

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: a token of `inventory-auditor` can list users, the same token cannot create a user, and the service account holds `view-users` without `manage-users` or `realm-admin`.

## Step 1: Reproduce the failure

Request a token with the client credentials grant and call the user list. The helper keeps the token in a variable:

```sh
NAMESPACE=adminapi-demo
TOKEN=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-auditor \
    -d client_secret=inventory-auditor-secret | jq -r .access_token)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' \
  -H "Authorization: Bearer $TOKEN" http://keycloak:8080/admin/realms/inventory/users
```

The status is `403`. The token is valid, so Keycloak knows who calls, but the service account has no administration role. A `401` would mean the token itself was missing or invalid.

## Step 2: Find the role

Sign in with `kcadm.sh` and list the roles of the client `realm-management`. This client holds the administration roles of the realm:

```sh
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get-roles -r inventory --cclientid realm-management --fields name
```

The list has `view-users`, `manage-users`, `view-clients`, `realm-admin` and others. `view-users` lets a caller read users and groups. `manage-users` also creates and changes them, and `realm-admin` allows everything in the realm.

## Step 3: Assign the role to the service account

The service account user is named `service-account-` plus the client ID:

```sh
kcadm add-roles -r inventory --uusername service-account-inventory-auditor \
  --cclientid realm-management --rolename view-users
```

In the Admin Console, the same step is on the client's **Service accounts roles** tab, with **Assign role** and the filter **Filter by clients**.

## Step 4: Prove the read and the refusal

Request a new token, because roles are copied into a token when it is issued, and repeat the call. Then try to create a user:

```sh
TOKEN=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-auditor \
    -d client_secret=inventory-auditor-secret | jq -r .access_token)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' \
  -H "Authorization: Bearer $TOKEN" http://keycloak:8080/admin/realms/inventory/users
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' -X POST \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"username":"probe-user"}' http://keycloak:8080/admin/realms/inventory/users
```

The first status is `200` and the second is `403`. The service account can read users, and Keycloak refuses to create one.

## Step 5: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Assign `realm-admin` | The list call works, but so does everything else; the grader rejects it |
| Assign `manage-users` | The auditor could change users, and the `POST` check fails |
| Use the `master` administrator in the audit tool | The tool gets full control of every realm |
| Test with the old token | A token keeps the roles it had when it was issued, so the result looks unchanged |

## Common mistakes

- Testing with a token requested before the role was assigned.
- Reading `403` as a wrong secret. A wrong secret gives an error at the token endpoint, not a `403` at the API.
- Assigning a realm role instead of a client role of `realm-management`.
- Adding the role to the client instead of its service account user.

## Practice on your own

- Add `view-clients` and call `GET /admin/realms/inventory/clients` with a fresh token.
- Remove `view-users` with `kcadm remove-roles` and check that the status returns to `403`.
- Decode the token and find the role under `resource_access`.
