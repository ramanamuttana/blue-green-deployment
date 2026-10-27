#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# Minikube bootstrap
# -------------------------
if ! command -v minikube >/dev/null 2>&1; then
  echo "Minikube not found. Installing..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm -f minikube-linux-amd64
fi

if ! minikube status >/dev/null 2>&1; then
  echo "Starting Minikube cluster..."
  minikube start --driver=docker
fi

NAMESPACE="${NAMESPACE:-default}"
SERVICE_NAME="${SERVICE_NAME:-deployment-demo}"

echo "==> Deploying BLUE (kept available)"
kubectl apply --validate=false -f blue-green-together/blue/deployment-blue.yaml -n "$NAMESPACE"

echo "==> Deploying GREEN"
kubectl apply --validate=false -f blue-green-together/green/deployment-green.yaml -n "$NAMESPACE"

echo "==> Waiting for GREEN deployment to be ready"
kubectl rollout status deployment/deployment-demo-green -n "$NAMESPACE" --timeout=180s

echo "==> Switching service traffic to GREEN"
kubectl patch service "$SERVICE_NAME" -n "$NAMESPACE" --type='merge' -p '
{
  "spec": {
    "selector": {
      "app": "deployment-demo",
      "deployment": "green",
      "version": "1.0.1"
    }
  }
}'

echo "==> Current service selector:"
kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector}{"\n"}'

echo "==> Pods:"
kubectl get pods -l app=deployment-demo -n "$NAMESPACE"
