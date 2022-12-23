#!/bin/bash
filename=$(basename $0)

if [ $# -ne 1 ]; then
    echo "get k8s nodes list"
    kubectl get nodes | awk '{print $1}'
else
    echo "get k8s nodes list"
    export aks_nodepool_name_old=$1
    nodes=`kubectl get nodes | grep $aks_nodepool_name_old- | awk '{print $1}'`
    for node in $nodes
    do
        echo "Drain out the node pool based on the name provided"
        echo "$node"
        kubectl cordon $node
        kubectl drain $node --ignore-daemonsets --pod-selector='app!=csi-attacher,app!=csi-provisioner' --delete-emptydir-data
    done
fi