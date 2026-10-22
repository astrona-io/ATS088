# OpenID Connect, The ID Token And The Discovery Document

OAuth 2.0 gives a client an access token for an API. It says nothing about who signed in. An application that shows "Hello, Alice" and needs her email address must not guess these from an access token that was meant for an API. This part shows how OpenID Connect closes that gap with the ID token, and how a client finds every endpoint of a realm from one document.

## What OpenID Connect adds

OpenID Connect (OIDC) is a layer on top of OAuth 2.0 that adds an ID token, which tells the client who the user is. The token endpoint and the grant types stay the same. OpenID Connect adds four things on top:

| Addition | What it is |
| --- | --- |
| The `openid` scope | A scope is a word the client sends to ask for a kind of access. With `openid` in the request, Keycloak treats it as an OpenID Connect request and returns an ID token |
| The ID token | A JWT for the **client**, not for an API. Its claims describe the signed-in user and the sign-in itself |
| The UserInfo endpoint | An endpoint that returns the user's claims when the client sends a valid access token |
| The discovery document | A JSON document that lists the realm's endpoints and features, so a client can set itself up from one URL |

The difference between the two tokens is about who reads them. The client reads the ID token to learn who signed in. The client sends the access token to an API, and the API reads it to decide what to allow. A client should never send its ID token to an API.

## Read the discovery document

Every realm publishes its discovery document at `/realms/<realm>/.well-known/openid-configuration`. Client libraries read it to find the endpoints, so you rarely type an endpoint URL by hand. Ask for the document of the realm `inventory` and pick out the main fields:

<!-- astrona:playground:renew -->

```sh
kubectl -n protocols-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/.well-known/openid-configuration \
  | jq '{issuer, authorization_endpoint, token_endpoint, userinfo_endpoint, jwks_uri, end_session_endpoint}'
```

Every value starts with `http://keycloak:8080/realms/inventory`. The `issuer` is that URL itself. The `token_endpoint` is the URL you used for the client credentials grant, and `jwks_uri` points at the realm's public keys. In development mode Keycloak builds these URLs from the request, so they use the host name the `tester` pod sent: `keycloak:8080`.

The issuer (`iss`) is the URL of the realm that signed a token. A client and an API compare the `iss` claim of every token with the issuer they expect, and refuse a token that does not match. So a token issued at `http://localhost:8080/realms/inventory` is refused by an API that expects `http://keycloak:8080/realms/inventory`, even though both are the same realm.

## Get an ID token for a user

To get a token about a user from a terminal, this module uses the password grant on the public client `inventory-cli`. The client sends the user's name and password straight to the token endpoint. This is only for tests: OAuth 2.1 drops the password grant, and a real application uses the authorization code flow, where the user types the password into Keycloak's own login page. In the Admin Console the setting is called **Direct access grants**.

Send the request with `scope=openid`, and keep the whole response in a shell variable on your machine:

```sh
TOKENS=$(kubectl -n protocols-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password \
    -d client_id=inventory-cli \
    -d username=alice \
    -d password=alice-password \
    -d scope=openid)
echo "$TOKENS" | jq 'keys'
```

The list of keys includes `access_token`, `id_token`, `refresh_token`, `expires_in` and `token_type`. The `id_token` is there because the request had `scope=openid`. Run the request again without `-d scope=openid` and the `id_token` key is missing.

Now decode the ID token. The helper reads the middle part of a JWT and prints it as JSON:

```sh
decode_jwt() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
echo "$TOKENS" | jq -r .id_token | decode_jwt
```

The payload has the claims a client reads. `typ` is `ID`. `iss` is `http://keycloak:8080/realms/inventory`. `aud` (audience), the client the token is for, is `inventory-cli`. `sub` (subject) is the user's ID in the realm, a UUID that never changes even if the user name changes. `preferred_username` is `alice`, and `email`, `given_name` and `family_name` come from her profile.

## Call the UserInfo endpoint

The UserInfo endpoint returns the same user claims to anyone who holds a valid access token for the user. Pass the access token in the `Authorization: Bearer` header:

```sh
ACCESS_TOKEN=$(echo "$TOKENS" | jq -r .access_token)
kubectl -n protocols-demo exec deploy/tester -- \
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/userinfo | jq
```

The response has `sub`, `preferred_username`, `email` and the name claims of `alice`. The access token lives for five minutes, so after that time the same command fails with `401`; request new tokens and try again. Keycloak checks the token here, so this is also a quick way to test whether an access token is still valid.

## Check the signing keys

An API does not call Keycloak for every request. It checks the token's signature with the realm's public key, which it gets once from `jwks_uri`. A JSON Web Key Set (JWKS) is a JSON document with a list of public keys. List the keys of the realm:

```sh
kubectl -n protocols-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/certs \
  | jq '.keys[] | {kid, kty, alg, use}'
```

Each key has a `kid` (key ID), a type and an algorithm, for example `RS256` for signatures. The header of every token names the `kid` that signed it, so an API can pick the right key. Decode the first part of the ID token instead of the second, and you can match its `kid` to one of these keys.

You now know what OpenID Connect adds to OAuth 2.0, how to read a discovery document, and how to get an ID token and read its claims. You also know why the issuer must match. The open question is the other protocol Keycloak speaks, SAML 2.0, and when an application should use it instead.

## Common pitfalls

> [!WARNING]
> - **Forgetting `scope=openid`.** Without it, the request is plain OAuth 2.0 and the response has no `id_token`.
> - **Sending the ID token to an API.** The ID token is for the client. APIs expect the access token.
> - **An issuer mismatch.** A token is issued for the host name the client used. `localhost:8080` and `keycloak:8080` give two different issuers for the same realm, and a strict API refuses the other one.
> - **Using `preferred_username` as a key.** User names can change. Store the `sub` claim to identify a user.
> - **Treating the password grant as normal.** It exists here only for terminal tests. Real applications use the authorization code flow.
