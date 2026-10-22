# Solution: Start Keycloak In Production Mode

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the pod is ready and `/health/ready` answers `UP`, the container runs `start` and never `start-dev` with `hostname-strict` left on, `KC_HOSTNAME` and `KC_HTTP_ENABLED` are set as environment variables, and the issuer stays `http://keycloak:8080/realms/master` for any `Host` header.

## Step 1: See the failure

Look at the Keycloak pod:

```sh
kubectl -n image-demo get pods -l app=keycloak
```

The pod shows `0/1`, a growing `RESTARTS` count, and the status `Error` or `CrashLoopBackOff`. The Keycloak process exits by itself, and Kubernetes keeps restarting it. A pod that exits during startup has not opened any port yet, so the probes cannot tell you why.

## Step 2: Read the reason in the log

Read the log of the Keycloak container. If the current attempt has just started, read the previous one:

```sh
kubectl -n image-demo logs deploy/keycloak
kubectl -n image-demo logs deploy/keycloak --previous
```

Near the end, Keycloak says that it cannot start in production mode as it is configured. It reports that the hostname is not configured, or that no key material (certificate and private key) is set up for HTTPS, and it names the options that would fix it. It may also warn that the `dev-file` database is deprecated in production mode; that warning does not stop the server.

So two settings are missing. Production mode needs a **hostname**, and it needs a **transport**: either TLS with a certificate, or the HTTP listener turned on explicitly.

## Step 3: Check the current container settings

Print the arguments and the environment variable names of the container:

```sh
kubectl -n image-demo get deployment keycloak \
  -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}{.spec.template.spec.containers[0].env[*].name}{"\n"}'
```

The arguments are `["start"]`. The environment holds the two bootstrap administrator variables and `KC_HEALTH_ENABLED`, and nothing about the hostname or HTTP. That matches the log.

## Step 4: Add the hostname and HTTP as environment variables

The option `hostname` becomes the environment variable `KC_HOSTNAME`, and `http-enabled` becomes `KC_HTTP_ENABLED`. Use the full URL `http://keycloak:8080`, so the scheme and port in the issuer are fixed too.

Save this as `deployment-keycloak.yaml`:

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
            - name: KC_HOSTNAME
              value: "http://keycloak:8080"
            - name: KC_HTTP_ENABLED
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
kubectl apply -f deployment-keycloak.yaml
```

Then wait for the new pod:

```sh
kubectl -n image-demo rollout status deployment/keycloak --timeout=600s
```

The rollout finishes once the new pod passes its startup and readiness probes. `kubectl -n image-demo set env deployment/keycloak KC_HOSTNAME=http://keycloak:8080 KC_HTTP_ENABLED=true` makes the same change in one command, if you prefer it.

## Step 5: Prove the result

Ask the ready endpoint on the management port, then the issuer, once normally and once with another `Host` header:

```sh
kubectl -n image-demo exec deploy/tester -- curl -s http://keycloak:9000/health/ready
kubectl -n image-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/master/.well-known/openid-configuration | jq -r .issuer
kubectl -n image-demo exec deploy/tester -- \
  curl -s -H 'Host: localhost:8080' http://keycloak:8080/realms/master/.well-known/openid-configuration | jq -r .issuer
```

The ready endpoint answers a JSON body with the status `UP`. Both issuer requests print `http://keycloak:8080/realms/master`. The second one proves that the hostname is fixed: Keycloak ignores the `Host` header the request claims.

## Step 6: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change `args` back to `start-dev` | the pod starts, but in development mode; the grader rejects `start-dev` |
| Set `KC_HOSTNAME_STRICT=false` and no hostname | the pod may start, but any client can choose the hostname in tokens and links; the grader rejects it |
| Set only `KC_HOSTNAME` | production mode still requires TLS or HTTP, so the pod keeps failing |
| Put the options in `args` instead of `env` | Keycloak starts, but the task asks for environment variables, and the grader checks them |
| Delete the probes so the pod counts as ready | the process still exits, and the task forbids changing the probes |

## Common mistakes

- Looking at the probe messages first. They only say the connection was refused; the reason is in `kubectl logs`.
- Writing `KC_HOSTNAME=keycloak` without the scheme and port. Keycloak then takes those from each request, and the issuer is no longer fully fixed.
- Judging a change too early. A production start takes a minute or two; wait for `rollout status`.

## Practice on your own

- Set the same hostname once in `args` and once, with a different value, in `env`. Predict which one appears in the issuer before you check.
- Remove `KC_HEALTH_ENABLED` and describe what happens to the probes and to port `9000`.
