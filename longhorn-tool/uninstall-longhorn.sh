#!/bin/bash

VERSION=$1

# Check if version argument is provided
if [[ $# -lt 1 ]]; then
    echo "Please provide a Longhorn version number as an argument."
    echo "Usage: ./uninstall-longhorn.sh <version> [<kubeconfig path>]"
    echo "Examples:"
    echo "  ./uninstall-longhorn.sh v1.4.0"
    echo "  ./uninstall-longhorn.sh v1.4.0 kubeconfig.yaml"
    exit 1    
fi

if [[ $# -ne 2 ]]; then
    echo "KUBECONFIG=~/.kube/config"
    KUBECONFIG=~/.kube/config # Set the default kubeconfig path
else
    echo "KUBECONFIG=$2"
    KUBECONFIG=$2 # Use the provided kubeconfig path
fi

# Confirm that the user wants to proceed with the uninstall
read -p "Are you sure you want to uninstall Longhorn? This action cannot be undone. (y/n)" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Uninstall aborted."
    exit 1
fi

# Allow for the uninstallation of Longhorn and modify deletion confirmation flag (only for v1.4+)
expected_output="setting.longhorn.io/deleting-confirmation-flag patched"
retry_count=0
max_retries=2
if [[ $VERSION == v1.[4-6]* ]]
then
    while true; do
      command_output=$(kubectl --kubeconfig=$KUBECONFIG -n longhorn-system patch -p '{"value": "true"}' --type=merge setting.longhorn.io/deleting-confirmation-flag)
    
      if [ "$command_output" == "$expected_output" ]; then
        echo "Set deleting-confirmation-flag to true"
        break
      else
        retry_count=$((retry_count+1))
        if [ $retry_count -gt $max_retries ]; then
          echo "Failed to set deleting-confirmation-flag. After $retry_count retries."
          exit 1
        else
          echo "Failed to set deleting-confirmation-flag. Retrying in 30 seconds..."
          sleep 30
        fi
      fi
    done
fi

# Uninstall Longhorn
kubectl --kubeconfig=$KUBECONFIG create -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/uninstall/uninstall.yaml

# Wait for the Longhorn uninstall job to complete (different namespaces for different versions)
if [[ $VERSION == v1.[4-6]* ]]
then
    kubectl --kubeconfig=$KUBECONFIG wait --for=condition=complete job/longhorn-uninstall -n longhorn-system --timeout=5m
elif [[ $VERSION == v1.3* ]]
then
    kubectl --kubeconfig=$KUBECONFIG wait --for=condition=complete job/longhorn-uninstall -n default --timeout=5m
fi

# Remove remaining components
set +e
kubectl --kubeconfig=$KUBECONFIG delete -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/longhorn.yaml
kubectl --kubeconfig=$KUBECONFIG delete -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/uninstall/uninstall.yaml
set -e

TIMEOUT=180 # set waiting time to 3 minutes

echo "Waiting for longhorn-system namespace to be deleted..."

# Continuously check if the longhorn-system namespace exists, if it does, continue waiting until timeout
while kubectl --kubeconfig=$KUBECONFIG get ns longhorn-system &> /dev/null; do
    sleep 5
    TIMEOUT=$((TIMEOUT-5))
    if [[ $TIMEOUT -lt 0 ]]; then
        echo "Timeout: longhorn-system namespace still exists."
        exit 1
    fi
done

echo "longhorn-system namespace has been successfully deleted."
echo "Uninstall completed successfully."

# for crd in $(kubectl get crd -o name | grep longhorn); do kubectl patch $crd -p '{"metadata":{"finalizers":[]}}' --type=merge; done;