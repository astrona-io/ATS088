# Logout And Token Lifetime

A user logs out and expects the access to end. Whether it does depends on which token the API holds and how the API checks it. This part shows what the logout endpoint does to the session and the refresh token, and why an access token that is still unexpired can keep passing a local signature check.

## What a logout ends

A user session at Keycloak is the record of the sign-in. A logout ends that session. The tokens that belong to it are then no longer usable in the ways that need the session: the refresh token stops working, and an introspection of the access token returns `active: false`. The access token itself is a signed document that nobody can recall. Its signature and `exp` claim stay valid until it expires.

A client logs out a user by calling the logout endpoint of the realm, `/realms/<realm>/protocol/openid-connect/logout`, with its `client_id` and the `refresh_token`. A public client does not need a secret for this call.

<!-- astrona:playground:renew -->

Get tokens and keep both the access token and the refresh token:

```sh
NAMESPACE=tokenval-demo
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid > tokens.json
}
introspect() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -u inventory-api:inventory-api-secret \
      http://keycloak:8080/realms/inventory/protocol/openid-connect/token/introspect \
      -d token="$1"
}
get_tokens
ACCESS_TOKEN=$(jq -r .access_token tokens.json)
REFRESH_TOKEN=$(jq -r .refresh_token tokens.json)
introspect "$ACCESS_TOKEN" | jq '{active}'
```

The token is active. Log the user out with the refresh token:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/logout \
    -d client_id=inventory-cli -d refresh_token="$REFRESH_TOKEN"
```

The status is `204`, with no body. Introspect the same access token again:

```sh
introspect "$ACCESS_TOKEN" | jq '{active}'
```

The token is no longer active, because its session ended. Now try to use the refresh token to get new tokens:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=refresh_token -d client_id=inventory-cli -d refresh_token="$REFRESH_TOKEN" | jq '{error}'
```

The `error` is `invalid_grant`. The session is gone, so the refresh token cannot be exchanged.

## What a signature check still accepts

The access token from before the logout still has a valid signature, the right issuer and an `exp` in the future. An API that checks only these will accept it until it expires, at most the access token lifespan, five minutes by default. This is the reason for short lifespans. A longer lifespan makes the gap longer. An API that cannot accept the gap introspects the token, or the realm can use shorter lifespans.

An administrator can also end sessions without the user: in the Admin Console under **Sessions**, or by deleting a session through the Admin REST API. Offline tokens, which come from the `offline_access` scope, belong to an offline session that a normal logout does not end, and they have their own revocation.

You now know what a logout changes and what it leaves valid. A resource server combines the checks: signature, issuer, expiry and audience for every call, short lifespans, and introspection where an ended session must stop access at once.

## Common pitfalls

> [!WARNING]
> - **Expecting a logout to cancel an access token that an API checks only by signature.** It stays valid until `exp`.
> - **Calling the logout endpoint without the `refresh_token`.** For a back-channel logout from a command line, Keycloak needs it to find the session.
> - **Raising the access token lifespan to avoid refreshes.** It lengthens the gap after a logout.
> - **Forgetting offline sessions.** Sessions created through `offline_access` outlive a normal logout.
