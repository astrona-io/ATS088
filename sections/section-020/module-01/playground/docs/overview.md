# Overview: Separate Administration From Applications With Realms (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, runs one Keycloak server and a client pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`realms-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | **Keycloak 26.8.1** in development mode (`start-dev`), behind the Service `keycloak` on port `8080`. Health checks answer on port `9000` |
  | `tester` | Client pod with `curl` and `jq`; send token requests from here |

- **Only the `master` realm.** A realm is a space in Keycloak that holds its own users, clients, roles, groups and settings. `master` holds the bootstrap administrator: user `admin`, password `admin`, set from the Secret `keycloak-admin`. These are lab-only credentials. There is no application realm, user or client yet; you create them.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool, `kcadm.sh`, inside the Keycloak pod. `get_user_token` asks a realm for a token with the password grant from the `tester` pod and prints the JSON response; it takes the realm, the client, the user name and the password. `decode_token` prints the payload of a token as JSON.

```sh
NAMESPACE=realms-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    -d grant_type=password -d client_id="$2" -d username="$3" -d password="$4" \
    "http://keycloak:8080/realms/$1/protocol/openid-connect/token"
}
decode_token() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Use them like this: `kcadm get realms --fields realm,enabled`, and `get_user_token master admin-cli admin admin | jq -r .access_token | decode_token`. Run `kcadm config credentials` again when `kcadm` answers `401`. The password grant is used here only to test from a terminal; OAuth 2.1 drops it, and a real application uses the authorization code flow.

To use the Admin Console, run `kubectl -n realms-demo port-forward svc/keycloak 8080:8080` in a second terminal and open `http://localhost:8080/admin`.

## Practice tasks

- Create a realm in the Admin Console and a second one with `kcadm`. Compare their discovery documents at `/realms/<realm>/.well-known/openid-configuration` and the `kid` values at `/realms/<realm>/protocol/openid-connect/certs`.
- Create a user without an email, first name and last name, give it a password, and request a token for it. Read the error, then complete the profile with `kcadm update users/<id> -r <realm> -s ...` and try again.
- Set a password with `--temporary` and request a token. Find the required action on the user with `kcadm get users/<id> -r <realm> --fields requiredActions`.
- Create a user in `master` by leaving out `-r`, find it with `kcadm get users -q username=<name>`, and delete it again.
- Disable a realm with `kcadm update realms/<realm> -s enabled=false` and see what the token endpoint answers. Enable it again.
