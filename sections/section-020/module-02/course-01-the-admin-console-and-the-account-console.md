# The Admin Console And The Account Console

A new administrator opens the Keycloak address in a browser and sees a welcome page with no obvious next step. Keycloak has two web interfaces with different users and different addresses, and knowing which is which saves time when a sign-in fails. This part names the addresses, shows how to reach them in the playground, and finds the clients that sit behind them.

## Two consoles, two audiences

The **Admin Console** is the web interface for administrators. Its address is `/admin/<realm>/console/`; the administrator of the `master` realm opens `/admin/master/console/` and can switch to any realm from the menu. The **Account Console** is the web interface for the users of one realm. Its address is `/realms/<realm>/account`. A user changes their own name, password, two-factor setup and sessions there, and sees the applications they signed in to.

Neither console is a separate program. Each one is a single-page web application that runs in the browser and is a client of Keycloak itself. The Admin Console is the public client `security-admin-console` in the realm that is being managed. The Account Console is the public client `account-console` of its own realm. When you open either address, the application sends you to the Keycloak login page with the authorization code flow and PKCE, and then calls the Admin REST API (or the account API) with the access token it receives.

<!-- astrona:playground:renew -->

Look at the clients that every realm starts with:

```sh
NAMESPACE=adminapi-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory --fields clientId,publicClient
```

The list holds `account`, `account-console`, `admin-cli`, `broker`, `realm-management`, `security-admin-console` and the clients created for this module. Keycloak creates the first six with every realm. `admin-cli` is the public client that command-line tools use to sign in with a user name and password. `realm-management` is not used to sign in; it only holds the administration roles, which the third part explains.

## Open the consoles from your machine

The cluster network is not reachable from your browser, so forward the Service to your machine. Keep this command running in its own terminal:

```sh
kubectl -n adminapi-demo port-forward svc/keycloak 8080:8080
```

Open `http://localhost:8080/admin` in the browser. Keycloak redirects to the sign-in page of the `master` realm. Sign in as `admin` with the password `admin`. In the realm list at the top left, choose `inventory` and open **Users** and **Clients** to see the objects you saw with `kcadm.sh`. Then open `http://localhost:8080/realms/inventory/account`, which asks for a login in the realm `inventory`. Sign in as `alice` with the password `alice-password` to see what a user sees: no realm list and no administration menu.

Both pages use the issuer `http://localhost:8080/realms/...`, because you reached Keycloak through `localhost:8080`. Tokens requested from inside the cluster through `keycloak:8080` carry a different issuer, so do not mix the two when you compare tokens.

## What the Admin Console does underneath

Every action in the Admin Console is a call to the Admin REST API. Open the browser's developer tools and the **Network** tab, then change a setting: you see requests such as `PUT /admin/realms/inventory`. This is why anything you can click can also be scripted, and why a person or a tool needs the same administration roles in both cases.

You now know the two consoles, their addresses and the clients behind them. You also know that the consoles are clients of Keycloak and call the Admin REST API. The open question is how to call that API yourself, which is the next part.

## Common pitfalls

> [!WARNING]
> - **Using the Account Console to administer.** It manages one user's own data. Administration is in the Admin Console.
> - **Administering application realms from inside `master` users.** The `master` administrator can manage every realm; give application teams an account in their own realm with limited roles.
> - **Expecting the port-forward address to work from a pod.** `localhost:8080` exists on your machine only. Pods use `keycloak:8080`.
> - **Deleting `admin-cli` or `security-admin-console`.** The command-line tools and the Admin Console stop working.
