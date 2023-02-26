#!/bin/bash

VERSION=$1

# Check if version argument is provided
if [ -z "$VERSION" ]
then
    echo "Please provide a Longhorn version number as an argument."
    exit 1
fi

# Confirm that the user wants to proceed with the uninstall
read -p "Are you sure you want to uninstall Longhorn? This action cannot be undone. (y/n)" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Uninstall aborted."
    exit 1
fi

# Remove the Longhorn deletion confirmation flag (only for v1.4+)
if [[ $VERSION == v1.[4-6]* ]]
then
    kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag
fi

# Uninstall Longhorn
kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/uninstall/uninstall.yaml

# Wait for the Longhorn uninstall job to complete (different namespaces for different versions)
if [[ $VERSION == v1.[4-6]* ]]
then
    kubectl wait --for=condition=complete job/longhorn-uninstall -n longhorn-system --timeout=5m

elif [[ $VERSION == v1.3* ]]
then
    kubectl wait --for=condition=complete job/longhorn-uninstall -n default --timeout=5m
fi

# Remove remaining components
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/longhorn.yaml
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/uninstall/uninstall.yaml

TIMEOUT=180 # set waiting time to 3 minutes

echo "Waiting for longhorn-system namespace to be deleted..."

# Continuously check if the longhorn-system namespace exists, if it does, continue waiting until timeout
while kubectl get ns longhorn-system &> /dev/null; do
    sleep 5
    TIMEOUT=$((TIMEOUT-5))
    if [[ $TIMEOUT -lt 0 ]]; then
        echo "Timeout: longhorn-system namespace still exists."
        exit 1
    fi
done

echo "longhorn-system namespace has been successfully deleted."
echo "Uninstall completed successfully."
