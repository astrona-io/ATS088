# Token Introspection

Checking a signature locally is fast, but it cannot tell an API that a user has logged out or that a session was ended by an administrator. Keycloak offers a second way to check: the resource server sends the token to Keycloak and asks whether it is still active. This part shows that call, its answer, and when to prefer it over a local check.

## The introspection endpoint

**Token introspection** is defined in RFC 7662. The resource server posts the token to the introspection endpoint of the realm, `/realms/<realm>/protocol/openid-connect/token/introspect`, and Keycloak answers with a JSON document. The field `active` is `true` when Keycloak issued the token, it has not expired and its session is still alive. For an inactive token, the answer holds `active` set to `false` and nothing else.

The caller must prove who it is, so the endpoint requires **client authentication**. A confidential client sends its client id and secret, here with HTTP basic authentication. A public client cannot call the endpoint, because it has no secret. This is why the resource server in this module is the confidential client `inventory-api`.

<!-- astrona:playground:renew -->

Request a token for `alice` and introspect it as `inventory-api`:

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
introspect "$(jq -r .access_token tokens.json)" | jq '{active, username, client_id, scope, exp}'
```

The answer shows `active` as `true`, the `username` `alice`, the `client_id` `inventory-cli` and the scopes. The fields mirror the token claims, so the API gets the same facts without decoding anything. Now send the token with the wrong credentials:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' -u inventory-api:wrong-secret \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token/introspect \
    -d token="$(jq -r .access_token tokens.json)"
```

The status is `401`. Without valid client credentials, Keycloak does not tell anyone whether a token is active.

## Local check or introspection

Each method has a cost. A local signature check needs no network call, scales with the number of requests, and cannot see a logout or a revoked session until the token expires. Introspection sees the current state of the session, but it adds a call to Keycloak for each token check, so it adds latency and load.

A common design combines them. The API validates the signature and the claims locally for most requests, keeps access token lifespans short, and uses introspection for sensitive operations, or caches the introspection answer for a few seconds. Short lifespans limit how long a revoked token can still work.

You now know how to ask Keycloak about a token and why the call needs client authentication. The open question is exactly what a logout changes, and which of these two checks notices it.

## Common pitfalls

> [!WARNING]
> - **Calling introspection from a public client.** It has no secret and the call fails.
> - **Trusting the `active` field of a token you did not send to Keycloak.** Only the answer from Keycloak counts.
> - **Introspecting on every request without a cache.** It puts the load of the whole API on Keycloak.
> - **Sending the token in the URL.** Post it in the request body so it does not appear in logs.
