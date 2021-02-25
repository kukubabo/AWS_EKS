#!/bin/bash

# delete ingress
#kubectl delete -f 01-7.ingress.yaml

# delete controllers / services
kubectl -n test delete rc/redis-master rc/redis-slave rc/guestbook svc/redis-master svc/redis-slave svc/guestbook

# reset INGRESS_SVC
#INGRESS_SVC=`kubectl -n infra get svc  nginx-ingress-external-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'`
#perl -pi -e "s/$INGRESS_SVC/SET_USER_HOST/g" 01-7.ingress.yaml

# delete 'test' namespace
#kubectl delete ns test
