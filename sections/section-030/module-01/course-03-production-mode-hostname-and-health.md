# Production Mode, The Hostname And Health Checks

Development mode is built for speed, not safety. It accepts plain HTTP, trusts whatever hostname a request uses, and keeps its caches on one machine. A real server must not do any of that, so production mode turns those defaults around and refuses to start until you choose. This part switches the playground server to production mode, reads why it stops, and gives it the settings it asks for. It ends with the health checks Kubernetes uses to know the server is ready.

## What changes between `start-dev` and `start`

`kc.sh start-dev` and `kc.sh start` run the same server with different defaults. The table lists the defaults that matter on day one:

| Setting | `start-dev` (development mode) | `start` (production mode) |
| --- | --- | --- |
| HTTP listener | On | Off |
| HTTPS (TLS) | Not required | Required, unless HTTP is turned on |
| `hostname` | Not required; taken from each request | Required, or `hostname-strict` must be `false` |
| `hostname-strict` | `false` | `true` |
| Caches | Local to the one server | Shared between servers |
| Theme and template caching | Off, so theme changes show at once | On |
| `db` default | `dev-file` | `dev-file`, with a deprecation warning |

The rule behind the table is that production mode is **secure by default**. Keycloak does not guess a safe hostname or a safe transport for you. Without them, it does not start.

## Switch the server to production mode

See the refusal before you fix it. The Deployment below is the playground's Deployment with one change: `args` is `start` instead of `start-dev`. The Deployment uses the `Recreate` strategy, so Kubernetes stops the old pod before it starts the new one.

<!-- astrona:playground:renew -->

Save this as `deployment-keycloak-start.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: image-demo
  labels:
    app: keycloak
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:26.8.1
          args: ["start"]
          env:
            - name: KC_BOOTSTRAP_ADMIN_USERNAME
              valueFrom:
                secretKeyRef:
                  name: keycloak-admin
                  key: username
            - name: KC_BOOTSTRAP_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-admin
                  key: password
            - name: KC_HEALTH_ENABLED
              value: "true"
          ports:
            - name: http
              containerPort: 8080
            - name: management
              containerPort: 9000
          startupProbe:
            httpGet:
              path: /health/started
              port: management
            periodSeconds: 5
            failureThreshold: 60
          readinessProbe:
            httpGet:
              path: /health/ready
              port: management
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health/live
              port: management
            periodSeconds: 10
          resources:
            requests:
              memory: 768Mi
              cpu: 250m
            limits:
              memory: 1536Mi
```

Apply it:

```sh
kubectl apply -f deployment-keycloak-start.yaml
```

Then watch the pod and read its log:

```sh
kubectl -n image-demo get pods -l app=keycloak -w
kubectl -n image-demo logs deploy/keycloak
```

Stop the watch with Ctrl+C once the pod has restarted a few times. The pod goes to `Error` and then `CrashLoopBackOff`: the Keycloak process exits on its own, and Kubernetes restarts it. The log explains why. Near the end, Keycloak reports that the hostname is not configured, or that no key material (certificate and private key) is set up for HTTPS, and it names the options that would fix it. It may also warn that `dev-file` is deprecated in production mode; that warning does not stop the server.

The probes are not the cause here. The process stops before it opens any port, so `kubectl logs` is the first place to look. If the log shows the previous attempt only, add `--previous`.

## Give production mode what it asks for

Production mode needs two decisions. The first is the **hostname**: the public address of the server, which Keycloak writes into every token as part of the issuer (`iss`) and into every link it sends to a browser. The option `hostname` accepts a host name such as `keycloak.example.com` or a full URL such as `https://keycloak.example.com`. A full URL also fixes the scheme and the port.

The second decision is the **transport**. A real server either has its own certificate (TLS options such as `https-certificate-file`) or sits behind a reverse proxy that ends TLS and forwards plain HTTP. The second case is common on Kubernetes, where an ingress controller ends TLS. For that case you turn the HTTP listener back on with `http-enabled=true`. In the playground there is no certificate and no proxy, so HTTP on port `8080` is the only choice, and the hostname is the Service address the `tester` pod uses: `http://keycloak:8080`.

Pass both as command-line options. Save this as `deployment-keycloak-production.yaml`; only the `args` line differs from the file above:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: image-demo
  labels:
    app: keycloak
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:26.8.1
          args: ["start", "--hostname=http://keycloak:8080", "--http-enabled=true"]
          env:
            - name: KC_BOOTSTRAP_ADMIN_USERNAME
              valueFrom:
                secretKeyRef:
                  name: keycloak-admin
                  key: username
            - name: KC_BOOTSTRAP_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-admin
                  key: password
            - name: KC_HEALTH_ENABLED
              value: "true"
          ports:
            - name: http
              containerPort: 8080
            - name: management
              containerPort: 9000
          startupProbe:
            httpGet:
              path: /health/started
              port: management
            periodSeconds: 5
            failureThreshold: 60
          readinessProbe:
            httpGet:
              path: /health/ready
              port: management
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health/live
              port: management
            periodSeconds: 10
          resources:
            requests:
              memory: 768Mi
              cpu: 250m
            limits:
              memory: 1536Mi
```

Apply it:

```sh
kubectl apply -f deployment-keycloak-production.yaml
```

Then check the result:

```sh
kubectl -n image-demo rollout status deployment/keycloak --timeout=600s
kubectl -n image-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/master/.well-known/openid-configuration | jq -r .issuer
```

The rollout finishes, and the issuer is `http://keycloak:8080/realms/master`. The issuer is the URL of the realm that signs tokens. It is built from the hostname you set, followed by `/realms/` and the realm name.

## What `hostname-strict` protects

The hostname matters most when a request uses a different name. Send the same request again, but tell Keycloak it was addressed to `localhost:8080` with a `Host` header:

```sh
kubectl -n image-demo exec deploy/tester -- \
  curl -s -H 'Host: localhost:8080' http://keycloak:8080/realms/master/.well-known/openid-configuration | jq -r .issuer
```

The issuer stays `http://keycloak:8080/realms/master`. With a hostname set and `hostname-strict` at its default `true`, Keycloak ignores the request's own `Host` header when it builds URLs. In development mode the same request returns `http://localhost:8080/realms/master`, because Keycloak takes the hostname from each request there.

That is the attack `hostname-strict` blocks. If Keycloak trusts the `Host` header, anyone who can reach it can make it put a hostname of their choice into tokens and links, for example into a password-reset email. So `--hostname-strict=false` is only safe when no untrusted client can reach Keycloak directly and a reverse proxy sets or overwrites the header. For the same reason, `proxy-headers` (`forwarded` or `xforwarded`) tells Keycloak to read the `Forwarded` or `X-Forwarded-*` headers. Turn it on only behind a proxy that overwrites those headers on every request.

## Health checks on the management port

Kubernetes needs to know when the server can take requests. Keycloak answers that on its **management interface**, a second HTTP listener on port `9000`, kept apart from the port users reach. It serves four health endpoints once `health-enabled` is `true`:

| Endpoint | What it says | Probe that uses it |
| --- | --- | --- |
| `/health/started` | The server has finished starting | `startupProbe` |
| `/health/live` | The server process is running | `livenessProbe` |
| `/health/ready` | The server can process requests, including its database connection | `readinessProbe` |
| `/health` | All checks together | none |

Each endpoint answers `200` with a JSON body whose `status` is `UP` when the check passes, and `503` with `DOWN` when it fails. Ask the ready endpoint from the `tester` pod:

```sh
kubectl -n image-demo exec deploy/tester -- curl -s http://keycloak:9000/health/ready
```

The body is a small JSON object with `"status": "UP"`. If health were off, the request would fail to connect. Keycloak turns the management interface off completely when nothing is exposed on it, and with health and metrics both off, nothing is. Every probe in the Deployment then fails, and Kubernetes never marks the pod ready.

The management interface follows the main server's TLS settings by default. Here the server has no certificate, so port `9000` speaks plain HTTP. With a certificate set, it would speak HTTPS, and the probes would need `scheme: HTTPS`, or `http-management-scheme=http` to keep it on HTTP.

You can now run Keycloak in production mode: you know what it refuses to start without, how to give it a hostname and a transport, and how the health endpoints tell Kubernetes it is ready. The question still open is where the server keeps its data, because this production server still writes everything to `dev-file` inside the pod.

## Common pitfalls

> [!WARNING]
> - **Going back to `start-dev` to make the error go away.** The server then starts, but with HTTP, a hostname taken from each request and development caches. Fix the missing settings instead.
> - **Setting `hostname-strict=false` instead of a hostname.** It makes the server start, and it lets any client choose the hostname in tokens and links.
> - **A hostname without the scheme and port when they matter.** `keycloak` alone takes the scheme and port from each request. Use a full URL such as `http://keycloak:8080` when the issuer must be fixed.
> - **Looking at the probes first.** When the process exits during startup, the probes only say "connection refused". The reason is in `kubectl logs`.
> - **Turning health off and keeping the probes.** With health and metrics off, port `9000` is closed, and the pod never becomes ready.

## Your mission: Start Keycloak In Production Mode

You can now read why production mode refuses to start and give it a hostname, HTTP and health checks. The graded lab gives you a Keycloak pod that someone switched to `start` and that crashes on every start, and asks you to make it ready in production mode with environment variables, without going back to `start-dev` and without turning off `hostname-strict`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-088-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-088-lab-030-01
astrona start ats-088-playground-030-01
```
