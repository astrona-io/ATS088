# Summary

The authorization code flow keeps passwords and tokens away from the browser. The client sends the user to the authorization endpoint with a client ID, a redirect URI, a scope, a state and a code challenge. Keycloak signs the user in and sends the browser back with a single-use code. The client then posts the code to the token endpoint on the back channel and receives the tokens.

Two client settings make the flow safe. PKCE ties the code to the client that started the flow, because the token request must carry the verifier that matches the challenge. Exact redirect URIs and exact web origins decide where Keycloak sends codes and which sites may call the token endpoint from a browser. A wildcard in either list weakens the protection for every user.

The scope parameter and the client scopes decide what a token holds. Default client scopes always apply, optional client scopes apply only on request, and protocol mappers write the claims. A token should carry only what its consumers need.

Token lifetimes work on three clocks: the access token lifespan, the single sign-on session timeouts, and the refresh token. A refresh token replaces a new login while the session lives. Rotation makes each refresh token usable once, and the `offline_access` scope creates a refresh token that outlives the session.

Key facts:

- The authorization endpoint is `/realms/<realm>/protocol/openid-connect/auth`.
- The client attribute `pkce.code.challenge.method` set to `S256` requires PKCE.
- A code is single-use, and a second exchange returns `invalid_grant`.
- The default access token lifespan is 5 minutes.

<!-- astrona:playground:destroy -->
