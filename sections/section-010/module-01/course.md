# Get Tokens From Keycloak With OAuth 2.0 And OpenID Connect

An application that uses Keycloak never sees a user's password. It sees a token: a short string, signed by Keycloak, that says who the user is or what the caller may do. If you cannot get a token from Keycloak and read what is inside it, you cannot tell whether Keycloak or the application is at fault when a sign-in fails.

Keycloak is an identity provider (IdP): a service that checks who a user is and tells applications the result, in a signed token or assertion. It speaks three standard protocols. OAuth 2.0 lets a client get an access token to call an API. OpenID Connect (OIDC) is a layer on top of OAuth 2.0 that adds an ID token, which tells the client who the user is. SAML 2.0 is an older XML-based standard that does the same job with signed assertions.

This module is about those protocols, seen from a terminal. Keep one sentence in mind: **a client asks the token endpoint of one realm for a token, and the grant type decides who the token is about.** A realm is a space in Keycloak that holds its own users, clients, roles and settings.

The module has four parts. **What Keycloak Does And Where It Fits** explains the job of an identity provider and Keycloak's place in the Cloud Native Computing Foundation (CNCF) landscape. **OAuth 2.0 And The Client Credentials Grant** names the four OAuth roles and has a service get its own token; a graded lab follows it. **OpenID Connect, The ID Token And The Discovery Document** gets a token for a user and reads the ID token claim by claim. **SAML 2.0 And Choosing A Protocol** reads a realm's SAML metadata and gives a rule for choosing between SAML and OpenID Connect.

## Learning objectives

After this module you can:

- Explain what an identity provider does and name the jobs Keycloak takes away from an application.
- Name the four OAuth 2.0 roles and say which component plays each one in the playground.
- Tell a public client from a confidential client, and say which grant types each can use.
- Request a token with the client credentials grant and with the password grant, using `curl`.
- Decode a JSON Web Token (JWT) and read its `iss`, `sub`, `azp`, `aud`, `exp` and `preferred_username` claims.
- Read a realm's discovery document and find its token, UserInfo and key endpoints.
- Explain what OpenID Connect adds to OAuth 2.0.
- Read a realm's SAML 2.0 metadata and choose between SAML and OpenID Connect for a new application.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, Secrets, and the commands `kubectl get`, `kubectl apply` and `kubectl exec`. You need to know what an HTTP request and a JSON document are. You do not need to know OAuth or OpenID Connect; this module teaches them.

Your playground is a single-node `kind` cluster. The namespace **`protocols-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

Inside Keycloak, the realm **`inventory`** holds the user `alice` (password `alice-password`) and two clients. The client `inventory-cli` is a public client that may use the password grant. The client `inventory-reporter` is a confidential client with a service account and the client secret `inventory-reporter-secret`. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials; never use them on a real server.

Every command in the parts runs against the playground cluster, and `kubectl` already points at it. Keycloak takes a few minutes to start the first time, so start the playground now.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
