# Configuration environment variables

OCP_RELEASE_SRC=quay.io/openshift-release-dev/ocp-release
OCP_RELEASE=4.6.18-x86_64
PULL_SECRET=/root/pull-secret.json

# 
IMAGE=quay.io/wcaban/beyond-kvc
DPDK_VERSION="19.11.8"
OCP_VERSION="4.6.18"

# #### Testing
# oc adm release info --image-for=machine-os-content \
# ${OCP_RELEASE_SRC}:${OCP_RELEASE} --registry-config=${PULL_SECRET}
