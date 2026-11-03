# Check The Signature With The Realm Keys

An API receives a long string in the `Authorization` header and must decide whether Keycloak really issued it. Anyone can write a JWT with any claims, so the claims prove nothing until the signature is checked. Keycloak signs each token with a private key that never leaves the server, and it publishes the matching public keys so that any API can check the signature without calling Keycloak. This part shows those keys and what a token with a damaged signature does.

## The parts of a token

A JWT has three parts separated by dots. The **header** says how the token was signed: the algorithm `alg`, usually `RS256` (RSA with SHA-256), and the key id `kid`. The **payload** holds the claims. The **signature** is computed over the header and the payload with the realm's private key. If anyone changes one character of the header or payload, the signature no longer matches.

The public keys are published as a JSON Web Key Set (JWKS) at `/realms/<realm>/protocol/openid-connect/certs`. The discovery document names this address in the field `jwks_uri`. An API fetches the set, finds the key whose `kid` equals the `kid` in the token header, and verifies the signature with it. Most libraries cache the set and fetch it again when they see an unknown `kid`, which is what happens after a key rotation.

<!-- astrona:playground:renew -->

Request tokens for `alice` and read the header of the access token. The password grant appears here only to get a user token from a terminal; a real application uses the authorization code flow.

```sh
NAMESPACE=tokenval-demo
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid > tokens.json
}
get_tokens
jq -r .access_token tokens.json | jq -R 'split(".")[0] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
```

The header holds `alg` with `RS256`, `typ` with `JWT` and a `kid`. Now read the key set and find the key with that `kid`:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/certs \
  | jq '.keys[] | {kid, kty, alg, use}'
```

Each key lists its `kid`, the key type `kty` (`RSA`), the algorithm and the use. The key marked `"use": "sig"` signs tokens. The set can also hold a key for encryption, with `"use": "enc"`, which is not used for signatures. The `kid` of the token header matches one of the signing keys.

## A token with a damaged signature

Keycloak itself validates tokens on its UserInfo endpoint, so that endpoint shows the result of a signature check. First send the good token:

```sh
ACCESS_TOKEN=$(jq -r .access_token tokens.json)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/userinfo
```

The status is `200`. Now add one character to the end of the token, which damages the signature:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' \
  -H "Authorization: Bearer ${ACCESS_TOKEN}x" \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/userinfo
```

The status is `401`. Keycloak refused the token because the signature does not match, even though the claims are the same. An API that decodes the payload without verifying the signature would have accepted it.

## Where keys come from

Every realm has its own keys, so a token from one realm does not validate against another realm's key set. The administrator manages the keys under **Realm settings**, on the **Keys** tab. When a key is rotated, new tokens carry the new `kid` and old tokens stay valid until they expire, as long as the old key stays in the set. This is why an API must read the `kid` and not assume one key forever.

You now know the three parts of a token, where the public keys are, and what a damaged signature does. The open question is what else an API must check once the signature is good, because a validly signed token can still be expired or meant for another API.

## Common pitfalls

> [!WARNING]
> - **Decoding a token and trusting the claims.** Base64URL is an encoding. Anyone can write a payload, so verify the signature first.
> - **Hard-coding one public key.** After a rotation, tokens carry a new `kid`. Read the key set and match the `kid`.
> - **Accepting the algorithm `none`.** Allow only the algorithms you expect, usually `RS256`.
> - **Using the key set of the wrong realm.** Each realm signs with its own keys.
