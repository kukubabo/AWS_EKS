#!/bin/bash

kubectl delete -n infra persistentvolumeclaim/gitlab-ce-config 
kubectl delete -n infra persistentvolumeclaim/gitlab-ce-data   
kubectl delete -n infra persistentvolumeclaim/gitlab-ce-log    
