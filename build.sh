#!/bin/bash -e

export DOCKER_BUILDKIT=0 
time docker-apptainer-build-image -u
