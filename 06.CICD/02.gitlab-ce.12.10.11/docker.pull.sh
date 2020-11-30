#!/bin/bash

docker pull gitlab/gitlab-ce:12.1.0-ce.0
docker images | grep gitlab-ce
