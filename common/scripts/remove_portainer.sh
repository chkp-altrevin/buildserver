#!/bin/bash

docker stop $(docker ps -qf "name=^portainer_")