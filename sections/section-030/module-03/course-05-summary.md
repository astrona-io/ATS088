# Summary

Keycloak carries passwords, codes and tokens, so production traffic must be encrypted. TLS can end at a reverse proxy, which sends plain HTTP to Keycloak, or at Keycloak itself, with the proxy either re-encrypting the last hop or passing the encrypted bytes through. The choice decides which certificates exist and whether Keycloak can see the original client address.

A production server started with `start` needs a hostname, and either a certificate or `http-enabled` for a proxy that ends TLS. When Keycloak serves HTTPS itself, it reads a PEM certificate and key from the files named by `https-certificate-file` and `https-certificate-key-file`. A Kubernetes Secret of type `kubernetes.io/tls` holds them, and the Deployment mounts it read-only. The certificate must list the used host names in its Subject Alternative Names.

A reverse proxy passes the original protocol, host and client address in `X-Forwarded-*` or `Forwarded` headers. Keycloak ignores them unless `proxy-headers` is set, and the setting must only be used when a trusted proxy overwrites the headers. A fixed `hostname` URL decides the issuer and the addresses in redirects, whatever the headers say. When a certificate is configured, the management interface inherits TLS, so health probes need `http-management-scheme` set to `http`, or HTTPS probes.

Troubleshooting follows the chain from the inside out: the pod log and options, the port, the certificate that the server presents, and the addresses in the discovery document.

Key facts:

- `KC_HTTPS_CERTIFICATE_FILE` and `KC_HTTPS_CERTIFICATE_KEY_FILE` set the certificate and the key.
- `KC_PROXY_HEADERS` takes `xforwarded` or `forwarded`.
- `KC_HOSTNAME` with a full URL fixes the issuer.
- `curl` exit code `60` reports a certificate that the client does not trust.

<!-- astrona:playground:destroy -->
