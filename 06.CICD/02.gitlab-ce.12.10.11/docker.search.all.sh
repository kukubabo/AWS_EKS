#!/bin/bash

curl -s https://registry.hub.docker.com/v1/repositories/gitlab/gitlab-ce/tags
curl -s https://registry.hub.docker.com/v1/repositories/gitlab/gitlab-ce/tags | jq . | grep name 
