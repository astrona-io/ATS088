# Section 020: The Master Realm And Application Realms

Keycloak keeps everything it knows in **realms**. A realm is a space in Keycloak that holds its own users, clients, roles, groups and settings, and one realm cannot see the objects of another. The first realm you ever meet is `master`, which Keycloak creates at its first start. It holds the administrator account, and it is easy to keep using it for everything.

This section explains why you should not. The `master` realm is for administration only: its users can manage every realm on the server. An application and its users belong in a realm of their own, an **application realm**, with its own URLs, its own signing keys and its own issuer. The section ends with the tool you use to build such a realm from the terminal: `kcadm.sh`, Keycloak's administration command-line tool.

**Topic covered:** Realms

## What you will learn

- What the `master` realm is for, and why an application's clients and users do not belong in it.
- How the bootstrap administrator is created from `KC_BOOTSTRAP_ADMIN_USERNAME` and `KC_BOOTSTRAP_ADMIN_PASSWORD`, and why Keycloak marks that account as temporary.
- What a realm holds: users and their credentials, clients, roles, groups, realm settings and signing keys.
- The URLs every realm publishes, and why the issuer of a token names exactly one realm.
- Signing `kcadm.sh` in to the `master` realm and using it to create, read, update and delete realms, users and clients.

## The learning path

Work through the module in order. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Separate Administration From Applications With Realms

The module starts at its landing page, which also launches the playground. The playground holds the namespace `realms-demo` with one Keycloak pod that has only the `master` realm. Everything else you create yourself.

1. The Master Realm And The Bootstrap Administrator
2. What A Realm Holds, And Its URLs
3. Managing Realms With kcadm.sh, followed by the lab **Create An Application Realm With kcadm.sh**
4. Summary

## Section capstone: Move An Application Out Of The Master Realm

The capstone is one graded scenario that uses the whole module. In the namespace `realmscapstone-demo`, a team created the realm `inventory` but left it disabled, and then put their client and their user into `master` to get started. Your task is to move the application into its own realm and leave `master` with nothing but administration. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-088-capstone-020
```
