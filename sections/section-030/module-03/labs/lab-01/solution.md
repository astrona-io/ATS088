# Solution: Serve Keycloak Over HTTPS Behind A Reverse Proxy

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the Deployment mounts the Secret and sets the two certificate options and `KC_PROXY_HEADERS`; the Service has the port `8443`; an HTTPS request from the `tester` pod returns the discovery document with the right issuer; and the Deployment is available.

## Step 1: Read the starting state

Show the options and the ports of the running server:

```sh
kubectl -n edge-demo get deploy keycloak \
  -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
kubectl -n edge-demo get svc keycloak
kubectl -n edge-demo get secret keycloak-tls
```

The options are `KC_HOSTNAME`, `KC_HTTP_ENABLED`, `KC_HEALTH_ENABLED` and `KC_HTTP_MANAGEMENT_SCHEME`, with no certificate and no proxy setting. The Service has only the ports `8080` and `9000`, and the Secret has the type `kubernetes.io/tls`.

## Step 2: Change the Deployment

Save this as `deployment-keycloak-tls.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: edge-demo
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
            - name: KC_HTTP_MANAGEMENT_SCHEME
              value: "http"
            - name: KC_HOSTNAME
              value: "https://id.example.test"
            - name: KC_HTTP_ENABLED
              value: "true"
            - name: KC_PROXY_HEADERS
              value: "xforwarded"
            - name: KC_HTTPS_CERTIFICATE_FILE
              value: "/opt/keycloak/conf/tls/tls.crt"
            - name: KC_HTTPS_CERTIFICATE_KEY_FILE
              value: "/opt/keycloak/conf/tls/tls.key"
          ports:
            - name: http
              containerPort: 8080
            - name: https
              containerPort: 8443
            - name: management
              containerPort: 9000
          volumeMounts:
            - name: tls
              mountPath: /opt/keycloak/conf/tls
              readOnly: true
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
      volumes:
        - name: tls
          secret:
            secretName: keycloak-tls
```

Apply it:

```sh
kubectl apply -f deployment-keycloak-tls.yaml
```

The Deployment uses the `Recreate` strategy, so Kubernetes stops the old pod before it starts the new one.

## Step 3: Open the port on the Service

Save this as `service-keycloak.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: keycloak
  namespace: edge-demo
  labels:
    app: keycloak
spec:
  selector:
    app: keycloak
  ports:
    - name: http
      port: 8080
      targetPort: http
    - name: https
      port: 8443
      targetPort: https
    - name: management
      port: 9000
      targetPort: management
```

Apply it and wait for the new pod:

```sh
kubectl apply -f service-keycloak.yaml
kubectl -n edge-demo rollout status deployment/keycloak --timeout=600s
```

## Step 4: Request the discovery document over HTTPS

Send the request from the `tester` pod. The `-k` option skips certificate checking, because the certificate is self-signed:

```sh
kubectl -n edge-demo exec deploy/tester -- \
  curl -sk https://keycloak:8443/realms/master/.well-known/openid-configuration | jq -r .issuer
```

The issuer is `https://id.example.test/realms/master`. The server answers over TLS on port `8443`, and the fixed hostname decides the address in the document.

## Step 5: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Switch to `start-dev` | The server starts without the production checks; the task keeps `start` |
| Paste the key into an environment variable | The key is readable in the Deployment; the task requires the Secret |
| Remove `KC_HTTP_ENABLED` | The reverse proxy loses its plain HTTP path to port `8080` |
| Forget the Service port | The pod serves HTTPS, but `keycloak:8443` is unreachable from other pods |

## Common mistakes

- Using a mount path that does not match the `KC_HTTPS_CERTIFICATE_FILE` value.
- Checking the result before the new pod is ready. The old pod may still answer on port `8080`.
- Reading `curl` exit code 60 as a failure of Keycloak. It reports an untrusted self-signed certificate; use `-k` or `--cacert`.
- Expecting `KC_PROXY_HEADERS` to change the issuer. A fixed `KC_HOSTNAME` URL decides the issuer.

## Practice on your own

- Save the certificate from the Secret to a file in the `tester` pod and call the server with `--cacert` instead of `-k`.
- Break the key path on purpose, apply it, and read the error in `kubectl logs`. Then fix it.
- Remove `KC_HOSTNAME` and compare the issuer with forwarded headers.
