# Reverse Proxy Headers

A reverse proxy answers the client, then opens its own connection to Keycloak. From Keycloak's point of view, every request comes from the proxy, over the proxy's protocol, to the proxy's address. Keycloak needs the original values to build correct links, redirects and the issuer of tokens. The proxy passes them in HTTP headers, and Keycloak must be told to trust those headers. This part shows the headers, the option that enables them, and the fixed hostname that decides the issuer.

## The forwarding headers

A proxy adds headers that describe the original request. The `X-Forwarded-*` family is the most common:

| Header | What it carries |
| --- | --- |
| `X-Forwarded-For` | The address of the client that made the request |
| `X-Forwarded-Proto` | The protocol the client used, `http` or `https` |
| `X-Forwarded-Host` | The host name the client used |
| `X-Forwarded-Port` | The port the client used |

The standard `Forwarded` header carries the same facts in one header. Keycloak reads either family, chosen by the option `proxy-headers` (environment variable `KC_PROXY_HEADERS`), with the values `xforwarded` or `forwarded`. If the option is not set, Keycloak ignores all of these headers. That is a safe default, because any client can send a forged header. Enable the option only when a proxy you control sets or overwrites the headers on every request, and the proxy is the only way to reach Keycloak.

<!-- astrona:playground:renew -->

See the default behavior in the playground. Define the helper again if this is a new terminal, then send a request that looks like it passed through a proxy:

```sh
NAMESPACE=edge-demo
show_issuer() {
  base_url="$1"; shift
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -sk "$@" "$base_url/realms/master/.well-known/openid-configuration" | jq -r .issuer
}
show_issuer http://keycloak:8080 -H 'X-Forwarded-Proto: https' -H 'X-Forwarded-Host: id.example.test'
```

The issuer still shows the address of the request, `http://keycloak:8080/realms/master`, because the option `proxy-headers` is not set and Keycloak ignores the headers. Turn it on:

```sh
kubectl -n edge-demo set env deployment/keycloak KC_PROXY_HEADERS=xforwarded
kubectl -n edge-demo rollout status deployment/keycloak --timeout=600s
```

Send the same request again:

```sh
show_issuer http://keycloak:8080 -H 'X-Forwarded-Proto: https' -H 'X-Forwarded-Host: id.example.test'
```

The issuer is now `https://id.example.test/realms/master`. Keycloak read the protocol and the host from the headers. This development-mode server has no fixed hostname, so the headers decide the address.

## A fixed hostname

In production mode the hostname is required. The option `hostname` (`KC_HOSTNAME`) accepts a host name or a full URL. A full URL, for example `https://id.example.test`, fixes the scheme, the host and the port that Keycloak uses in the addresses it creates, in the issuer, in redirects and in the Admin Console. With a fixed URL, a forged `X-Forwarded-Host` cannot change the issuer. A fixed hostname is the stronger setting. The proxy-headers option still matters for the client address in the logs and events, and for the protocol of the request.

Set the hostname on the playground server and compare:

```sh
kubectl -n edge-demo set env deployment/keycloak KC_HOSTNAME=https://id.example.test
kubectl -n edge-demo rollout status deployment/keycloak --timeout=600s
show_issuer http://keycloak:8080 -H 'X-Forwarded-Host: other.example.test'
```

The issuer is `https://id.example.test/realms/master`, even though the request sent another host. The fixed URL won over the header.

## What a graded setup needs

A production server behind a proxy that still sends HTTP to port `8080` runs `start` with `KC_HOSTNAME`, `KC_HTTP_ENABLED=true` and `KC_PROXY_HEADERS`. If the proxy sends HTTPS to port `8443`, the server also needs the certificate options from the previous part. Both listeners can run together, so a proxy can use port `8080` while pods in the cluster use `8443`. Only a proxy should reach port `8080`, and Kubernetes network policies are the tool for that.

You now know the headers a proxy sends, how `KC_PROXY_HEADERS` enables them, and how a fixed `KC_HOSTNAME` decides the issuer. The open question is how to prove all of this on a production-mode server and what to read when it fails. First, practise it.

## Common pitfalls

> [!WARNING]
> - **Enabling `proxy-headers` without a proxy that overwrites the headers.** Clients can forge their address and protocol.
> - **Choosing `forwarded` when the proxy sends `X-Forwarded-*`.** Keycloak then reads headers that do not exist.
> - **Expecting `proxy-headers` to fix the issuer in production mode.** The fixed `KC_HOSTNAME` URL decides the issuer.
> - **Leaving port `8080` open to every pod when only the proxy needs it.** Restrict it with a network policy.

## Your mission: Serve Keycloak Over HTTPS Behind A Reverse Proxy

You can now give Keycloak a certificate, trust a proxy's headers and keep a fixed hostname. The graded lab gives you a production-mode server that serves only HTTP and asks you to mount the Secret, set the certificate and proxy options, and open port `8443`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-088-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-088-lab-030-03
astrona start ats-088-playground-030-03
```
