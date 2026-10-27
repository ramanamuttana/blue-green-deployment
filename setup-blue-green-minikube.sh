#!/usr/bin/env bash
# setup-blue-green-minikube.sh
# One-shot setup for macOS:
#   1. clones https://github.com/ramanamuttana/blue-green-deployment (if not already cloned)
#   2. installs minikube (if missing)
#   3. starts minikube with the Docker driver
#   4. deploys blue
#   5. waits 60 seconds
#   6. deploys green and switches the service to green
#   7. port-forwards service/deployment-demo to http://localhost:8080
#
# Usage:
#   chmod +x setup-blue-green-minikube.sh
#   ./setup-blue-green-minikube.sh
#
# Optional: pass an existing local copy of the repo as the first argument:
#   ./setup-blue-green-minikube.sh ~/Downloads/blue-green-deployment

set -euo pipefail

REPO_URL="https://github.com/ramanamuttana/blue-green-deployment"
REPO_DIR="${1:-$HOME/blue-green-deployment}"
BLUE_MANIFEST="$REPO_DIR/blue-green-together/blue/deployment-blue.yaml"
GREEN_MANIFEST="$REPO_DIR/blue-green-together/green/deployment-green.yaml"
SERVICE_NAME="deployment-demo"
LOCAL_PORT=8080
SERVICE_PORT=80

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
err() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# --- 0. Prerequisites ---------------------------------------------------------
[[ "$(uname -s)" == "Darwin" ]] || err "This script is for macOS."

command -v git >/dev/null 2>&1 || err "git is not installed. Run: xcode-select --install"

if ! command -v docker >/dev/null 2>&1; then
  err "Docker is not installed. Install Docker Desktop first: https://www.docker.com/products/docker-desktop/"
fi
if ! docker info >/dev/null 2>&1; then
  err "Docker is installed but not running. Start Docker Desktop and re-run this script."
fi

# --- 1. Get the repository ----------------------------------------------------
if [[ -d "$REPO_DIR/.git" ]]; then
  log "Repository already present at $REPO_DIR - pulling latest"
  git -C "$REPO_DIR" pull --ff-only || true
elif [[ -d "$REPO_DIR" && -n "$(ls -A "$REPO_DIR")" ]]; then
  log "Using existing folder $REPO_DIR (not a git clone)"
else
  log "Cloning $REPO_URL into $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

[[ -f "$BLUE_MANIFEST" ]] || err "Blue manifest not found: $BLUE_MANIFEST"
[[ -f "$GREEN_MANIFEST" ]] || err "Green manifest not found: $GREEN_MANIFEST"

# --- 2. Install minikube ------------------------------------------------------
if command -v minikube >/dev/null 2>&1; then
  log "minikube already installed: $(minikube version --short)"
else
  log "Installing minikube"
  ARCH="$(uname -m)"
  if [[ "$ARCH" == "arm64" ]]; then
    BIN="minikube-darwin-arm64"
  else
    BIN="minikube-darwin-amd64"
  fi
  curl -fLO "https://storage.googleapis.com/minikube/releases/latest/$BIN"
  sudo install "$BIN" /usr/local/bin/minikube
  rm -f "$BIN"
  log "Installed minikube: $(minikube version --short)"
fi

# --- 3. kubectl ---------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  KUBECTL="kubectl"
else
  log "kubectl not found, using 'minikube kubectl --'"
  KUBECTL="minikube kubectl --"
fi

# --- 4. Start minikube --------------------------------------------------------
log "Starting minikube (driver=docker)"
minikube start --driver=docker

# --- 5. Deploy BLUE -----------------------------------------------------------
log "Applying BLUE deployment"
$KUBECTL apply -f "$BLUE_MANIFEST"

log "Waiting for BLUE deployment to become available"
$KUBECTL rollout status deployment/deployment-demo-blue --timeout=180s

# --- 6. Wait before switching --------------------------------------------------
log "Waiting 60 seconds before switching to green..."
sleep 60

# --- 7. Deploy GREEN -----------------------------------------------------------
log "Applying GREEN deployment"
$KUBECTL apply -f "$GREEN_MANIFEST"

log "Waiting for GREEN deployment to become available"
$KUBECTL rollout status deployment/deployment-demo-green --timeout=180s

# --- 8. Switch service to GREEN ------------------------------------------------
log "Switching service selector to GREEN deployment"
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

log "Current service selector"
$KUBECTL get service "$SERVICE_NAME" -o jsonpath='{.spec.selector}{"\n"}'

log "Pods"
$KUBECTL get pods -l app=deployment-demo

# --- 9. Port-forward ----------------------------------------------------------
log "Port-forwarding service/$SERVICE_NAME -> localhost:$LOCAL_PORT"
$KUBECTL port-forward "service/$SERVICE_NAME" "$LOCAL_PORT:$SERVICE_PORT" &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT INT TERM

sleep 3
log "Opening http://localhost:$LOCAL_PORT  (press Ctrl+C to stop port-forwarding)"
open "http://localhost:$LOCAL_PORT"

wait $PF_PID
