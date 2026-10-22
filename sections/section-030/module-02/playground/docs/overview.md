# Overview: Store Keycloak Data In PostgreSQL And Import A Realm (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, PostgreSQL and a client pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`database-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One pod of **Keycloak 26.8.1**, started with `start-dev`. It stores its data in the built-in `dev-file` database inside the pod. Service ports `8080` (HTTP) and `9000` (management) |
  | `postgres` | **PostgreSQL 17** (`postgres:17-alpine`) with the database `keycloak`, on port `5432`. Keycloak does not use it yet |
  | `tester` | Client pod with `curl` and `jq`; send test requests from here |

- Secret **`keycloak-admin`**: the first administrator of the `master` realm, user `admin`, password `admin`.
- Secret **`keycloak-db`**: the database user `keycloak` with the password `keycloak-db-password`, under the keys `username` and `password`. PostgreSQL created this user from the same Secret.
- ConfigMap **`inventory-realm`**: one key, `inventory-realm.json`, a realm file for the realm `inventory` with the user `alice` (password `alice-password`) and the public client `inventory-cli`. Nothing mounts it yet.
- All credentials here are lab-only. PostgreSQL keeps its data in an `emptyDir` volume: the data survives a restart of the Keycloak pod, but not the deletion of the `postgres` pod.

## Helpers

Paste these once in each new terminal. `list_realms` asks PostgreSQL which realms it stores. `get_token` asks the `inventory` realm for a token for `alice` with the password grant, which only a test client should allow. `show_claims` reads the token JSON on standard input and prints the claims of the access token.

```sh
list_realms() {
  kubectl -n database-demo exec deploy/postgres -- \
    psql -U keycloak -d keycloak -c 'select name from realm;'
}
get_token() {
  kubectl -n database-demo exec deploy/tester -- curl -s \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token
}
show_claims() {
  jq -r '.access_token | split(".")[1] | gsub("-";"+") | gsub("_";"/")
         | . + ("=" * ((4 - (length % 4)) % 4)) | @base64d | fromjson'
}
```

Use them like this: `list_realms`, `get_token | show_claims`.

## Practice tasks

- Run `list_realms` before you change anything, and explain the error: Keycloak has not created any tables in PostgreSQL yet.
- Create a test realm with the Admin Console or `kcadm.sh`, delete the Keycloak pod, and check whether the realm is still there. Then do the same after Keycloak uses PostgreSQL.
- Mount the `inventory-realm` ConfigMap at `/opt/keycloak/data/import`, add `--import-realm`, and run `get_token | show_claims`.
- Change the first name of `alice` in the ConfigMap, restart Keycloak, and check whether the change reached the server. Explain the result.
- Scale Keycloak to zero, export the `inventory` realm with a separate pod, and compare the exported file with the ConfigMap.
