# Overview: Get Tokens From Keycloak With OAuth 2.0 And OpenID Connect (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with one user and two clients, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`protocols-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode (`start-dev`), behind the Service `keycloak` on port `8080` (`http`) and `9000` (`management`) |
  | `tester` | Client pod with `curl` and `jq`; send test requests from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**. A realm is a space in Keycloak that holds its own users, clients and settings.

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password`, with email, first name and last name set |
  | client `inventory-cli` | Public client with direct access grants on, so it can use the password grant for `alice` |
  | client `inventory-reporter` | Confidential client with a service account, client secret `inventory-reporter-secret`, for the client credentials grant |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n protocols-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal. They need `jq` on your machine.

`kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod; sign it in once with the `kcadm config credentials` line, and again when it answers `401`. `get_client_token` prints the token response of the client credentials grant for `inventory-reporter`. `get_user_token` prints the token response of the password grant for `alice`, with `scope=openid`. `decode_jwt` reads a JWT on standard input and prints its payload as JSON.

```sh
NAMESPACE=protocols-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_client_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=client_credentials \
      -d client_id=inventory-reporter \
      -d client_secret=inventory-reporter-secret
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

Use them like this: `get_client_token | jq`, `get_user_token | jq -r .id_token | decode_jwt`, `kcadm get clients -r inventory --fields clientId,protocol`.

## Practice tasks

- Compare the access token and the ID token of `alice` with `decode_jwt`. Write down which claims appear in only one of them, and the value of `aud` and `azp` in each.
- Turn off the service account of `inventory-reporter` and predict what `get_client_token` returns before you run it. Find the client's ID with `kcadm get clients -r inventory -q clientId=inventory-reporter --fields id`, then run `kcadm update clients/<ID> -r inventory -s serviceAccountsEnabled=false`. Turn it back on afterwards.
- Request a user token without `scope=openid` and check which key is missing from the response.
- Send a wrong password for `alice` and read the `error` and `error_description` fields of the response.
- Read the discovery document of the `master` realm and of `inventory`, and compare their `issuer` values.
- Forward the Service to your machine with `kubectl -n protocols-demo port-forward svc/keycloak 8080:8080`, open `http://localhost:8080/admin`, sign in as `admin`, and find the settings you changed with `kcadm` in the Admin Console. Note that tokens requested through `localhost:8080` have a different issuer from tokens requested through `keycloak:8080`.
- Fetch the SAML metadata at `/realms/inventory/protocol/saml/descriptor` and find the realm's signing certificate.
