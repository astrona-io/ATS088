# Operating And Troubleshooting

Running Keycloak means changing it: a new version, a new setting, a new certificate. Each change restarts the pod, and a restart that goes wrong is an outage. This part gives a safe order for an upgrade and a method for finding the cause of a fault from the facts the earlier parts showed.

## A safe upgrade

Keycloak stores its data in a database. At start, the server checks the schema version of the database and migrates it to the version of the new software. This migration can be one-way: after a newer version has changed the schema, an older version may refuse to start against it. So a rollback of the image tag is not always enough.

The safe order is short. First, read the release notes of the new version for changes in options. Second, back up the database. Third, change the image tag in the Deployment, pinned to an exact version and never `latest`. Fourth, wait for the rollout and check the health paths and the log. If the new version fails, restore the database backup and set the old tag.

<!-- astrona:playground:renew -->

Check the image the playground server runs and the rollout history of the Deployment:

```sh
NAMESPACE=ops-demo
kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n "$NAMESPACE" rollout history deployment/keycloak
```

The image is `quay.io/keycloak/keycloak:26.8.1`. The history lists one revision for each change of the Deployment, which you can use to see what changed. A Deployment with more than one replica needs a database that all replicas share and a cache that connects them, so one pod and the development database used here are for learning only.

## A method for faults

When something is wrong, work from the facts Kubernetes already has before you change anything. First read the state of the pod and the events. Then read the log of the current container, and the log of the previous container if it restarted. Then test the ports from inside the cluster. Only then change one setting.

```sh
kubectl -n "$NAMESPACE" get pods -l app=keycloak
kubectl -n "$NAMESPACE" describe pod -l app=keycloak | tail -15
kubectl -n "$NAMESPACE" logs deploy/keycloak --tail=20
```

The `describe` output ends with the events: the image pull, the scheduling and any failing probes. A probe failure appears there with the path and the status. Use `logs --previous` for a container that restarted, because the current container only holds the log since the restart. Then test the three management paths:

```sh
for path in /health/started /health/live /health/ready; do
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w "$path %{http_code}\n" "http://keycloak:9000$path"
done
```

Each path prints its status. A server that is alive but not ready, with `/health/live` at `200` and `/health/ready` at `503`, is usually waiting for a dependency such as the database.

| Symptom | First place to look |
| --- | --- |
| Pod restarts, log ends without an error | `lastState` for `OOMKilled` |
| Pod never becomes ready | Probe events in `describe`, then `/health/ready` and the database |
| Pod in `CrashLoopBackOff` with an error in the log | `logs --previous` for the first error |
| Slow sign-ins | Metrics: heap use, garbage collection pauses, database pool |
| Many failed logins | Events and the user event metrics |
| New version does not start | Schema migration errors in the log; restore the backup and the old tag |

You now have the order of work for an operator: read the state, read the events, read the log, test the ports, change one thing, and read again. The metrics tell you whether the change helped.

## Common pitfalls

> [!WARNING]
> - **Upgrading without a database backup.** A migration can make a rollback of the image impossible.
> - **Using `latest` as the image tag.** A restart can silently change the version.
> - **Changing several settings at once.** Change one, wait for the rollout and read the result.
> - **Reading only the current log of a restarting container.** Use `--previous`.
> - **Treating a failing readiness probe as a Keycloak bug.** Often the database is not reachable.
