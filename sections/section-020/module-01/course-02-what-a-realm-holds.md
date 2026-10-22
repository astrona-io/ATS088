# What A Realm Holds, And Its URLs

Creating a realm takes one click. Knowing what you just created takes longer. A new realm is not an empty folder: it already holds settings, built-in clients and its own signing keys, and it publishes its own set of URLs. This part creates a second realm in the Admin Console, goes through what is inside it, and compares its URLs with the URLs of `master`. Those URLs are what every application that uses the realm depends on.

## Creating a realm in the Admin Console

A **realm** is a space in Keycloak that holds its own users, clients, roles, groups and settings. You create one from the **Manage realms** page of the Admin Console, the web interface for administrators. If the port forward from the playground is not running, start it again in a second terminal and leave it running:

<!-- astrona:playground:renew -->

```sh
kubectl -n realms-demo port-forward svc/keycloak 8080:8080
```

Open `http://localhost:8080/admin` and sign in as `admin` with the password `admin`, which are lab-only credentials. Then create the realm:

1. Click **Manage realms**, then **Create realm**.
2. Enter `demo` in **Realm name**. Leave **Enabled** on.
3. Click **Create**.

The console switches to the new realm, and the realm selector now shows `demo`. The realm name is part of every URL of the realm, so pick it with care. You can change a realm's display name later, but renaming the realm itself changes all of its URLs.

## What is inside a realm

The left menu of the console lists what a realm holds. Each item belongs to this realm only. A user in `demo` does not exist in `master`, and a client in `master` cannot ask `demo` for a token.

| Object | What it is |
| --- | --- |
| Users | The accounts that can sign in to this realm, with their attributes (email, first name, last name) |
| Credentials | A user's password, one-time password devices or passkeys; they belong to the user in this realm |
| Clients | The applications and services that use this realm to sign users in or to get tokens |
| Client scopes | Named sets of claims and roles that clients can ask for, for example `profile` and `email` |
| Realm roles | Roles that any client in the realm can see in a token |
| Groups | Sets of users that share roles and attributes |
| Realm settings | Login options, token and session lifetimes, email server, themes and user profile rules |
| Keys | The key pairs the realm uses to sign tokens |
| Authentication | The flows that decide which steps a sign-in needs, for example a password and then a one-time code |

Open **Clients** in `demo`. The list is not empty: Keycloak created built-in clients such as `account`, `account-console`, `admin-cli` and `security-admin-console`. They serve the realm's own pages and tools. Then open **Realm settings** and the **Keys** tab. The realm already has key pairs, generated when you clicked **Create**.

## The URLs a realm publishes

Every realm has a base URL: the server address, then `/realms/`, then the realm name. Every endpoint a client uses sits under it:

| URL | What it is for |
| --- | --- |
| `/realms/<realm>` | The realm's base URL; it is also the **issuer** in every token the realm signs |
| `/realms/<realm>/.well-known/openid-configuration` | The discovery document: a JSON list of the realm's endpoints and features |
| `/realms/<realm>/protocol/openid-connect/token` | The token endpoint, where clients get tokens |
| `/realms/<realm>/protocol/openid-connect/certs` | The realm's public keys, which an API uses to check a token's signature |
| `/realms/<realm>/account` | The Account Console, where a user of the realm manages their own account |
| `/admin/master/console/` | The Admin Console; administrators of `master` sign in here to manage every realm |

The Admin Console is the exception to the pattern. It always signs you in through `master`, because `master` holds the administrators, and you then pick the realm you want to manage. Compare the discovery documents of the two realms from the `tester` pod:

```sh
for realm in master demo; do
  kubectl -n realms-demo exec deploy/tester -- \
    curl -s "http://keycloak:8080/realms/$realm/.well-known/openid-configuration" \
    | jq '{issuer, token_endpoint, jwks_uri}'
done
```

You get two JSON objects. In each one, the three values start with the same server address, `http://keycloak:8080`, and differ only in the realm name: `/realms/master` against `/realms/demo`. The `issuer` is exactly the realm's base URL.

## Each realm signs with its own keys

The URLs differ, and so do the keys behind them. A token carries a `kid` (key ID) in its header, which tells an API which public key checks the signature. List the signing keys of both realms:

```sh
for realm in master demo; do
  kubectl -n realms-demo exec deploy/tester -- \
    curl -s "http://keycloak:8080/realms/$realm/protocol/openid-connect/certs" \
    | jq -c '.keys[] | {kid, alg, use}'
done
```

Each realm prints its own keys, at least one with `"use":"sig"` (signing) and `"alg":"RS256"`. The `kid` values of `master` and `demo` are all different. So a token signed by `demo` cannot pass a signature check against the keys of `master`, even on the same server.

This is what isolation between realms means in practice. An API is set up to trust one issuer and its keys. It accepts tokens from that realm and rejects tokens from every other realm, with no extra rule needed.

You now know what a realm holds and how its URLs and keys tie every token to exactly one realm. The open question is how to build a realm without clicking, so that the same setup can run on every server.

## Common pitfalls

> [!WARNING]
> - **Thinking a new realm is empty.** It already has built-in clients, client scopes, settings and signing keys. Do not delete the built-in clients; the realm's own pages need them.
> - **Renaming a realm that applications already use.** The realm name is in the issuer and in every endpoint URL. Every client and API that uses the realm breaks.
> - **Looking for a realm's administration page under `/realms/<realm>`.** Administrators always sign in through `/admin/master/console/` and then pick the realm. `/realms/<realm>/account` is for the realm's own users.
> - **Expecting a user to sign in to any realm on the server.** Users, credentials and sessions belong to one realm. A user in `demo` does not exist in `master`.
