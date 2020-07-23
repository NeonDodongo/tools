#!/bin/bash

# Add additional image names here, do not specify tag
declare -a IMAGES=("minio/minio" "mongo" "bitnami/kubectl")

# Script Vars
TAG=latest
UNAME=$(uname)
DOCKER_MACHINE=dev

# Determine Docker Machine IP
echo "Retrieving Docker Machine IP for '${DOCKER_MACHINE}'"
DOCKER_IP=$(docker-machine ip ${DOCKER_MACHINE})

# Check if Docker is available
echo ""
echo "Checking docker version..."
docker --version
if [ $? != 0 ]; then
    echo "...docker not found on system...aborting"
    exit 1
fi

# Kill running containers for mongo and minio
# Add kill commands for containers spun up by this script
echo ""
echo "Removing possible running containers..."
for i in "${IMAGES[@]}"; do
    echo ${i}...
    if ! docker rm -f $(docker ps -q --filter ancestor=${i}) &> /dev/null; then
        echo "...no ancestor found for '${i}'"
    fi
done

# Pull latest images for local development environment
echo ""
echo "Pulling latest images..."
for i in "${IMAGES[@]}"; do
    image=${i}:${TAG}

    if ! docker pull ${image}; then 
        echo "...failed to pull image: ${image}"
    fi
done

start_mongo_container() {
    image=$1
    echo ${i}...
    if ! docker run -d -p 27017:27017 ${image}; then
        echo "...failed to start container for image ${image}"
        return
    fi
    echo "...created!"
}

start_minio_container() {
    image=$1
    echo ${i}...
    if ! docker run -e "MINIO_ACCESS_KEY=TEST-USER" -e "MINIO_SECRET_KEY=TEST-USER" -d -p 9000:9000 ${image} server start; then
        echo "...failed to start container for image ${image}"
        return
    fi
    echo "...created!"
}

# Spin up specified docker containers
echo ""
echo "Spinning up docker containers..."
for i in "${IMAGES[@]}"; do
    image=${i}:${TAG}

    case ${image} in
    *"mongo"*)
        start_mongo_container ${image};;
    *"minio"*)
        start_minio_container ${image};;
    esac
done

# Clean up dangling artifacts
echo ""
echo "Cleaning up dangling artifacts..."
echo "y" | docker image prune

echo "************************************************************************"
echo "Docker containers can be accessed via ${DOCKER_IP}:<port_of_container>"
echo ""

docker ps -a