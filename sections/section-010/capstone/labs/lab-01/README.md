---
estimated_duration: 30m
---

# Make A User Sign-In Work End To End

- **ID:** CAPSTONE
- **Slug:** ats-088-capstone-010
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab (section capstone)

Graded capstone for the namespace `protocolscapstone-demo`. Three independent
faults stop the user `alice` from getting tokens: the client `inventory-cli`
does not allow the password grant, `alice` is disabled, and `alice` has a
temporary password (the `UPDATE_PASSWORD` required action). Read
`question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This capstone was written from the Keycloak 26.8.1
> documentation and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-088-capstone-010
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-088-capstone-010`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough with a submit loop |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation run once at startup |
| `manifests/` | Starting workloads applied by the bootstrap |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs before the reference solution |
| `validation/` | Grading scripts, one per check |
