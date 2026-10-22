# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Running Keycloak

## Scenario

The inventory team needs Keycloak in the namespace `runcapstone-demo` to go live next week. Someone copied the Deployment from a laptop test. The pod never becomes ready, Kubernetes keeps restarting it, and the realm the application needs is not there. A PostgreSQL server, a Secret with its credentials and a ConfigMap with the realm file are already in the namespace.

## Your task

In the namespace `runcapstone-demo`, bring the `keycloak` Deployment to a production-ready state:

1. Find every reason the pod is not ready, from the pod's events, its probes and its log.
2. Run Keycloak **in production mode** with the hostname `http://keycloak:8080` and the HTTP listener on, because there is no certificate in this cluster.
3. Make the health endpoints available on the management port `9000`, so the existing probes pass.
4. Store all data in PostgreSQL: host `postgres`, database `keycloak`, user name and password from the Secret `keycloak-db`.
5. Create the realm `inventory` from the ConfigMap `inventory-realm` when Keycloak starts.

## Constraints

- **Production mode only.** The container must run `start`; `start-dev` must appear nowhere. Do not replace the image entrypoint with `command`.
- **Keep strict hostname checks.** `hostname-strict` must not be `false`.
- **No password in the Deployment.** `KC_DB_USERNAME` and `KC_DB_PASSWORD` must use `secretKeyRef` to the Secret `keycloak-db`.
- **Import the realm from the file** at `/opt/keycloak/data/import` with `--import-realm`. Do not create it with the Admin Console or `kcadm.sh`.
- Keep the image `quay.io/keycloak/keycloak:26.8.1`, the Service and the probes as they are. Do not change the Secrets, the ConfigMap, the `postgres` Deployment or the `tester` pod.

## Done when

- The `keycloak` Deployment has a ready pod, and `http://keycloak:9000/health/ready` answers `UP` to the `tester` pod.
- The container's first argument is `start`, `start-dev` appears nowhere, and `hostname-strict` is not turned off.
- The issuer of the `inventory` realm is `http://keycloak:8080/realms/inventory`, also for a request sent with the header `Host: localhost:8080`.
- `KC_DB` is `postgres` with host `postgres` and database `keycloak`, and the credentials come from the Secret `keycloak-db`.
- `select name from realm;` in PostgreSQL lists `master` and `inventory`.
- The user `alice` (password `alice-password`) gets an access token from the `inventory` realm through the client `inventory-cli`, with the issuer `http://keycloak:8080/realms/inventory`.
