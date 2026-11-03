# Overview: Sign Users In With The Authorization Code Flow And PKCE (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with one user and two clients, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`authcode-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode (`start-dev`), behind the Service `keycloak` on port `8080` (`http`) and `9000` (`management`) |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; send test requests from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password`, with email, first name and last name set |
  | client `inventory-web` | Public client for a browser application. The standard flow is on, PKCE with `S256` is required, and the only redirect URI is `https://inventory.example.test/callback` |
  | client `inventory-cli` | Public client with direct access grants on, so it can use the password grant for `alice`. Used to get refresh tokens quickly |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n authcode-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal. They need `jq` on your machine.

`kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `get_user_token` prints the token response of the password grant for `alice` through `inventory-cli`, with `scope=openid`. `decode_jwt` reads a JWT on standard input and prints its payload as JSON.

```sh
NAMESPACE=authcode-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password \
      -d client_id=inventory-cli \
      -d username=alice \
      -d password=alice-password \
      -d scope=openid
}
decode_jwt() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Practice tasks

- Request the authorization endpoint for `inventory-web` with a redirect URI that is not registered, and compare the status code with a request that uses the registered URI.
- Send a valid authorization request without `code_challenge` and read the `error` that Keycloak returns to the redirect URI.
- Change the PKCE setting of `inventory-web` to empty in the Admin Console, repeat the request, and turn `S256` back on.
- Add a hardcoded claim mapper to `inventory-web` and find the claim in the access token of a user.
- Set the realm `accessTokenLifespan` to `60` and compare `expires_in` in a token response before and after.
- Turn on `revokeRefreshToken` for the realm, use one refresh token twice, and read the `error` of the second request.
- Request `scope=openid offline_access` for `alice` through `inventory-cli` and compare `refresh_expires_in` with a request without `offline_access`.
