# Solution: Run A Production Keycloak On PostgreSQL

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader runs seven checks: the pod is ready and `/health/ready` answers `UP`, the container runs `start` with `hostname-strict` on, the `inventory` issuer is fixed, the database settings come from the Secret, the realm file is mounted with `--import-realm`, PostgreSQL lists `master` and `inventory`, and `alice` gets a token with the right issuer.

## Step 1: See why the pod is not ready

Look at the pod and its events:

```sh
kubectl -n runcapstone-demo get pods -l app=keycloak
kubectl -n runcapstone-demo describe pod -l app=keycloak | sed -n '/Events:/,$p'
```

The pod shows `0/1` and restarts now and then. The events show the startup probe failing with a refused connection on port `9000`, and Kubernetes killing the container after the startup probe has failed too often. Port `9000` is the management interface. Keycloak opens it only when health or metrics is turned on.

## Step 2: Read the whole Deployment, not only the first fault

Print the arguments and environment variable names, and the volume mounts:

```sh
kubectl -n runcapstone-demo get deployment keycloak \
  -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}{.spec.template.spec.containers[0].env[*].name}{"\n"}{.spec.template.spec.containers[0].volumeMounts}{"\n"}'
kubectl -n runcapstone-demo logs deploy/keycloak | grep -iE 'profile|database|import'
```

Four faults are visible, and each one is independent of the others:

| What you see | Fault |
| --- | --- |
| `args` is `["start-dev"]` | development mode, not production mode |
| no `KC_HEALTH_ENABLED` | health is off, so port `9000` is closed and every probe fails |
| no `KC_DB` variables | Keycloak uses `dev-file` inside the pod; PostgreSQL is unused |
| no volume mount, no `--import-realm` | the `inventory` realm is never created |

The log confirms the development profile and says nothing about importing a realm. Fixing only the health setting would make the pod ready, but in development mode and on `dev-file`. That is why every item of the task needs its own check.

## Step 3: Check what the namespace gives you

Check the keys of the Secret and the ConfigMap:

```sh
kubectl -n runcapstone-demo get secret keycloak-db -o jsonpath='{.data}' | jq 'keys'
kubectl -n runcapstone-demo get configmap inventory-realm -o jsonpath='{.data}' | jq 'keys'
```

The Secret has `password` and `username`, and the ConfigMap has `inventory-realm.json`.

## Step 4: Write the production Deployment

One Deployment fixes all four faults. It runs `start --import-realm`, turns health on, sets the hostname and HTTP, reads the database credentials from the Secret, and mounts the realm file at the import folder.

Save this as `deployment-keycloak.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: runcapstone-demo
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
          args: ["start", "--import-realm"]
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
            - name: KC_DB
              value: postgres
            - name: KC_DB_URL_HOST
              value: postgres
            - name: KC_DB_URL_DATABASE
              value: keycloak
            - name: KC_DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: keycloak-db
                  key: username
            - name: KC_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-db
                  key: password
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
          volumeMounts:
            - name: realm-import
              mountPath: /opt/keycloak/data/import
              readOnly: true
      volumes:
        - name: realm-import
          configMap:
            name: inventory-realm
```

Apply it:

```sh
kubectl apply -f deployment-keycloak.yaml
```

Then wait for the new pod:

```sh
kubectl -n runcapstone-demo rollout status deployment/keycloak --timeout=600s
```

The first production start against an empty database takes longer than a development start: Keycloak builds, creates its tables in PostgreSQL and imports the realm before the probes pass.

## Step 5: Prove each item

Check the health endpoint and the issuer, once normally and once with another `Host` header:

```sh
kubectl -n runcapstone-demo exec deploy/tester -- curl -s http://keycloak:9000/health/ready
kubectl -n runcapstone-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/.well-known/openid-configuration | jq -r .issuer
kubectl -n runcapstone-demo exec deploy/tester -- \
  curl -s -H 'Host: localhost:8080' http://keycloak:8080/realms/inventory/.well-known/openid-configuration | jq -r .issuer
```

The ready endpoint answers `UP`, and both requests print `http://keycloak:8080/realms/inventory`. Now check the database and the token:

```sh
kubectl -n runcapstone-demo exec deploy/postgres -- \
  psql -U keycloak -d keycloak -c 'select name from realm;'
kubectl -n runcapstone-demo exec deploy/tester -- curl -s \
  -d grant_type=password -d client_id=inventory-cli \
  -d username=alice -d password=alice-password -d scope=openid \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  | jq -r '.access_token | split(".")[1] | gsub("-";"+") | gsub("_";"/")
           | . + ("=" * ((4 - (length % 4)) % 4)) | @base64d | fromjson
           | {iss, preferred_username}'
```

PostgreSQL lists `master` and `inventory`, and the token names the issuer `http://keycloak:8080/realms/inventory` and the user `alice`. The password grant is used here only to test from a terminal; OAuth 2.1 drops it, and a real application uses the authorization code flow.

## Step 6: Submit

Send the capstone for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Turn health on and stop there | the pod becomes ready, but in development mode on `dev-file`, without the realm |
| Remove the probes so the pod counts as ready | the task forbids it, and nothing tells Kubernetes when Keycloak can serve requests |
| Switch to `start` with `KC_HOSTNAME_STRICT=false` and no hostname | the issuer follows each request's `Host` header; the grader rejects it |
| Write the database password as a plain `value` | the password is readable in the Deployment; the grader rejects it |
| Create `inventory` with `kcadm.sh` | the realm exists, but the next empty server will not have it; the grader checks the import |

## Common mistakes

- Fixing the first fault and assuming the rest will follow. The four faults are independent.
- Turning health on but pointing the probes at port `8080`. The health endpoints live on the management port `9000`.
- Judging the result before the rollout finishes. The first production start does the most work.
