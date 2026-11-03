# Troubleshooting TLS And Proxy Problems

TLS and proxy faults rarely say what is wrong. The browser shows a certificate warning, a redirect loop or an error about a redirect address, and each symptom can come from the certificate, the proxy or the Keycloak settings. This part lists the common symptoms, names the layer behind each, and gives one check per layer so you can narrow the cause quickly.

## Check one layer at a time

A request passes through a chain: the client, the TLS connection, the proxy, the Keycloak listener and the Keycloak application. Test the chain from the inside out. First ask whether the pod is ready and its log is clean. Then ask whether the port answers. Then ask which certificate it presents. Last, ask which addresses Keycloak puts in its answers.

<!-- astrona:playground:renew -->

Start with the log and the readiness of the pod. The log names the options Keycloak could not use:

```sh
kubectl -n edge-demo get pods
kubectl -n edge-demo logs deploy/keycloak --tail=30
```

A ready pod shows `1/1`. A pod that restarts has an error near the end of the log, such as a certificate file that cannot be read. Check which options the Deployment actually sets:

```sh
kubectl -n edge-demo get deploy keycloak \
  -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
```

Compare the paths in `KC_HTTPS_CERTIFICATE_FILE` and `KC_HTTPS_CERTIFICATE_KEY_FILE` with the mount path of the volume. A path that differs by one directory is the most common cause of a pod that does not start.

## Symptoms and causes

| Symptom | Likely cause |
| --- | --- |
| The pod restarts, and the log names a certificate path | The file is not at that path, or the Secret has other key names than `tls.crt` and `tls.key` |
| The pod runs but is never ready | The probes use HTTP on a management port that now expects HTTPS. Set `KC_HTTP_MANAGEMENT_SCHEME=http` |
| `curl` exits with code `60` | The client does not trust the certificate. Use `--cacert` with the certificate, or `-k` in a lab |
| A certificate error that names a host | The host name is not in the SAN list |
| Login redirects to `http://` addresses behind a proxy | `KC_PROXY_HEADERS` is not set, or the proxy does not send `X-Forwarded-Proto` |
| Error page: invalid parameter `redirect_uri` | The client registered `https://` addresses, and Keycloak builds the request as `http://` |
| Tokens carry an issuer that applications reject | The hostname or the forwarded host differs from the address applications use |
| The server does not start in production mode | No `KC_HOSTNAME`, and neither TLS nor `KC_HTTP_ENABLED` |

## Read the certificate and trust it properly

When the cause is the certificate, read what the server presents. Request it with `openssl s_client`, which prints the chain and the verification result:

```sh
kubectl -n edge-demo exec deploy/tester -- sh -c \
  'openssl s_client -connect keycloak:8443 -servername keycloak </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates'
```

For a self-signed certificate the subject and the issuer are the same. Instead of skipping validation with `-k`, tell `curl` which certificate to trust. Copy the certificate into the tester pod and use `--cacert`:

```sh
kubectl -n edge-demo exec deploy/tester -- sh -c \
  'openssl s_client -connect keycloak:8443 -servername keycloak </dev/null 2>/dev/null | openssl x509 > /tmp/server.crt
   curl -s -o /dev/null -w "%{http_code}\n" --cacert /tmp/server.crt https://keycloak:8443/realms/master'
```

If the certificate is valid for the host name, the request returns `200` without `-k`. The host used in the URL must be in the SAN list, so a request to `https://keycloak:8443` works and a request to a name outside the list fails. This is the same check a real client makes.

## Check the addresses Keycloak returns

Last, read the issuer and the endpoints in the discovery document, and compare them with the address applications use:

```sh
kubectl -n edge-demo exec deploy/tester -- \
  curl -sk https://keycloak:8443/realms/master/.well-known/openid-configuration \
  | jq '{issuer, authorization_endpoint, token_endpoint}'
```

All three values must start with the public address of the service. If they start with an internal name, check `KC_HOSTNAME`. If they use `http` where the public address uses `https`, check the proxy headers.

You now have a method for TLS and proxy faults: read the log, read the options, test the port, read the certificate, then read the addresses. A symptom points to one layer, and one check confirms it.

## Common pitfalls

> [!WARNING]
> - **Skipping validation with `-k` and trusting the result.** It hides certificate faults that real clients will meet.
> - **Changing several options at once.** Change one, wait for the rollout, and test again.
> - **Reading the log of the old pod.** Use the log of the new pod after a rollout.
> - **Treating a redirect loop as a Keycloak bug.** It is often a proxy that sends the wrong protocol header.
> - **Testing only from inside the cluster.** The public path through the proxy can differ.
