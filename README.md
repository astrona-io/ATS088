# ATS088 — Fundamentals & Getting Started (Keycloak)

Course material for the **Fundamentals & Getting Started** domain of the
Astrona Keycloak training path ([ATP018](https://github.com/astrona-io/ATP018)),
which is **10% of the path**. Written for **Keycloak 26.8.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Keycloak 26.8.1 documentation. None has been started on a cluster,
> and no lab has passed `astrona test` yet. See `CLAUDE.md`.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** with a task, placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

Read a module, run its playground alongside it, work the module's lab without
looking at the solution, then finish the section with its capstone.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | OAuth 2.0, OpenID Connect And SAML In Keycloak | 1 | 1 + capstone | Identity protocols |
| [020](sections/section-020) | The Master Realm And Application Realms | 1 | 1 + capstone | Realms |
| [030](sections/section-030) | Running Keycloak From The Container Image | 2 | 2 + capstone | Running Keycloak |

The order goes from the outside in. Section 010 starts with what an
application gets from Keycloak: tokens, and the protocols that deliver them.
Section 020 shows where those tokens come from: a realm, and why it must not be
`master`. Section 030 ends with the server itself: the image, its
configuration, production mode and the database.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Get Tokens From Keycloak With OAuth 2.0 And OpenID Connect](sections/section-010/module-01/course.md) | 4 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Separate Administration From Applications With Realms](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Run Keycloak From The Container Image In Production Mode](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 030-02 | [Store Keycloak Data In PostgreSQL And Import A Realm](sections/section-030/module-02/course.md) | 2 | [lab-01](sections/section-030/module-02/labs/lab-01) |

---

## Capstones

One per section, each combining that section's modules into a single scenario
with several independent faults.

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Make A User Sign-In Work End To End | a client without the grant it needs, a disabled user, a pending required action |
| [020](sections/section-020/capstone/labs/lab-01) | Move An Application Out Of The Master Realm | a disabled application realm, a client and a user created in `master` |
| [030](sections/section-030/capstone/labs/lab-01) | Run A Production Keycloak On PostgreSQL | development mode, the `dev-file` database, health checks off, a realm file that is never imported |

---

## Running a playground

Every module has one: a **kind** cluster with Keycloak 26.8.1 deployed from
plain Kubernetes manifests and the module's starting state applied. Unlike a
lab, it is ungraded — it spins up, prepares the environment, and waits.

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

The environment name is the playground's `metadata.name` in its `config.yaml`,
for example `ats-088-playground-010-01`; each module's landing page launches its
playground. The first start pulls the Keycloak image and can take a few minutes.

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

`solution.md` is a full walkthrough — read it after you have tried the task,
not before. Each lab grades the **final cluster state** with independent
checks, and several of them deliberately reject the plausible-but-wrong fix
(switching on a grant the client should not have, a database password in plain
text, going back to `start-dev`, creating the application in `master`).
