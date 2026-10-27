#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
SERVICE_NAME="${SERVICE_NAME:-deployment-demo}"

echo "==> Making sure BLUE deployment exists"
kubectl apply -f blue-green-together/blue/deployment-blue.yaml -n "$NAMESPACE"

echo "==> Waiting for BLUE deployment to be ready"
kubectl rollout status deployment/deployment-demo-blue -n "$NAMESPACE" --timeout=180s

echo "==> Switching service traffic back to BLUE"
kubectl patch service "$SERVICE_NAME" -n "$NAMESPACE" --type='merge' -p '
{
  "spec": {
    "selector": {
      "app": "deployment-demo",
      "deployment": "blue",
      "version": "1.0.0"
    }
  }
}'

echo "==> Current service selector:"
kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector}{"\n"}'

echo "==> Pods:"
kubectl get pods -l app=deployment-demo -n "$NAMESPACE"
