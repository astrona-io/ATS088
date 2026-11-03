# Scopes, Client Scopes And Claims

Two applications can sign in the same user and still need different tokens. A reporting service needs a role list, while a mobile application needs the email address and nothing more. Keycloak lets each client choose, and it keeps tokens small by adding only what was asked for. This part shows how the `scope` parameter, client scopes and protocol mappers decide the claims in a token.

## Scopes, client scopes and mappers

A **scope** is a word the client sends in the `scope` parameter to ask for a kind of access, for example `openid`, `profile` or `email`. In Keycloak each scope name is backed by a **client scope**: a named set of settings that is shared between clients. A client scope holds **protocol mappers**. A protocol mapper is a rule that takes a value (a user attribute, a role list, a fixed text) and writes it as a claim into a token.

A client scope has a type for each client. A **default** client scope is always applied when a token is issued for the client. An **optional** client scope is applied only when the client asks for it in the `scope` parameter. Every client also has a **dedicated scope**, named after the client, for mappers that only that client needs.

<!-- astrona:playground:renew -->

List the client scopes of the realm and the protocol they belong to:

```sh
NAMESPACE=authcode-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get client-scopes -r inventory --fields name,protocol
```

The list includes `profile`, `email`, `roles`, `web-origins`, `offline_access` and others, all for `openid-connect`. Now see which of them `inventory-web` receives by default and which it may ask for:

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-web --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$CLIENT_ID/default-client-scopes" -r inventory --fields name
kcadm get "clients/$CLIENT_ID/optional-client-scopes" -r inventory --fields name
```

The default list holds scopes such as `profile`, `email`, `roles` and `web-origins`. The optional list holds scopes such as `offline_access`, `address`, `phone` and `microprofile-jwt`. In the Admin Console both lists are on the client's **Client scopes** tab.

## See the effect of the scope parameter

Request a token for `alice` through `inventory-cli`, first with only `openid`, then with `openid email`. Define a helper that prints the decoded access token for a scope value:

```sh
decode_access_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d "scope=$1" \
  | jq -r .access_token \
  | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
decode_access_token openid
```

The password grant appears here only so you can get a user token from a terminal; a real browser application uses the authorization code flow. The payload carries the claims of the default scopes: `preferred_username`, `email`, `realm_access` from the `roles` scope, and `scope` that lists the granted scopes. The `scope` claim names what Keycloak actually granted, which can be less than what the client asked for.

## Add a claim with a protocol mapper

Add a mapper to the dedicated scope of `inventory-cli` that writes a fixed claim `region`. The mapper type `oidc-hardcoded-claim-mapper` writes the same value for every user:

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=region -s protocol=openid-connect -s protocolMapper=oidc-hardcoded-claim-mapper \
  -s 'config."claim.name"=region' -s 'config."claim.value"=eu-north' \
  -s 'config."jsonType.label"=String' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=true'
decode_access_token openid | jq '{preferred_username, region}'
```

The new token holds `"region": "eu-north"`. The three `*.claim` settings choose which tokens receive the claim: the access token, the ID token, or the UserInfo response. A mapper that is set for the ID token only never appears in the access token. For values that come from the user instead of a fixed text, the mapper type `oidc-usermodel-attribute-mapper` reads a user attribute.

## Why a token should stay small

The access token travels in the `Authorization` header of every API call. Large tokens hit header size limits of proxies and servers, and every claim is readable by anyone who holds the token. Put a claim in a token only when a consumer needs it, and prefer the optional scope for data that few clients use. An API can also call the UserInfo endpoint when it needs more attributes than the token holds.

You now know the difference between a scope, a client scope and a mapper, how default and optional scopes differ, and how to add a claim to a token. The open question is how long these tokens stay valid and how a client gets new ones without asking the user to sign in again.

## Common pitfalls

> [!WARNING]
> - **Expecting an optional scope without asking for it.** An optional client scope applies only when its name is in the `scope` parameter.
> - **Putting sensitive data in claims.** A JWT payload is only encoded, so any holder can read it.
> - **Setting a mapper for the wrong token.** A mapper with only `id.token.claim` on does not change the access token.
> - **Adding a mapper to a shared client scope by accident.** Every client that uses the scope gets the claim. Use the dedicated scope for a single client.
> - **Assuming `scope` in the request equals `scope` in the token.** Read the `scope` claim to see what was granted.
