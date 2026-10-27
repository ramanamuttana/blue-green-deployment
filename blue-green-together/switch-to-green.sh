#!/usr/bin/env bash
set -euo pipefail

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
