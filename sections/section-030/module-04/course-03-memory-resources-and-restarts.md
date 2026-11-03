# Memory, Resources And Restarts

Keycloak runs on the Java virtual machine (JVM), and it needs memory for the heap, which holds the objects the program creates, and for other areas outside the heap. A container has a memory limit, and Kubernetes ends a container that goes over it. A pod that restarts without any error in the log is often this case. This part shows how to read the limits and the reason for a restart.

## Requests, limits and the heap

A Kubernetes **resource request** is the amount of memory and CPU the scheduler reserves for a container. A **limit** is the amount the container may not exceed. For memory, a container that goes over its limit is killed by the kernel, and Kubernetes records the reason `OOMKilled` (out of memory). The container then restarts, and the restart count goes up.

Keycloak sets the JVM heap as a percentage of the container memory limit, not as a fixed number. By default the maximum heap is 70 percent of the limit and the initial heap is 50 percent. The rest of the limit is for memory outside the heap, such as thread stacks and caches. The percentages are applied only when the container has a memory limit, so always set one. The options `JAVA_OPTS_KC_HEAP` can override the heap settings, and `JAVA_OPTS_APPEND` adds other JVM options.

<!-- astrona:playground:renew -->

Read the resources of the playground server:

```sh
NAMESPACE=ops-demo
kubectl -n "$NAMESPACE" get deploy keycloak \
  -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```

The output shows a request of `768Mi` memory and `250m` CPU and a memory limit of `1536Mi`. With the default percentages, the maximum heap is about 70 percent of `1536Mi`. Now read the state of the pod, which includes the restart count and the reason for the last termination:

```sh
kubectl -n "$NAMESPACE" get pods -l app=keycloak
kubectl -n "$NAMESPACE" get pod -l app=keycloak \
  -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}{"\n"}{.items[0].status.containerStatuses[0].lastState}{"\n"}'
```

A healthy pod shows a restart count of `0` and an empty last state. A pod that was killed for memory shows a `terminated` state with the reason `OOMKilled`.

## Cause a memory kill on purpose

Lower the memory limit to a value that is too small for the server, and watch the pod. Save this as `patch-keycloak-memory.yaml`:

```yaml
spec:
  template:
    spec:
      containers:
        - name: keycloak
          resources:
            requests:
              memory: 256Mi
            limits:
              memory: 256Mi
```

Apply it and watch:

```sh
kubectl -n "$NAMESPACE" patch deployment keycloak --patch-file patch-keycloak-memory.yaml
kubectl -n "$NAMESPACE" get pods -l app=keycloak -w
```

The new pod restarts, because the server needs more memory than the limit allows. Stop the watch with `Ctrl+C`. Read the reason:

```sh
kubectl -n "$NAMESPACE" describe pod -l app=keycloak | grep -A6 'Last State'
```

The last state shows `Terminated` with the reason `OOMKilled`, or the pod stays in `CrashLoopBackOff` between restarts. The log of the killed container ends without an error message, because the kernel ends the process. Restore the limit by saving the original values:

```yaml
spec:
  template:
    spec:
      containers:
        - name: keycloak
          resources:
            requests:
              memory: 768Mi
            limits:
              memory: 1536Mi
```

Save it as `patch-keycloak-memory-restore.yaml`, then apply it and wait for the rollout:

```sh
kubectl -n "$NAMESPACE" patch deployment keycloak --patch-file patch-keycloak-memory-restore.yaml
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
```

## The probes and restarts

Three probes use the management port. The **startup** probe uses `/health/started` and gives the server time to start. The **liveness** probe uses `/health/live` and restarts the container when the server does not answer. The **readiness** probe uses `/health/ready` and removes the pod from the Service when the server cannot take requests, for example when the database is not reachable. A liveness probe that is too strict restarts a slow server that only needed more time, so the startup probe must allow enough time.

You now know how limits become a heap size, how to read a kill, and which probe does what. The open question is how to change a running server without losing data, and how to approach a fault you have not seen before.

## Common pitfalls

> [!WARNING]
> - **Running without a memory limit.** The heap percentages need a limit, and the pod can use all memory of the node.
> - **Setting the limit equal to the heap you want.** The server also needs memory outside the heap.
> - **Reading only the log after a restart.** A kill by the kernel leaves no message in the log. Read `lastState`.
> - **A short startup probe.** The liveness probe then restarts a server that is still starting.
> - **Sizing for one user.** Sizing depends on the number of sessions and realms, so measure with the metrics.
