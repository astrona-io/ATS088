# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Server configuration

## Scenario

The operations team collects Keycloak metrics with Prometheus and sends container logs to a log platform that only parses JSON. Keycloak in the namespace `ops-demo` has neither: the `/metrics` path is not served, and the logs are plain text. The team also wants more detail about user events while it investigates a sign-in problem, but not debug output from the whole server.

## Your task

In the namespace `ops-demo`:

1. Turn on metrics with `KC_METRICS_ENABLED`.
2. Switch the console log output to JSON with `KC_LOG_CONSOLE_OUTPUT`.
3. Set `KC_LOG_LEVEL` so that the root level stays `info` and the category `org.keycloak.events` logs at `debug`.
4. Wait until the new pod is ready, then request `/metrics` on the management port and read a log line.

## Constraints

- Keep `KC_HEALTH_ENABLED=true`. The probes of the Deployment need it.
- Do not set the root log level to `debug`.
- Do not switch to a different image tag or change the command.

## Done when

- `http://keycloak:9000/metrics` returns status `200` from the `tester` pod and lists JVM metrics.
- The newest log lines of the running pod are JSON objects.
- `KC_LOG_LEVEL` starts with `info` and sets `org.keycloak.events` to `debug`.
- The `keycloak` Deployment is available.
