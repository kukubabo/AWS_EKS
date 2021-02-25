#!/bin/bash

# setting ingress host
#INGRESS_SVC=`kubectl -n infra get svc  nginx-ingress-external-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'`
#perl -pi -e "s/SET_USER_HOST/$INGRESS_SVC/g" 01-7.ingress.yaml

# create 'test' namespace
#kubectl create ns test

# create redis controller / service
kubectl apply -f 01-1.redis-master-controller.json
kubectl apply -f 01-2.redis-master-service.json
kubectl apply -f 01-3.redis-slave-controller.json
kubectl apply -f 01-4.redis-slave-service.json

# create guestbook controller / service
kubectl apply -f 01-5.guestbook-controller.json
kubectl apply -f 01-6.guestbook-service.json

# create ingress
#kubectl apply -f 01-7.ingress.yaml

#echo ""
#echo "##### TEST URL #####"
#echo "http://$INGRESS_SVC"

