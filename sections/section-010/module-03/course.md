# Validate Tokens In A Resource Server

An access token is only useful if the API that receives it can decide whether to trust it. The API never sees the user's password, so it must check the token itself: that Keycloak signed it, that it has not expired, and that it was meant for this API. A resource server that skips one of these checks accepts forged, old or misdirected tokens.

A resource server is an API that receives access tokens and serves data when a token is valid. A client is the application that sends the token. A JSON Web Token (JWT) is a token made of three Base64URL parts, a header, a payload and a signature, separated by dots. The payload holds claims, which are statements such as the issuer, the expiry time and the audience.

Keep one sentence in mind: **a resource server trusts a token only after it has checked the signature, the issuer, the expiry and the audience, or after Keycloak has confirmed the token through introspection.** This module shows both ways to check, adds the audience a token needs, and shows what happens to a token when the user logs out.

The module has four parts. **Check The Signature With The Realm Keys** reads the signing keys and shows a token that fails. **Claims A Resource Server Must Check** covers the issuer, the expiry and the audience, and ends with the graded lab. **Token Introspection** asks Keycloak whether a token is active. **Logout And Token Lifetime** shows what a logout does and does not revoke.

## Learning objectives

After this module you can:

- Read the signing keys of a realm from the `certs` endpoint and match the `kid` of a token.
- Explain which claims an API checks: `iss`, `exp`, `aud` and `azp`.
- Add an audience to an access token with an audience protocol mapper.
- Call the introspection endpoint with client authentication and read the `active` field.
- Explain what a logout revokes, and why a signature check alone still accepts an unexpired access token.

## Before you start

You need to know what a token is, how to request one from the token endpoint with `curl`, and how to decode a JWT payload with `jq`. You do not need to know the validation rules; this module teaches them.

Your playground is a single-node `kind` cluster. The namespace **`tokenval-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

Inside Keycloak, the realm **`inventory`** holds the user `alice` (password `alice-password`), the public client `inventory-cli` with direct access grants on, and the confidential client `inventory-api` with the secret `inventory-api-secret`, which stands for the resource server. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials; never use them on a real server.

Every command runs against the playground cluster, and `kubectl` already points at it. Keycloak takes a few minutes to start the first time, so start the playground now.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
