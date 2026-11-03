# Sign Users In With The Authorization Code Flow And PKCE

A browser application must never hold a user's password, and it must never send tokens through an address an attacker controls. The authorization code flow solves the first problem, and exact redirect URIs with PKCE solve the second. Most real Keycloak sign-ins use this flow, so a mistake in its settings is a mistake in front of every user.

Keycloak is an identity and access management server that signs users in and issues tokens. In the authorization code flow, the application sends the user's browser to Keycloak. The user signs in on a Keycloak page. Keycloak sends the browser back to the application with a short-lived code, and the application exchanges that code for tokens in a direct request to Keycloak. A realm is a space in Keycloak that holds its own users, clients, roles and settings.

Keep one sentence in mind: **the browser carries only a code, and the token request proves that the same client that asked for the code is the one using it.** This module shows each step with `curl`, then covers the settings that make the flow safe and the settings that decide what the tokens contain and how long they live.

The module has four parts. **The Authorization Code Flow Step By Step** sends the authorization request, signs in as a user with `curl` and exchanges the code. **PKCE And Exact Redirect URIs** adds the code challenge and shows why wildcards are dangerous; a graded lab follows it. **Scopes, Client Scopes And Claims** shows how the `scope` parameter and protocol mappers decide what a token holds. **Refresh Tokens, Token Lifespans And Sessions** covers the lifetimes of tokens and of the user's single sign-on session.

## Learning objectives

After this module you can:

- Name the parameters of an authorization request and say what each one does.
- Describe the front channel and the back channel of the authorization code flow.
- Sign in as a user with `curl` and exchange an authorization code for tokens.
- Compute a PKCE code verifier and code challenge and set a client to require `S256`.
- Explain why a client needs exact redirect URIs and exact web origins.
- Tell a default client scope from an optional client scope, and add a protocol mapper to a client.
- Use a refresh token, and set the access token lifespan and the single sign-on session timeouts.
- Explain what the `offline_access` scope changes.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services and the commands `kubectl get` and `kubectl exec`. You need to know what an HTTP redirect is, and what a JSON Web Token (JWT) is: a signed token with three Base64URL parts. You do not need to know the authorization code flow; this module teaches it.

Your playground is a single-node `kind` cluster. The namespace **`authcode-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl`, `jq` and `openssl`. Every test request in this module is sent from here |

Inside Keycloak, the realm **`inventory`** holds the user `alice` (password `alice-password`) and two public clients. The client `inventory-web` is a browser application client with the standard flow on and the redirect URI `https://inventory.example.test/callback`. The client `inventory-cli` may use the password grant, which gives quick access to refresh tokens. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials; never use them on a real server.

Every command in the parts runs against the playground cluster, and `kubectl` already points at it. Keycloak takes a few minutes to start the first time, so start the playground now.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
