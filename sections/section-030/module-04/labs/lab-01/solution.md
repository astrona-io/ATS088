# Solution: Expose Metrics, Use JSON Logs And Raise One Log Category

Work the task yourself first. Running `astrona submit -c sections/section-030/module-04/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the management port serves `/metrics` with JVM metrics; the running pod writes JSON log lines; and `KC_LOG_LEVEL` keeps the root level at `info` while it sets the events category to `debug`.

## Step 1: Read the starting state

```sh
NAMESPACE=ops-demo
kubectl -n "$NAMESPACE" get deploy keycloak \
  -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' http://keycloak:9000/metrics
kubectl -n "$NAMESPACE" logs deploy/keycloak --tail=3
```

The options hold the bootstrap administrator and `KC_HEALTH_ENABLED`. The metrics path does not return `200`, and the log lines are plain text.

## Step 2: Set the three options

```sh
kubectl -n "$NAMESPACE" set env deployment/keycloak \
  KC_METRICS_ENABLED=true \
  KC_LOG_CONSOLE_OUTPUT=json \
  KC_LOG_LEVEL=info,org.keycloak.events:debug
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
```

The value of `KC_LOG_LEVEL` is a comma-separated list. The first item without a category sets the root level, and each `category:level` item sets one category. Metrics are a build option, so Keycloak rebuilds its configuration when the new pod starts, which makes this start slower.

## Step 3: Check the result

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s http://keycloak:9000/metrics | grep -m3 '^jvm_'
kubectl -n "$NAMESPACE" logs deploy/keycloak --tail=3 | jq -r '.level + " " + .loggerName'
```

The metrics response holds lines for JVM metrics, and each log line is a JSON object.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-04/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set `KC_LOG_LEVEL=debug` | Every component logs at debug level, which floods the log platform |
| Forget `KC_HEALTH_ENABLED` while editing the options | The probes fail and the pod never becomes ready |
| Read the log of the old pod | It shows the old text format |
| Run `kc.sh build` by hand in the pod | The change is lost when the pod restarts. Set the option on the Deployment |

## Common mistakes

- Writing `KC_LOG_LEVEL=info,org.keycloak.events=debug`. The separator between category and level is a colon.
- Testing before the new pod is ready.
- Expecting metrics on port `8080`. They are served on the management port `9000`.

## Practice on your own

- Sign in as `admin` and look for event lines in the log.
- Set `KC_EVENT_METRICS_USER_ENABLED=true` and search `/metrics` for `keycloak_user_events`.
- Set `KC_LOG_CONSOLE_OUTPUT=default` again and compare.
