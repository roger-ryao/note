#!/bin/bash

VERSION=$1

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/prerequisite/longhorn-nfs-installation.yaml
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/prerequisite/longhorn-iscsi-installation.yaml
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${VERSION}/deploy/longhorn.yaml
