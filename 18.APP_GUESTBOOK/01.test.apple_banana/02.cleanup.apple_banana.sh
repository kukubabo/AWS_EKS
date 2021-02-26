#!/bin/bash

# delete ingress
kubectl delete -f 01-3.ingress.yaml

# delete service apple / banana
kubectl delete -f 01-1.apple.yaml
kubectl delete -f 01-2.banana.yaml

# reset INGRESS_SVC
INGRESS_SVC=`kubectl -n infra get svc nginx-ingress-external-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'`
perl -pi -e "s/$INGRESS_SVC/SET_USER_HOST/g" 01-3.ingress.yaml

# delete 'test' namespace
kubectl delete ns test
