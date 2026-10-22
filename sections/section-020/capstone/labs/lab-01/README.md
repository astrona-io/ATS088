---
estimated_duration: 30m
---

# Move An Application Out Of The Master Realm

- **ID:** CAPSTONE
- **Slug:** ats-088-capstone-020
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab (section capstone)

Graded capstone for the namespace `realmscapstone-demo`. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this capstone was written from the Keycloak 26.8.1 documentation
and has not passed `astrona validate` or `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-088-capstone-020
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-088-capstone-020`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation and the faulty starting state |
| `manifests/` | Workloads applied by the bootstrap |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs before the reference solution |
| `validation/` | Grading scripts, one per check |
