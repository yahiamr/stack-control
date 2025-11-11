# stackctl – Portable Docker Compose helpers

A tiny, plug-and-play shell add-on that gives you ergonomic commands to manage one or many Docker Compose “stacks” from anywhere.

* One file to drop in: `~/.config/stackctl/stackctl.sh`
* Works with **bash** and **zsh**
* Stack settings are simple env vars (project name, root dir, compose files, env file)
* Per-stack overrides via `/srv/.stackrc`
* Safe defaults; nothing global is modified except your shell session

---

## 1) Quick install

1. Create the plugin directory and save the helper:

```bash
mkdir -p ~/.config/stackctl
nano ~/.config/stackctl/stackctl.sh
# (paste the stackctl.sh contents here)
```

2. Source it from your shell profile:

```bash
echo 'source ~/.config/stackctl/stackctl.sh' >> ~/.bashrc    # or ~/.zshrc
source ~/.bashrc
```

3. (Optional) Create a per-stack overrides file so settings live **with** your stack:

```bash
cat >/srv/.stackrc <<'RC'
STACK_NAME="yayaxeon (prod)"
STACK_PROJECT="yayaxeon"
STACK_ROOT="/srv"
STACK_FILES="docker-compose.core.yml docker-compose.proxy.yml"
STACK_ENV_FILE="/srv/.env"
RC
```

That’s it. You now have the `dc` helper and `stack-*` aliases.

---

## 2) Default variables (override anytime)

* `STACK_ROOT` — folder containing your compose files (default `/srv`)
* `STACK_PROJECT` — Compose project name (default `yayaxeon`)
* `STACK_FILES` — space-separated list of compose files (default `docker-compose.core.yml docker-compose.proxy.yml`)
* `STACK_ENV_FILE` — path to the env file (default `${STACK_ROOT}/.env`)
* `STACK_NAME` — friendly label for `stack-info` (optional)

Override order (lowest → highest precedence):

1. Built-in defaults in `stackctl.sh`
2. `/srv/.stackrc` (or `${STACK_ROOT}/.stackrc`)
3. Variables you export **before** sourcing the plugin
4. `stack-use` (temporary for the current shell)

---

## 3) Commands & aliases

Core runner (always executes in `STACK_ROOT`):

```bash
dc <compose-args...>
# example: dc config --services
```

Common tasks:

```bash
stack-up                # docker compose up -d
stack-down              # docker compose down
stack-stop              # docker compose stop
stack-restart           # down && up -d
stack-ps                # table view of running containers
stack-logs              # follow all services' logs
stack-logs-svc <svc>    # logs for one service
stack-up-svc <svc>      # up -d for one service
stack-stop-svc <svc>    # stop one service
stack-restart-svc <svc> # restart one service
stack-env               # print effective env (from STACK_ENV_FILE)
stack-info              # print current settings
```

Service name autocompletion works for the `*-svc` helpers (bash).

---

## 4) Typical workflows (use cases)

### A) Daily ops

```bash
stack-up
stack-ps
stack-logs-svc caddy
stack-restart-svc n8n
stack-down     # (when you want to remove containers but keep data)
```

### B) Edit env and roll

```bash
nano /srv/.env
stack-restart
```

### C) Add a third compose file (e.g., monitoring)

Edit `/srv/.stackrc`:

```bash
STACK_FILES="docker-compose.core.yml docker-compose.proxy.yml docker-compose.monitoring.yml"
```

Then:

```bash
stack-up
```

### D) Work on another stack temporarily

```bash
stack-use /opt/other-stack otherproj docker-compose.yml
stack-up
stack-info
# open a new shell (or run stack-use again) to switch back:
stack-use /srv yayaxeon docker-compose.core.yml docker-compose.proxy.yml
```

### E) Per-service lifecycle

```bash
stack-up-svc code-server
stack-logs-svc n8n
stack-stop-svc jupyter
```

---

## 5) Extending stackctl

* **More aliases**: Add your own, e.g., `alias stack-rebuild='dc up -d --build'`.
* **Preflight checks**: Write small functions that validate `STACK_ENV_FILE` keys before `stack-up`.
* **Health commands**:

  ```bash
  stack-health() { curl -fsS "https://${N8N_FQDN:-n8n.yayaxeon.bond}/rest/healthz" || echo "n8n unhealthy"; }
  ```
* **Multiple envs**: Keep `/srv/.stackrc` files per environment and swap `STACK_ROOT` with `stack-use`.

---

## 6) Troubleshooting

* **“No such project” / nothing stops:** You might be using a different project name. Run `stack-info` and ensure `STACK_PROJECT` matches the one that launched the containers. To detect a running project name:

  ```bash
  docker inspect caddy --format '{{ index .Config.Labels "com.docker.compose.project" }}'
  ```

* **Compose can’t find files:** Confirm `STACK_ROOT` and `STACK_FILES`. Run `ls` inside `STACK_ROOT`:

  ```bash
  (cd "$STACK_ROOT" && ls -1 ${STACK_FILES})
  ```

* **Env not applied:** Check `STACK_ENV_FILE` exists and `stack-env` prints variables.

---

## 7) Uninstall / disable

* Remove the `source` line from your `~/.bashrc` / `~/.zshrc`.
* Delete `~/.config/stackctl/stackctl.sh`.
* Optionally delete `/srv/.stackrc`.

---

## 8) Security notes

* `stackctl` merely wraps `docker compose` with explicit file/env paths. It doesn’t mount sockets or escalate privileges.
* Keep your `.env` out of version control and restrict permissions (`chmod 600 /srv/.env`).
* Only include compose files you trust in `STACK_FILES`.

---

## 9) FAQ

**Q: Can I have different stacks per user or repo?**
Yes. Use `stack-use` to switch on the fly, or create multiple `.stackrc` files in different roots.

**Q: Can I call raw compose commands?**
Yes: `dc <args>` passes anything through (e.g., `dc config --services`, `dc pull`, `dc rm -f`).

**Q: Will it work with Portainer “stacks”?**
`stackctl` is for local Compose on the host. Portainer manages its own stack state. You can use both, but treat your on-disk compose files as the source of truth.

---
