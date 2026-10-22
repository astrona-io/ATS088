# Summary

An application that uses Keycloak never handles a password. It gets a signed token or assertion from Keycloak and trusts what it says. This module showed what Keycloak hands out, over which protocols, and how to read it from a terminal.

## What you learned

Keycloak is an identity provider: it checks who a user is and tells applications the result. It takes sign-in, password storage, single sign-on and second factors away from every application. Each application is a client in a realm, and every URL an application uses starts with `/realms/<realm>`. Keycloak joined the Cloud Native Computing Foundation (CNCF) as an incubating project in April 2023. Among the CNCF identity projects it is the one for people signing in; Dex connects to other identity providers, SPIFFE and SPIRE identify workloads, and Open Policy Agent decides on requests.

OAuth 2.0 has four roles: resource owner, client, authorization server and resource server. A client gets every token from the realm's token endpoint, and the grant type decides who the token is about. The client credentials grant gives a token to the client itself, through its service account. It needs a confidential client, one that proves who it is with a client secret. A public client cannot keep a secret, so Keycloak refuses that grant for it and says why in `error_description`.

OpenID Connect sits on top of OAuth 2.0. With the `openid` scope, the token endpoint also returns an ID token, which tells the client who signed in. The client reads the ID token; an API reads the access token. Both are JSON Web Tokens: a header, a payload and a signature, and the payload is only encoded, not hidden. The discovery document at `/.well-known/openid-configuration` lists every endpoint of a realm. The issuer in a token follows the host name the client used, and a client or API refuses a token whose issuer it does not expect.

SAML 2.0 does the same job with signed XML assertions that travel through the browser. Its metadata at `/protocol/saml/descriptor` gives the realm's entity ID, signing certificate and endpoints. The protocol is a setting of each client, so one realm serves both kinds of application. The key facts to remember are these:

- The token endpoint is `/realms/<realm>/protocol/openid-connect/token`.
- `client_credentials` needs a confidential client with service accounts on.
- `scope=openid` is what turns an OAuth 2.0 request into an OpenID Connect request with an ID token.
- The password grant is only for tests; real applications use the authorization code flow.
- Use OpenID Connect for new applications, and SAML only when the application supports nothing else.

<!-- astrona:playground:destroy -->
