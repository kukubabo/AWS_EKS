#!/bin/bash

# setting ingress host
INGRESS_SVC=`kubectl -n infra get svc nginx-ingress-external-ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'`
perl -pi -e "s/SET_USER_HOST/$INGRESS_SVC/g" 01-3.ingress.yaml

# create 'test' namespace
kubectl create ns test

# create service apple / banana
kubectl apply -f 01-1.apple.yaml
kubectl apply -f 01-2.banana.yaml

# create ingress
kubectl apply -f 01-3.ingress.yaml

echo ""
echo "##### TEST URL #####"
echo "http://$INGRESS_SVC/apple"
echo "http://$INGRESS_SVC/banana"
