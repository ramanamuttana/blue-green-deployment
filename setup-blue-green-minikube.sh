#!/usr/bin/env bash
# setup-blue-green-minikube.sh
# Flow:
#   1. get the repo, install/start minikube
#   2. deploy BLUE, apply service.yaml, point the Service at BLUE
#   3. port-forward + open browser (blue)
#   4. wait 60 seconds
#   5. deploy GREEN, switch the Service to GREEN
#   6. port-forward again + open browser (green)
#
# Usage:
#   chmod +x setup-blue-green-minikube.sh
#   ./setup-blue-green-minikube.sh [path-to-local-repo]
#
# Optional overrides (environment variables):
#   SERVICE_MANIFEST=/path/to/service.yaml ./setup-blue-green-minikube.sh

set -euo pipefail

REPO_URL="https://github.com/ramanamuttana/blue-green-deployment"
REPO_DIR="${1:-$HOME/blue-green-deployment}"
BLUE_MANIFEST="$REPO_DIR/blue-green-together/blue/deployment-blue.yaml"
GREEN_MANIFEST="$REPO_DIR/blue-green-together/green/deployment-green.yaml"
SERVICE_MANIFEST="${SERVICE_MANIFEST:-}"
SERVICE_NAME="deployment-demo"
LOCAL_PORT=8080
SERVICE_PORT=80
WAIT_SECONDS=60
PF_PID=""

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
err() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

stop_pf() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
    wait "$PF_PID" 2>/dev/null || true
    PF_PID=""
  fi
}
trap stop_pf EXIT INT TERM

start_pf() {
  log "Port-forwarding service/$SERVICE_NAME -> localhost:$LOCAL_PORT"
  $KUBECTL port-forward "service/$SERVICE_NAME" "$LOCAL_PORT:$SERVICE_PORT" >/dev/null &
  PF_PID=$!
  sleep 3
  kill -0 "$PF_PID" 2>/dev/null || err "port-forward failed (is port $LOCAL_PORT already in use?)"
  log "Opening http://localhost:$LOCAL_PORT"
  open "http://localhost:$LOCAL_PORT"
}

# --- 0. Prerequisites ---------------------------------------------------------
[[ "$(uname -s)" == "Darwin" ]] || err "This script is for macOS."
command -v git >/dev/null 2>&1 || err "git is not installed. Run: xcode-select --install"
command -v docker >/dev/null 2>&1 || err "Docker is not installed (https://www.docker.com/products/docker-desktop/)"
docker info >/dev/null 2>&1 || err "Docker is installed but not running. Start Docker Desktop and re-run."

# --- 1. Repository ------------------------------------------------------------
if [[ -d "$REPO_DIR/.git" ]]; then
  log "Repository present at $REPO_DIR - pulling latest"
  git -C "$REPO_DIR" pull --ff-only || true
elif [[ -d "$REPO_DIR" && -n "$(ls -A "$REPO_DIR")" ]]; then
  log "Using existing folder $REPO_DIR (not a git clone)"
else
  log "Cloning $REPO_URL into $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi
[[ -f "$BLUE_MANIFEST" ]]  || err "Blue manifest not found: $BLUE_MANIFEST"
[[ -f "$GREEN_MANIFEST" ]] || err "Green manifest not found: $GREEN_MANIFEST"

# Find service.yaml: prefer the blue-green-together folder, skip the individual one
if [[ -z "$SERVICE_MANIFEST" ]]; then
  SERVICE_MANIFEST="$(find "$REPO_DIR/blue-green-together" -type f \( -name 'service.yaml' -o -name 'service.yml' \) 2>/dev/null | head -n 1 || true)"
fi
if [[ -z "$SERVICE_MANIFEST" ]]; then
  SERVICE_MANIFEST="$(find "$REPO_DIR" -type f \( -name 'service.yaml' -o -name 'service.yml' \) 2>/dev/null | head -n 1 || true)"
fi
[[ -n "$SERVICE_MANIFEST" && -f "$SERVICE_MANIFEST" ]] || err "service.yaml not found under $REPO_DIR. Set SERVICE_MANIFEST=/path/to/service.yaml and re-run."
log "Using service manifest: $SERVICE_MANIFEST"

# --- 2. minikube --------------------------------------------------------------
if command -v minikube >/dev/null 2>&1; then
  log "minikube already installed: $(minikube version --short)"
else
  log "Installing minikube"
  if [[ "$(uname -m)" == "arm64" ]]; then BIN="minikube-darwin-arm64"; else BIN="minikube-darwin-amd64"; fi
  curl -fLO "https://storage.googleapis.com/minikube/releases/latest/$BIN"
  sudo install "$BIN" /usr/local/bin/minikube
  rm -f "$BIN"
fi

if command -v kubectl >/dev/null 2>&1; then KUBECTL="kubectl"; else KUBECTL="minikube kubectl --"; fi

log "Starting minikube (driver=docker)"
minikube start --driver=docker

# --- 3. Deploy BLUE -----------------------------------------------------------
log "Applying BLUE deployment"
$KUBECTL apply -f "$BLUE_MANIFEST"

log "Waiting for BLUE deployment"
$KUBECTL rollout status deployment/deployment-demo-blue --timeout=180s

# --- 4. Apply service.yaml, then point it at BLUE -----------------------------
# service.yaml in the repo selects GREEN, so right after applying it we switch
# the selector to BLUE (version: null removes the version key from the selector).
log "Applying service.yaml"
$KUBECTL apply -f "$SERVICE_MANIFEST"

log "Pointing service at BLUE"
$KUBECTL patch service "$SERVICE_NAME" --type='merge' -p '
{
  "spec": {
    "selector": {
      "app": "deployment-demo",
      "deployment": "blue",
      "version": null
    }
  }
}'

log "Service selector"
$KUBECTL get service "$SERVICE_NAME" -o jsonpath='{.spec.selector}{"\n"}'
log "Endpoints"
$KUBECTL get endpoints "$SERVICE_NAME"
if [[ -z "$($KUBECTL get endpoints "$SERVICE_NAME" -o jsonpath='{.subsets[*].addresses[*].ip}')" ]]; then
  log "WARNING: no endpoints. The selector does not match the blue pod labels:"
  $KUBECTL get pods --show-labels
  err "Fix the selector labels in this script or in the blue manifest, then re-run."
fi

# --- 5. Port-forward to BLUE, browser ----------------------------------------
start_pf

log "BLUE is live. Waiting $WAIT_SECONDS seconds before rolling out GREEN..."
for ((i = WAIT_SECONDS; i > 0; i--)); do
  printf '\r   %2d seconds left ' "$i"
  sleep 1
done
printf '\r                      \n'
stop_pf

# --- 6. Deploy GREEN ----------------------------------------------------------
log "Applying GREEN deployment"
$KUBECTL apply -f "$GREEN_MANIFEST"

log "Waiting for GREEN deployment"
$KUBECTL rollout status deployment/deployment-demo-green --timeout=180s

# --- 7. Switch service to GREEN ----------------------------------------------
log "Switching service selector to GREEN"
$KUBECTL patch service "$SERVICE_NAME" --type='merge' -p '
{
  "spec": {
    "selector": {
      "app": "deployment-demo",
      "deployment": "green",
      "version": "1.0.1"
    }
  }
}'

log "Service selector now"
$KUBECTL get service "$SERVICE_NAME" -o jsonpath='{.spec.selector}{"\n"}'
log "Endpoints (must not be empty)"
$KUBECTL get endpoints "$SERVICE_NAME"

# --- 8. Port-forward again to GREEN ------------------------------------------
start_pf
echo
echo "GREEN should now be open (hard-refresh with Cmd+Shift+R if you still see blue)."
echo "Press Ctrl+C to stop port-forwarding."
wait "$PF_PID"
