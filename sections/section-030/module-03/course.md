# Secure Keycloak Traffic With TLS And A Reverse Proxy

Keycloak signs users in and issues tokens, so every request to it carries passwords, authorization codes or tokens. Sent over plain HTTP, any device on the network path can read them. In production, Keycloak traffic must be encrypted with Transport Layer Security (TLS), and the server must also know which address the outside world uses to reach it.

Keycloak is an identity and access management server. TLS is the protocol that encrypts HTTP traffic and lets a client check the server's identity with a certificate. A reverse proxy is a server in front of Keycloak that receives requests from clients and forwards them to Keycloak. Many deployments end TLS at the reverse proxy, and some also encrypt the last hop to Keycloak.

Keep one sentence in mind: **Keycloak builds every address it returns from its hostname and from the TLS and proxy settings, so a wrong setting shows up as a wrong issuer, a wrong redirect or a failed health check.** This module shows where TLS can end, how to give Keycloak a certificate, how to make it trust a reverse proxy, and how to find the cause when something fails.

The module has four parts. **Where TLS Ends** compares the three common layouts. **Server TLS Certificate Files** mounts a certificate from a Kubernetes Secret. **Reverse Proxy Headers** sets the options for a server behind a proxy; a graded lab follows it. **Troubleshooting TLS And Proxy Problems** reads the symptoms and checks each layer.

## Learning objectives

After this module you can:

- Compare TLS edge termination, re-encryption and passthrough.
- Say why `start` needs a hostname and either TLS or `KC_HTTP_ENABLED`.
- Mount a certificate and key from a Secret and set `KC_HTTPS_CERTIFICATE_FILE` and `KC_HTTPS_CERTIFICATE_KEY_FILE`.
- Set `KC_PROXY_HEADERS` to `xforwarded` or `forwarded` and explain what it changes.
- Explain how a fixed `KC_HOSTNAME` decides the issuer.
- Keep health probes working when TLS is on, with `KC_HTTP_MANAGEMENT_SCHEME`.
- Check the certificate a server presents with `openssl s_client`.

## Before you start

You need Kubernetes basics: Deployments, Services, Secrets and `kubectl exec`. You need to know what an HTTP header is. You do not need to know TLS in detail; the first part explains what is needed.

Your playground is a single-node `kind` cluster. The namespace **`edge-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak 26.8.1 pod in development mode with HTTP only, behind the Service `keycloak` on port `8080` and `9000` |
| `tester` | A client pod with `curl`, `jq` and `openssl`. Every test request in this module is sent from here |

The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials; never use them on a real server. The reverse proxy in this module is not a running component. The tester pod plays its role by sending the headers a proxy would send.

Every command runs against the playground cluster, and `kubectl` already points at it. Keycloak takes a few minutes to start the first time, so start the playground now.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
