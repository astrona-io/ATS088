# Observe And Operate Keycloak

A Keycloak server that runs is not the same as a Keycloak server that is understood. When sign-ins slow down or a pod restarts, the operator needs three sources of facts: logs that say what the server did, metrics that show how much work it does, and health checks that say whether it can serve requests. Without them, every fault is a guess.

Logging is the text or JSON lines that the server writes to its console. Metrics are numbers about the running server, such as memory use and request counts, that a monitoring system collects at intervals. A health check is an HTTP path that reports whether the server is alive, ready or started. Operating the server also means giving it enough memory and changing its version without losing data.

Keep one sentence in mind: **Keycloak reports on itself through its console log and through the management port 9000, and every option that controls them is an environment variable on the Deployment.** This module shows the log options, turns on metrics, explains memory limits and restarts, and gives a method for the common faults.

The module has four parts. **Logging Levels And Formats** sets the level and the JSON output. **Metrics On The Management Port** turns on `/metrics`; a graded lab follows it. **Memory, Resources And Restarts** reads the container limits and the reasons for a restart. **Operating And Troubleshooting** covers upgrades and a method for faults.

## Learning objectives

After this module you can:

- Read Keycloak logs with `kubectl logs`, and set the root level and the level of one category with `KC_LOG_LEVEL`.
- Switch the console output to JSON with `KC_LOG_CONSOLE_OUTPUT`.
- Turn on metrics with `KC_METRICS_ENABLED` and read `/metrics` on port `9000`.
- Name the three health paths and what each one reports.
- Explain how container memory limits and the Java heap relate, and read an `OOMKilled` restart.
- Describe a safe upgrade: back up the database, change the image tag, wait for the rollout.

## Before you start

You need Kubernetes basics: Deployments, pods, and the commands `kubectl logs`, `kubectl describe` and `kubectl set env`. You do not need to know Prometheus; the second part explains the format.

Your playground is a single-node `kind` cluster. The namespace **`ops-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak 26.8.1 pod in development mode with health checks on, behind the Service `keycloak` on port `8080` and `9000` |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials; never use them on a real server.

Every command runs against the playground cluster, and `kubectl` already points at it. Keycloak takes a few minutes to start the first time, so start the playground now.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
