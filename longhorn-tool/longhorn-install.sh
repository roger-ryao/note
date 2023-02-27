#!/bin/bash

VERSION=$1

if [[ $# -lt 1 ]]; then
    echo "Please provide the version and kubeconfig path arguments."
    echo "Usage: ./longhorn-install.sh <version> [<kubeconfig path>]"
    echo "Examples:"
    echo "  ./longhorn-install.sh v1.4.0"
    echo "  ./longhorn-install.sh v1.4.0 kubeconfig.yaml"
    exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "KUBECONFIG=~/.kube/config"
    KUBECONFIG=~/.kube/config # Set the default kubeconfig path
else
    echo "KUBECONFIG=$2"
    KUBECONFIG=$2 # Use the provided kubeconfig path
fi

control_nodes=$(kubectl --kubeconfig="$KUBECONFIG" get node | awk '$3 ~ /control-plane/ {print $1}')

for node in ${control_nodes}; do
  kubectl --kubeconfig="$KUBECONFIG" taint node ${node} node-role.kubernetes.io/master=true:NoExecute
  kubectl --kubeconfig="$KUBECONFIG" taint node ${node} node-role.kubernetes.io/master=true:NoSchedule
done

echo "Tainted control-plane nodes:"
kubectl --kubeconfig="$KUBECONFIG" get node --show-labels | grep node-role.kubernetes.io/master=true

kubectl --kubeconfig="$KUBECONFIG" apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/prerequisite/longhorn-nfs-installation.yaml
kubectl --kubeconfig="$KUBECONFIG" apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/prerequisite/longhorn-iscsi-installation.yaml

if [[ $VERSION == v1.3.x ]]; then
    kubectl --kubeconfig="$KUBECONFIG" apply -f longhorn-13x.yaml
elif [[ $VERSION == v1.4.x ]]; then
    kubectl --kubeconfig="$KUBECONFIG" apply -f longhorn-14x.yaml
else
    kubectl --kubeconfig="$KUBECONFIG" apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/longhorn.yaml
fi

# Check if all Longhorn components are ready
sleep 30
TIMEOUT=180 # Set the timeout to 3 minutes
echo "Waiting for Longhorn components to be ready..."
if ! kubectl --kubeconfig="$KUBECONFIG" wait --for=condition=ready pod --all -n longhorn-system --timeout=${TIMEOUT}s &> /dev/null
then
    echo "Not all Longhorn components are ready after ${TIMEOUT} seconds."
    exit 1
fi

echo "All Longhorn components are ready."


