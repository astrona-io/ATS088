# Summary

Keycloak reports on itself in two ways: its console log and its management port. The console log is collected by Kubernetes and read with `kubectl logs`. The option `KC_LOG_LEVEL` sets the root level and, with `category:level` items, the level of single categories, so an investigation can raise one part of the server without flooding the log. The option `KC_LOG_CONSOLE_OUTPUT=json` makes every line a JSON object that a log platform can parse.

The management interface listens on port `9000`. It serves the health paths `/health/started`, `/health/live` and `/health/ready`, and the metrics path `/metrics` when `KC_METRICS_ENABLED` is true. The metrics use the Prometheus text format, with counters that only rise and gauges that move. They show JVM memory, request rates and, when event metrics are on, counts of user events. The management port has no user authentication and stays inside the cluster.

A container needs a memory limit. Keycloak sizes the Java heap as a percentage of that limit, and a container that goes over the limit is killed with the reason `OOMKilled`, which leaves no message in the log. The startup, liveness and readiness probes each use a health path, and a short startup probe makes the liveness probe restart a server that is still starting.

An upgrade migrates the database schema, and the migration can be one-way, so the safe order is release notes, database backup, a pinned image tag, rollout and checks. Troubleshooting follows the facts in order: pod state and events, current and previous logs, the three health paths, then one change at a time.

Key facts:

- `KC_LOG_LEVEL=info,org.keycloak.events:debug` keeps the root at `info` and raises one category.
- `KC_METRICS_ENABLED` and `KC_HEALTH_ENABLED` are build options and serve their paths on port `9000`.
- The default maximum heap is 70 percent of the container memory limit.
- `kubectl logs --previous` shows the log of the container before the last restart.

<!-- astrona:playground:destroy -->
