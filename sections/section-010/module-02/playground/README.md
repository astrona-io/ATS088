# Sign Users In With The Authorization Code Flow And PKCE — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-088-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that spins up, deploys Keycloak 26.8.1 in the
namespace `authcode-demo`, creates the objects the module uses, and stays running
so you can explore the module's topic. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-088-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-088-playground-010-02`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Deploys Keycloak and creates the realm objects |
| `manifests/lab-start.yaml` | Namespace, Keycloak, Service and tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
