#!/usr/bin/env bash
# setup-minikube.sh
# One-shot setup for macOS:
#   1. clones https://github.com/ramanamuttana/blue-green-deployment (if not already cloned)
#   2. installs minikube (if missing)
#   3. starts minikube with the Docker driver
#   4. deploys blue-green-individual/blue
#   5. port-forwards service/deployment-demo to http://localhost:8080
#
# Usage:
#   chmod +x setup-minikube.sh
#   ./setup-minikube.sh
#
# Optional: pass an existing local copy of the repo as the first argument:
#   ./setup-minikube.sh ~/Downloads/blue-green-deployment

set -euo pipefail

REPO_URL="https://github.com/ramanamuttana/blue-green-deployment"
REPO_DIR="${1:-$HOME/blue-green-deployment}"
MANIFEST_DIR="$REPO_DIR/blue-green-individual/blue"
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

[[ -d "$MANIFEST_DIR" ]] || err "Manifest folder not found: $MANIFEST_DIR"

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

# --- 5. Deploy manifests ------------------------------------------------------
log "Applying manifests in $MANIFEST_DIR"
if ! find "$MANIFEST_DIR" -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) | grep -q .; then
  echo "No .yaml/.yml/.json files found under: $MANIFEST_DIR"
  echo "Contents of $REPO_DIR:"
  find "$REPO_DIR" -not -path '*/.git/*' | head -50
  err "No manifests found."
fi
$KUBECTL apply -R -f "$MANIFEST_DIR"

# --- 6. Check resources -------------------------------------------------------
log "Waiting for deployments to become ready"
$KUBECTL wait --for=condition=available deployment --all --timeout=180s || true

log "Deployments"
$KUBECTL get deployments
log "Pods"
$KUBECTL get pods
log "Services"
$KUBECTL get services

# --- 7. Port-forward and open browser ----------------------------------------
log "Port-forwarding service/$SERVICE_NAME -> localhost:$LOCAL_PORT"
$KUBECTL port-forward "service/$SERVICE_NAME" "$LOCAL_PORT:$SERVICE_PORT" &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT INT TERM

sleep 3
log "Opening http://localhost:$LOCAL_PORT  (press Ctrl+C to stop port-forwarding)"
open "http://localhost:$LOCAL_PORT"

wait $PF_PID
