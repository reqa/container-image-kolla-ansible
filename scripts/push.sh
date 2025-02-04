#!/usr/bin/env bash
set -x

# Available environment variables
#
# DOCKER_REGISTRY
# OPENSTACK_VERSION
# REPOSITORY
# VERSION

# Set default values

DOCKER_REGISTRY=${DOCKER_REGISTRY:-quay.io}
OPENSTACK_VERSION=${OPENSTACK_VERSION:-master}
REPOSITORY=${REPOSITORY:-osism/kolla-ansible}
VERSION=${VERSION:-latest}

COMMIT=$(git rev-parse --short HEAD)

# NOTE: For builds for a specific release, the OpenStack version is taken from the release repository.
if [[ $VERSION != "latest" ]]; then
    filename=$(curl -L https://raw.githubusercontent.com/osism/release/main/$VERSION/openstack.yml)
    OPENSTACK_VERSION=$(curl -L https://raw.githubusercontent.com/osism/release/main/$VERSION/$filename | grep "openstack_version:" | awk -F': ' '{ print $2 }')
fi

. defaults/$OPENSTACK_VERSION.sh

if [[ -n $DOCKER_REGISTRY ]]; then
    REPOSITORY="$DOCKER_REGISTRY/$REPOSITORY"
fi

buildah login --password $DOCKER_PASSWORD --username $DOCKER_USERNAME $DOCKER_REGISTRY

if [[ $OPENSTACK_VERSION == "master" ]]; then
    tag=$REPOSITORY:latest

    buildah tag "$COMMIT" "$tag"
    buildah push "$tag"
else
    if [[ $VERSION == "latest" ]]; then
        tag=$REPOSITORY:$OPENSTACK_VERSION
    else
        tag=$REPOSITORY:$VERSION
    fi

    buildah tag "$COMMIT" "$tag"
    buildah push "$tag"
fi
