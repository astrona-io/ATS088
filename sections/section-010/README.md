# Section 010: OAuth 2.0, OpenID Connect And SAML In Keycloak

Keycloak is an identity provider. An identity provider (IdP) is a service that checks who a user is and tells applications the result, in a signed token or assertion. Before you can run Keycloak well, you need to know what it hands out and why. This section teaches the protocols Keycloak speaks and the tokens they produce.

The section starts with Keycloak's place in the Cloud Native Computing Foundation (CNCF) landscape and the job of an identity provider. Then it covers OAuth 2.0 and the client credentials grant, which a service uses to get its own token. Next comes OpenID Connect (OIDC), which adds the ID token and the discovery document. It ends with SAML 2.0 and a clear rule for when to use which protocol.

**Topic covered:** Identity protocols

## What you will learn

- What an identity provider does, and where Keycloak sits among CNCF projects.
- The four roles in OAuth 2.0: resource owner, client, authorization server and resource server.
- Public clients against confidential clients, and why only a confidential client can use the client credentials grant.
- Requesting a token from the token endpoint with `curl`, and reading its claims with `jq`.
- The JSON Web Token (JWT) format: header, payload and signature.
- What OpenID Connect adds to OAuth 2.0: the ID token, the `openid` scope, the UserInfo endpoint and the discovery document.
- What the issuer (`iss`) claim says, and why it must match what the client expects.
- SAML 2.0 assertions and metadata, and how to choose between SAML and OpenID Connect.

## The learning path

Work through the module in order. It has a landing page, a few short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Get Tokens From Keycloak With OAuth 2.0 And OpenID Connect

The module starts at its landing page, which also launches the playground. The playground holds the namespace `protocols-demo` with one Keycloak 26.8.1 pod, a `tester` pod, and the realm `inventory` with the user `alice` and two clients.

1. What Keycloak Does And Where It Fits
2. OAuth 2.0 And The Client Credentials Grant, followed by the lab **Give A Service Client Its Own Token**
3. OpenID Connect, The ID Token And The Discovery Document
4. SAML 2.0 And Choosing A Protocol
5. Summary

## Section capstone: Make A User Sign-In Work End To End

The capstone is one graded scenario that combines the whole module. In the namespace `protocolscapstone-demo`, the user `alice` cannot get any token from the realm `inventory`. The token endpoint refuses each request, and there is more than one reason. You find each fault from the error Keycloak returns, fix the client and the user without recreating them, and prove the fix with an ID token. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-088-capstone-010
```
