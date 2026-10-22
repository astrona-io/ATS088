# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Running Keycloak

## Scenario

A colleague read that `start-dev` must never run in production. They changed the Keycloak Deployment in the namespace `image-demo` from `start-dev` to `start` and changed nothing else. Since then, the Keycloak pod restarts again and again, and no request reaches the server.

## Your task

In the namespace `image-demo`:

1. Find out from the cluster why Keycloak does not start.
2. Make Keycloak start and become ready **in production mode**. Configure it with **environment variables** on the `keycloak` container:
   - the hostname is the full URL `http://keycloak:8080`;
   - the HTTP listener is turned on, because there is no certificate in this cluster.
3. Prove the result from the `tester` pod: the ready endpoint on the management port answers `UP`, and the `master` realm's discovery document shows the issuer `http://keycloak:8080/realms/master`.

## Constraints

- **Keep production mode.** The container must run `start`. Do not use `start-dev` anywhere, and do not replace the image entrypoint with `command`.
- **Do not turn off strict hostname checks.** `hostname-strict` must not be `false`, in `args` or in `env`.
- Keep the image `quay.io/keycloak/keycloak:26.8.1`, the Service and the probes as they are.

## Done when

- The `keycloak` Deployment has a ready pod, and `http://keycloak:9000/health/ready` answers `UP` to the `tester` pod.
- The container's first argument is `start`, and `start-dev` appears nowhere.
- `KC_HOSTNAME` is `http://keycloak:8080` and `KC_HTTP_ENABLED` is `true` in the container's environment.
- The `master` realm's issuer is `http://keycloak:8080/realms/master`, also for a request sent with the header `Host: localhost:8080`.
