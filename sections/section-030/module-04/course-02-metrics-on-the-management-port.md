# Metrics On The Management Port

A log tells a person what happened. It does not show whether the server is using more memory every hour, or how many requests per second it serves. Metrics do, and a monitoring system such as Prometheus collects them by sending an HTTP request to the server at regular intervals. This part turns on the Keycloak metrics endpoint, reads its format, and ends with a graded lab.

## The management interface

Keycloak serves health checks and metrics on a separate port, the **management interface**, which listens on port `9000`. It is separate from the main port `8080` so that operations traffic and user traffic do not share a listener, and the management port can be kept away from the public network. The paths are `/health`, `/health/live`, `/health/ready`, `/health/started` and `/metrics`. The options `KC_HEALTH_ENABLED` and `KC_METRICS_ENABLED` turn on the health and metrics paths. Both are build options, so a start with a new value rebuilds the configuration, which makes the first start slower.

<!-- astrona:playground:renew -->

Check what the playground server serves today:

```sh
NAMESPACE=ops-demo
management_status() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' "http://keycloak:9000$1"
}
management_status /health/ready
management_status /metrics
```

The health path returns `200`. The metrics path does not, because metrics are off. Turn them on:

```sh
kubectl -n "$NAMESPACE" set env deployment/keycloak KC_METRICS_ENABLED=true
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
management_status /metrics
```

The status is now `200`.

## The Prometheus text format

The response is plain text in the Prometheus exposition format. A line that starts with `#` is a comment: `# HELP` describes a metric and `# TYPE` names its type. Other lines hold a metric name, optional labels in braces and a value. A **counter** only goes up, for example the number of requests. A **gauge** goes up and down, for example the memory in use. Read some lines:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s http://keycloak:9000/metrics | grep -m6 '^jvm_'
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s http://keycloak:9000/metrics | grep -m4 '^http_server'
```

The first command prints metrics about the Java virtual machine, such as `jvm_memory_used_bytes` and `jvm_gc_pause_seconds_count`. The second prints metrics about HTTP requests handled by the server. The metric names and labels come from the running version, so read them from your own server and not from a guide.

## Event metrics and what to watch

User events can also become metrics. The option `event-metrics-user-enabled` (`KC_EVENT_METRICS_USER_ENABLED`) adds counters for events such as logins and failed logins, labelled by realm. These counters help to see a spike in failed sign-ins without reading the log. Operators usually watch four groups of metrics: JVM memory and garbage collection pauses, the request rate and latency, the counts of failed events, and the database connection pool.

Prometheus collects the endpoint with a scrape configuration, or in Kubernetes with a monitoring resource that points at the Service port `9000`. The scrape must reach the management port, so the Service needs the `management` port, as in this module. Keep the management port inside the cluster. It has no user authentication.

You now know how to turn metrics on, where they are served and how to read the format. The open question is what the numbers mean for a container that has a memory limit. First, practise logs and metrics together.

## Common pitfalls

> [!WARNING]
> - **Expecting metrics on port `8080`.** They are on the management port `9000`.
> - **Exposing the management port to the internet.** It has no user authentication.
> - **Forgetting that `KC_METRICS_ENABLED` is a build option.** A start with a new value takes longer, and a pre-built optimized image needs the value at build time.
> - **Copying metric names from another version.** Read them from your own `/metrics`.
> - **Alerting on a single sample.** Use rates and thresholds over a time window.

## Your mission: Expose Metrics, Use JSON Logs And Raise One Log Category

You can now set the log level and format, and turn on metrics. The graded lab gives you a server with health checks only and asks you to turn on metrics, switch to JSON logs, and raise one log category without raising the root level.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-088-playground-030-04
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-030/module-04/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-04/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-088-lab-030-04
astrona start ats-088-playground-030-04
```
