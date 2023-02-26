#!/bin/bash

if [ -z "$1" ]; then
    echo "Please provide the version argument."
    echo "Usage: ./longhorn-install.sh <version>"
    exit 1
fi

VERSION=$1

control_nodes=$(kubectl get node | awk '$3 ~ /control-plane/ {print $1}')

for node in ${control_nodes}; do
  kubectl taint node ${node} node-role.kubernetes.io/master=true:NoExecute
  kubectl taint node ${node} node-role.kubernetes.io/master=true:NoSchedule
done

echo "Tainted control-plane nodes:"
kubectl get node --show-labels | grep node-role.kubernetes.io/master=true

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/prerequisite/longhorn-nfs-installation.yaml
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/prerequisite/longhorn-iscsi-installation.yaml
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/longhorn.yaml
