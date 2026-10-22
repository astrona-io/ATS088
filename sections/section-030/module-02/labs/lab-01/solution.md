# Solution: Move Keycloak To PostgreSQL With An Imported Realm

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the database settings with credentials from the Secret `keycloak-db`, the realm file mounted at the import folder with `--import-realm`, the realms `master` and `inventory` in PostgreSQL, and a token for `alice` with the right issuer.

## Step 1: Confirm where Keycloak stores its data today

Print the arguments and environment variable names of the Keycloak container, then ask PostgreSQL for its tables:

```sh
kubectl -n database-demo get deployment keycloak \
  -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}{.spec.template.spec.containers[0].env[*].name}{"\n"}'
kubectl -n database-demo exec deploy/postgres -- psql -U keycloak -d keycloak -c '\dt'
```

The arguments are `["start-dev"]`, and no `KC_DB` variable is set, so Keycloak uses its default `dev-file` database inside the pod. PostgreSQL answers that it did not find any relations: Keycloak has never written to it. That explains the lost realms.

## Step 2: Look at what you have to work with

Check the keys of the Secret and the ConfigMap, without printing the password:

```sh
kubectl -n database-demo get secret keycloak-db -o jsonpath='{.data}' | jq 'keys'
kubectl -n database-demo get configmap inventory-realm -o jsonpath='{.data}' | jq 'keys'
```

The Secret has the keys `password` and `username`. The ConfigMap has one key, `inventory-realm.json`. Mounted as a volume, that key becomes the file `inventory-realm.json`, which matches the `<realm name>-realm.json` convention for a realm file.

## Step 3: Write the new Deployment

The new Deployment adds five database variables, with the user name and password read through `secretKeyRef`, mounts the ConfigMap at `/opt/keycloak/data/import`, and adds `--import-realm` to `args`.

Save this as `deployment-keycloak.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: database-demo
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
          args: ["start-dev", "--import-realm"]
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

Then wait for the new pod and look for the import in its log:

```sh
kubectl -n database-demo rollout status deployment/keycloak --timeout=600s
kubectl -n database-demo logs deploy/keycloak | grep -i import
```

The rollout finishes once Keycloak has connected to PostgreSQL, created its tables and passed its probes. The log has a line that says the realm `inventory` was imported.

## Step 4: Prove the data lives in PostgreSQL

Ask PostgreSQL for the rows of the table `realm`:

```sh
kubectl -n database-demo exec deploy/postgres -- \
  psql -U keycloak -d keycloak -c 'select name from realm;'
```

The table lists `master` and `inventory`. Keycloak created `master` on its first start against the empty database, and the import created `inventory` from the file.

## Step 5: Prove the realm works

Ask the `inventory` realm for a token for `alice` and decode two claims of the access token. The password grant is used only to test from a terminal; OAuth 2.1 drops it, and a real application uses the authorization code flow:

```sh
kubectl -n database-demo exec deploy/tester -- curl -s \
  -d grant_type=password -d client_id=inventory-cli \
  -d username=alice -d password=alice-password -d scope=openid \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  | jq -r '.access_token | split(".")[1] | gsub("-";"+") | gsub("_";"/")
           | . + ("=" * ((4 - (length % 4)) % 4)) | @base64d | fromjson
           | {iss, preferred_username}'
```

The issuer is `http://keycloak:8080/realms/inventory` and the user is `alice`.

## Step 6: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Write `KC_DB_PASSWORD` as a plain `value` | it works, but the password is readable by anyone who can read the Deployment; the grader rejects it |
| Create `inventory` with `kcadm.sh` or the Admin Console | the realm exists, but the next empty server will not have it; the grader checks the import |
| Mount the ConfigMap but forget `--import-realm` | Keycloak never reads the folder, so the realm is not created |
| Mount the ConfigMap at `/opt/keycloak/data` | the file is not in the import folder, and the volume hides the rest of the data folder |

## Common mistakes

- Setting `KC_DB_URL_HOST` to the pod name instead of the Service name `postgres`.
- Expecting a changed ConfigMap to update a realm that already exists. A startup import skips existing realms.
- Judging the change before the rollout finishes. The first start against an empty database also creates every table, which takes extra time.

## Practice on your own

- Delete the Keycloak pod, wait for the new one, and check that `inventory` and `alice` are still there.
- Change the first name of `alice` in the ConfigMap, restart Keycloak, and explain why the token still shows the old name.
