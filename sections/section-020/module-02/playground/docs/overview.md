# Overview: Administer Keycloak With The Consoles And The Admin REST API (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with one user and one client, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`adminapi-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode (`start-dev`), behind the Service `keycloak` on port `8080` (`http`) and `9000` (`management`) |
  | `tester` | Client pod with `curl` and `jq`; send test requests from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password`, with email, first name and last name set |
  | client `inventory-auditor` | Confidential client with a service account and the client secret `inventory-auditor-secret`. It has no administration roles yet |
  | client `inventory-cli` | Public client with direct access grants on, so it can sign `alice` in from a terminal |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n adminapi-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal. They need `jq` on your machine.

`kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `get_admin_token` prints an access token of the `master` administrator. `get_auditor_token` prints an access token of the service account of `inventory-auditor`. `call_admin_api` sends a request to the Admin REST API from the `tester` pod: the first argument is the token, the second the HTTP method, the third the path after `/admin/realms/`, and the fourth an optional JSON body.

```sh
NAMESPACE=adminapi-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_admin_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/master/protocol/openid-connect/token \
      -d grant_type=password -d client_id=admin-cli \
      -d username=admin -d password=admin | jq -r .access_token
}
get_auditor_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=client_credentials -d client_id=inventory-auditor \
      -d client_secret=inventory-auditor-secret | jq -r .access_token
}
call_admin_api() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' -X "$2" \
      -H "Authorization: Bearer $1" -H 'Content-Type: application/json' \
      ${4:+-d "$4"} "http://keycloak:8080/admin/realms/$3"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Use them like this: `call_admin_api "$(get_admin_token)" GET inventory/users`, `kcadm get users -r inventory --fields username`.

## Practice tasks

- Forward the Service with `kubectl -n adminapi-demo port-forward svc/keycloak 8080:8080`, open `http://localhost:8080/admin`, sign in as `admin` and find the realm `inventory`. Then open `http://localhost:8080/realms/inventory/account` and sign in as `alice`.
- Call `call_admin_api "$(get_auditor_token)" GET inventory/users` before the auditor has any role and read the status code.
- Give the auditor the role `view-users` with `kcadm add-roles`, and repeat the call. Then try `POST inventory/users` with the body `{"username":"probe-user"}` and read the status.
- Call the API with the string `invalid` as the token and compare the status with the call that has a valid token but no role.
- Turn on user events and admin events for `inventory`, create a user, and find both events with `kcadm get events` and `kcadm get admin-events`.
- Send a wrong password for `alice` through `inventory-cli` and find the `LOGIN_ERROR` event.
