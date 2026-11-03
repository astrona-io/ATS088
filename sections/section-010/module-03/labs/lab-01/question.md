# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Tokens

## Scenario

The API behind the client `inventory-api` accepts an access token only when its `aud` claim lists `inventory-api`. Tokens that the command-line client `inventory-cli` gets for `alice` do not list it, so the API rejects every call. The team must fix this in Keycloak, without changing the API and without making tokens last longer.

## Your task

In the realm `inventory`:

1. Request an access token for `alice` through `inventory-cli` and read its `aud` claim.
2. Add a protocol mapper to the dedicated scope of `inventory-cli` that puts the audience `inventory-api` into the access token.
3. Request a new token and confirm that `aud` now lists `inventory-api`.
4. Introspect the new token with the client `inventory-api` and its secret and confirm that `active` is `true`.

## Constraints

- Add the audience to the access token of `inventory-cli` only. Do not add it to the `profile` or `email` client scopes, because other clients share them.
- Do not change the access token lifespan.
- Do not give `inventory-cli` a client secret or change its type.

## Done when

- A new access token for `alice` from `inventory-cli` has `aud` with `inventory-api`.
- Its `iss` is `http://keycloak:8080/realms/inventory` and `preferred_username` is `alice`.
- The introspection endpoint, called with `inventory-api` and `inventory-api-secret`, returns `"active": true` for that token.
- The access token lifespan is still the default `300` seconds.
