# ===== stackctl: portable Docker-Compose helpers =====
# Drop-in plugin: source from ~/.bashrc or ~/.zshrc
# Defaults (override via env or a .stackrc file):
: "${STACK_ROOT:=/srv}"                       # folder containing your compose files
: "${STACK_PROJECT:=yayaxeon}"                # compose project name
: "${STACK_ENV_FILE:=${STACK_ROOT}/.env}"     # env file passed to compose
: "${STACK_FILES:=docker-compose.core.yml docker-compose.proxy.yml}"  # space-separated
: "${STACK_NAME:=yayaxeon}"                   # a friendly display name

# Optional: per-project overrides file (shell syntax: KEY=VALUE)
[ -f "${STACK_ROOT}/.stackrc" ] && . "${STACK_ROOT}/.stackrc"

# Build the compose command dynamically from variables
stackctl::_compose_cmd() {
  local files=(${STACK_FILES})
  local args=()
  for f in "${files[@]}"; do args+=("-f" "$f"); done
  echo docker compose -p "${STACK_PROJECT}" "${args[@]}" --env-file "${STACK_ENV_FILE}"
}

# Always run from STACK_ROOT so relative compose paths resolve
dc() { ( cd "${STACK_ROOT}" && eval "$(\stackctl::_compose_cmd)" "$@" ); }

# Aliases / helpers (safe to use in both bash & zsh)
alias stack-up='dc up -d'                       # start (or recreate changed services)
alias stack-down='dc down'                      # remove containers (keep volumes)
alias stack-stop='dc stop'                      # stop containers (keep created)
alias stack-restart='dc down && dc up -d'       # clean restart
alias stack-ps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Logs
alias stack-logs='dc logs -f'
stack-logs-svc() { dc logs -f "$1"; }           # usage: stack-logs-svc n8n

# Service control
stack-restart-svc() { dc restart "$1"; }        # usage: stack-restart-svc caddy
stack-up-svc()      { dc up -d "$1"; }
stack-stop-svc()    { dc stop "$1"; }

# Quick checks
stack-env() { grep -v "^[[:space:]]*#\|^$" "${STACK_ENV_FILE}" 2>/dev/null || true; }
stack-info() {
  echo "STACK_NAME=${STACK_NAME}"
  echo "STACK_PROJECT=${STACK_PROJECT}"
  echo "STACK_ROOT=${STACK_ROOT}"
  echo "STACK_ENV_FILE=${STACK_ENV_FILE}"
  echo "STACK_FILES=${STACK_FILES}"
}

# Switch to another stack on the fly (temporary for current shell)
stack-use() {
  if [ $# -lt 2 ]; then echo "Usage: stack-use <STACK_ROOT> <STACK_PROJECT> [files...]"; return 2; fi
  export STACK_ROOT="$1"
  export STACK_PROJECT="$2"
  shift 2
  [ $# -gt 0 ] && export STACK_FILES="$*"
  [ -f "${STACK_ROOT}/.stackrc" ] && . "${STACK_ROOT}/.stackrc"
  echo "Switched to STACK_ROOT=${STACK_ROOT} STACK_PROJECT=${STACK_PROJECT}"
}

# Simple service name completion for *_svc functions (bash-only lightweight)
if [ -n "$BASH_VERSION" ]; then
  _stack_services() {
    local svcs ; svcs=$(dc config --services 2>/dev/null) || return 0
    COMPREPLY=( $(compgen -W "${svcs}" -- "${COMP_WORDS[COMP_CWORD]}") )
  }
  complete -F _stack_services stack-logs-svc stack-restart-svc stack-up-svc stack-stop-svc
fi
