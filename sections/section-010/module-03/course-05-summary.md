# Summary

A resource server never sees the user's password, so it decides to trust a token by checking it. The first check is the signature. Keycloak signs each token with a private key and publishes the public keys as a JSON Web Key Set at the `certs` endpoint of the realm. The API finds the key by the `kid` in the token header and verifies the signature. A token whose signature is damaged is refused, even when its claims look right.

A good signature is not enough. The API also checks that the issuer is the exact URL of the expected realm, that `exp` is in the future, that `aud` lists the API, and that `azp` and `scope` fit the call. An audience protocol mapper puts an API into the `aud` claim. It belongs in the dedicated scope of the client that asks for the token, so that other clients that share a client scope do not change.

The second way to check is token introspection. The resource server posts the token to the introspection endpoint with its own client credentials, and Keycloak answers with `active` and the main claims. Introspection sees the state of the session. It costs one request to Keycloak for each check, so many APIs use it only for sensitive calls or cache the answer.

A logout ends the user session. The refresh token then fails with `invalid_grant`, and introspection returns `active: false`. An access token that was already issued keeps a valid signature until `exp`, so an API that checks only the signature accepts it until then. Short access token lifespans limit this gap.

Key facts:

- The key set is at `/realms/<realm>/protocol/openid-connect/certs`.
- Introspection is at `/realms/<realm>/protocol/openid-connect/token/introspect` and needs client authentication.
- The audience mapper type is `oidc-audience-mapper` and the setting for a client is `included.client.audience`.
- The default access token lifespan is 5 minutes.

<!-- astrona:playground:destroy -->
