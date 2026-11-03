# Overview: Validate Tokens In A Resource Server (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`tokenval-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl` and `jq`; send test requests from here to `http://keycloak:8080` |

- The realm **`inventory`** with the user `alice` (password `alice-password`), the public client `inventory-cli` with direct access grants on, and the confidential client `inventory-api` with the secret `inventory-api-secret`. The client `inventory-api` stands for a resource server: an API that receives access tokens.
- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n tokenval-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal. `get_tokens` requests tokens for `alice` through the password grant and saves the response in `tokens.json`. The password grant appears only so you can get a user token from a terminal; OAuth 2.1 drops it, and a real application uses the authorization code flow. `show_claims` prints the payload of the access token.

```sh
NAMESPACE=tokenval-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid > tokens.json
}
show_claims() {
  jq -r .access_token tokens.json \
    | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
```

## Practice tasks

- Run `get_tokens` and `show_claims`, and find `iss`, `exp`, `aud` and `azp`.
- Read the signing keys at `/realms/inventory/protocol/openid-connect/certs` and match the `kid` of the token header.
- Call the UserInfo endpoint with a good token and with a token that has one added character.
- Introspect a token with the client `inventory-api` and read the `active` field.
- Add an audience mapper to `inventory-cli` and compare the `aud` claim before and after.
- Log out with the refresh token, then introspect the access token again.
