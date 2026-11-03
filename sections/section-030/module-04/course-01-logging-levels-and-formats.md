# Logging Levels And Formats

When a sign-in fails, the first question is what the server did. Keycloak writes its log to the console of the container, and Kubernetes keeps that output for `kubectl logs`. Two settings decide how useful the log is: the level, which controls how much detail is written, and the format, which controls whether a person or a program reads it. This part sets both.

## Levels and categories

A **log level** says how important a message is. From quiet to detailed they are `error`, `warn`, `info`, `debug` and `trace`. The server writes every message at or above the configured level. The default level is `info`. A **category** is the name of the part of the code that writes a message, such as `org.keycloak.events` for the events system. A level can be set for the whole server (the root) or for one category.

The option is `log-level`, set with the environment variable `KC_LOG_LEVEL`. Its value is a comma-separated list. An item without a category sets the root level. An item written as `category:level` sets one category. For example, `info,org.keycloak.events:debug` keeps the root at `info` and writes debug messages only for events. Setting the root to `debug` makes every component write debug messages, which is rarely wanted.

<!-- astrona:playground:renew -->

Read the newest lines of the log of the playground server:

```sh
NAMESPACE=ops-demo
kubectl -n "$NAMESPACE" logs deploy/keycloak --tail=5
```

The lines are plain text. Each line starts with a time stamp, a level and a category, followed by the message. Show the options of the Deployment and look for log settings:

```sh
show_options() {
  kubectl -n "$NAMESPACE" get deploy keycloak \
    -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
}
show_options
```

No `KC_LOG_*` option is set, so the defaults apply: the handler is `console`, the output is the default text format and the level is `info`.

## Change the level of one category

Raise only the events category and wait for the restart:

```sh
kubectl -n "$NAMESPACE" set env deployment/keycloak KC_LOG_LEVEL=info,org.keycloak.events:debug
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
```

Sign in as the administrator through the token endpoint, which creates a login event, and read the log:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null http://keycloak:8080/realms/master/protocol/openid-connect/token \
    -d grant_type=password -d client_id=admin-cli -d username=admin -d password=admin
kubectl -n "$NAMESPACE" logs deploy/keycloak --tail=10
```

The new lines come from the events category and describe the event. The level applies to that category only; the rest of the log is as quiet as before. Debug output also writes more data about requests, so use it for an investigation and then set the level back.

## JSON output

A log platform reads structured data better than text. The option `log-console-output` (`KC_LOG_CONSOLE_OUTPUT`) accepts `default` and `json`. With `json`, every line is one JSON object with fields such as the time stamp, the level and the logger name, so a program can filter on the fields. Switch to it:

```sh
kubectl -n "$NAMESPACE" set env deployment/keycloak KC_LOG_CONSOLE_OUTPUT=json
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" logs deploy/keycloak --tail=3 | jq -r '.level + " " + .loggerName'
```

The command prints a level and a logger name for each line, because every line is valid JSON. Keycloak can also write to a file with `log=console,file`, but in a container the console is the right place, because Kubernetes collects it.

You now know the levels, how a category gets its own level, and how to make the log machine-readable. The open question is how to see numbers, not messages, about a server.

## Common pitfalls

> [!WARNING]
> - **Setting the root level to `debug` in production.** The log grows quickly and may contain request details.
> - **Writing `category=level`.** The separator is a colon.
> - **Reading the log of the old pod after a change.** Wait for the rollout, then read the new pod.
> - **Writing logs to a file inside the container.** The file is lost when the pod restarts, and Kubernetes does not collect it.
> - **Leaving debug on after an investigation.** Set the level back.
