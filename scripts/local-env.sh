#!/bin/bash

# Add additional image names here, do not specify tag
declare -a IMAGES=("alpine" "minio/minio" "mongo" "bitnami/kubectl")

# Script Vars
TAG=latest
DOCKER_IP=localhost
UNAME=$(uname)

# Determine OS and docker IP
if [[ ${UNAME} == CYGWIN* || ${UNAME} == MINGW* ]]; then
    echo "Running on Windows OS...changing DOCKER_IP var"
    DOCKER_IP=$(docker-machine ip)
fi

# Check if Docker is installed on system
echo ""
echo "Checking docker version..."
docker --version
if [ $? != 0 ]; then
    echo "Docker not found on system...aborting"
    exit 1
fi

# Kill running containers for mongo and minio
# Add kill commands for containers spun up by this script
echo ""
echo "Killing running containers..."
docker kill $(docker ps -q --filter ancestor=mongo)
docker kill $(docker ps -q --filter ancestor=minio/minio)

# Pull latest images for local development environment
echo ""
echo "Pulling latest images..."
for i in "${IMAGES[@]}"; do
    image=${i}:${TAG}
    docker pull ${image}
    if [ $? != 0 ]; then
        echo "Failed to pull image: ${image}"
    fi
done

# Spin up docker containers for mongo and minio
echo ""
echo "Spinning up docker containers..."
for i in "${IMAGES[@]}"; do
    image=${i}:${TAG}
    if [[ ${image} == *"mongo"* ]]; then
        docker run -d -p 27017:27017 ${image}
        echo "Created local mongo instance running inside docker container"
    fi
    if [[ ${image} == *"minio"* ]]; then
        docker run -e "MINIO_ACCESS_KEY=TEST-USER" -e "MINIO_SECRET_KEY=TEST-USER" -d -p 9000:9000 ${image} server start
        echo "Created local minio instance running inside docker container"
    fi
done

# Clean up dangling artifacts
echo ""
echo "Cleaning up dangling artifacts..."
echo "y" | docker system prune

echo "*********************************"
echo "Docker containers can be accessed via ${DOCKER_IP}:<port_of_container>"