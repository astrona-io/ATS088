# Summary

Keycloak keeps every user, client and setting inside a realm, and realms do not see each other. This module showed why the first realm on a server is not the place for an application, and how to build the right place from the terminal.

## What you learned

Keycloak creates the `master` realm at its first start, when the database is empty. In a container it creates the first administrator from `KC_BOOTSTRAP_ADMIN_USERNAME` and `KC_BOOTSTRAP_ADMIN_PASSWORD`, best read from a Kubernetes Secret. The variables only matter on that first start, and Keycloak marks the account as temporary, so a real server gets a permanent administrator next. The administrators of `master` can manage every realm on the server. An application's clients and users therefore belong in an application realm, where a wrong role stays inside that realm and where the settings, the issuer and the keys belong to the application alone.

A new realm already holds built-in clients, client scopes, settings and its own signing keys. Every realm publishes its endpoints under `/realms/<realm>`, and that base URL is the issuer in every token the realm signs. The discovery document at `/.well-known/openid-configuration` lists the endpoints, and `/protocol/openid-connect/certs` lists the public keys. Two realms on the same server have different issuers and different keys, so an API that trusts one realm rejects tokens from the other. Administrators always sign in through `/admin/master/console/`, and users manage their own account at `/realms/<realm>/account`.

`kcadm.sh` calls the Admin REST API, so it can do everything the Admin Console does. It signs in once with `config credentials` against `master`, and then runs `create`, `get`, `update` and `delete` on resource paths, with `-s` to set fields and `-r` to choose the realm. A user who should get tokens through a direct grant needs a permanent password and a complete profile. The proof that a realm works is a token whose issuer names that realm. The key facts to remember are these:

- `master` is for administration only; every application gets its own realm.
- The bootstrap administrator variables have no effect once `master` exists.
- The issuer of a token is the base URL of exactly one realm.
- `kcadm.sh` without `-r` works on `master`.
- Resource paths such as `clients/<id>` use the generated `id`, not the `clientId`.

<!-- astrona:playground:destroy -->
