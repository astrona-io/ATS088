# PKCE And Exact Redirect URIs

A public client cannot keep a secret, so the only thing that stops a thief from using a stolen authorization code is the way the client is registered. Two settings do that work: the list of redirect URIs that Keycloak accepts, and Proof Key for Code Exchange (PKCE), a check that ties the token request to the client that started the flow. This part shows the attack each setting stops and how to set both with `kcadm.sh`.

## The problem a code in a URL creates

The authorization code travels in a URL, in the front channel. A malicious application on the same device can register to receive the same redirect, or a script can read a URL from the logs. A thief who holds the code could post it to the token endpoint and get the user's tokens. A confidential client would also need its secret, but a public client has none.

PKCE (pronounced "pixie") fixes this without a secret. The client invents a random string for each sign-in, called the **code verifier**. It sends only a hash of that string, the **code challenge**, in the authorization request. Keycloak stores the challenge with the code. At the token request the client sends the verifier itself, and Keycloak hashes it and compares. A thief who saw only the URL has the code and the challenge, but not the verifier, and a hash cannot be reversed.

## Compute a verifier and a challenge

The method `S256` means the challenge is the Base64URL-encoded SHA-256 hash of the verifier. The verifier is a random string of 43 to 128 characters. Compute both in the `tester` pod:

<!-- astrona:playground:renew -->

```sh
kubectl -n authcode-demo exec deploy/tester -- bash -c '
VERIFIER=$(openssl rand -base64 48 | tr -d "=+/\n" | cut -c1-64)
CHALLENGE=$(printf %s "$VERIFIER" | openssl dgst -sha256 -binary | openssl base64 -A | tr "+/" "-_" | tr -d "=")
echo "verifier:  $VERIFIER"
echo "challenge: $CHALLENGE"'
```

The two lines print different random-looking strings that change at every run. The challenge is 43 characters long, because SHA-256 gives 32 bytes. The `tr` commands turn the standard Base64 alphabet into the URL-safe one and remove the padding `=`.

## Make Keycloak require PKCE

PKCE is optional by default: a client that sends no challenge still works. A client setting turns it into a requirement. Sign in with `kcadm.sh` and read the attributes of `inventory-web`:

```sh
NAMESPACE=authcode-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=inventory-web --fields clientId,attributes
```

The attribute `pkce.code.challenge.method` has the value `S256`. When it is set, Keycloak refuses an authorization request for this client that has no `code_challenge`. It also refuses a token request whose verifier does not match. In the Admin Console the setting is **Proof Key for Code Exchange Code Challenge Method** on the client's **Advanced** tab. To set it on another client, use the client's internal ID:

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory -s 'attributes."pkce.code.challenge.method"=S256'
```

Send an authorization request for `inventory-web` without `code_challenge` and read the answer:

```sh
kubectl -n authcode-demo exec deploy/tester -- \
  curl -s -i 'http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=https://inventory.example.test/callback' \
  | grep -i '^location:'
```

Keycloak redirects the browser back to the registered redirect URI with an `error` parameter in the query, and no code. The error tells the client application that its request was incomplete. Without the setting, the same request would have returned the login page.

## Exact redirect URIs and web origins

PKCE protects the code after it is issued. The redirect URI list protects where the code goes. Keycloak compares the `redirect_uri` of each request with the list registered for the client, and it sends a code only to a match. A pattern such as `*` or `https://inventory.example.test/*` also matches addresses the owner never planned, for example an open redirect page on the same host that forwards the visitor to an attacker. Register the full URL of the callback, with no wildcard.

**Web origins** are a different list. An origin is a scheme, a host and a port, with no path, for example `https://inventory.example.test`. For a browser application, Keycloak uses it to set the Cross-Origin Resource Sharing (CORS) headers that let the application's JavaScript call the token endpoint. Use the exact origin here too.

Set both lists, keeping them exact:

```sh
kcadm update "clients/$(kcadm get clients -r inventory -q clientId=inventory-web --fields id --format csv --noquotes | tr -d '\r')" -r inventory \
  -s 'redirectUris=["https://inventory.example.test/callback"]' \
  -s 'webOrigins=["https://inventory.example.test"]'
```

You now know how PKCE ties a code to the client that asked for it, how to require it with a client attribute, and why redirect URIs and web origins must be exact. The open question is what the tokens contain after a successful sign-in, and how the client controls that with scopes.

## Common pitfalls

> [!WARNING]
> - **Leaving PKCE optional for a public client.** A client that does not send a challenge is not protected, and Keycloak accepts it unless the attribute requires PKCE.
> - **Using `plain` as the method.** `plain` sends the verifier itself as the challenge, so it does not hide anything. Use `S256`.
> - **Wildcards in redirect URIs.** `*` lets any address receive a code. Register the full callback URL.
> - **A path in a web origin.** An origin has no path and no trailing slash.
> - **Reusing one verifier for many sign-ins.** The verifier must be new and random for every authorization request.

## Your mission: Secure A Single-Page Client With PKCE And Exact Redirect URIs

You can now require PKCE and restrict where a client's codes and requests may come from. The graded lab gives you a browser application client that was registered with wildcards and no PKCE, and asks you to make its redirect URI, web origin and PKCE setting exact and to turn off the password grant.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-088-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-088-lab-010-02
astrona start ats-088-playground-010-02
```
