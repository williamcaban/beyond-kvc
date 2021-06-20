#!/bin/bash

source ./set-env.sh

# Use defaults if not defined
OCP_RELEASE_SRC=${OCP_RELEASE_SRC:-"quay.io/openshift-release-dev/ocp-release"}
OCP_RELEASE=${OCP_RELEASE:-"4.6.18-x86_64"}
IMAGE=${IMAGE:-"quay.io/wcaban/beyond-kvc"}
DPDK_VERSION=${DPDK_VERSION:-"19.11.8"}
FILES_DIR=${FILES_DIR:-"files"}
PULL_SECRET=${PULL_SECRET:-"/root/pull-secret.json"}

kernels_from_machine_os_content () {
    echo "Identifying the machine-os-content for the release"
    MACHINE_OS_IMAGE=$(oc adm release info --image-for=machine-os-content "${OCP_RELEASE_SRC}:${OCP_RELEASE}" --registry-config=${PULL_SECRET})
    echo ${MACHINE_OS_IMAGE}

    echo "Downloading the machine-os-content ${MACHINE_OS_IMAGE}"
    podman pull --authfile ${PULL_SECRET} ${MACHINE_OS_IMAGE}

    echo "Run a local temporary copy of machine-os-content"
    OS_CONTAINER=$(podman run -it --rm -d --entrypoint /bin/bash ${MACHINE_OS_IMAGE})
    if [[ ! $? -eq 0 ]]; then echo "Error running container"; exit 1; fi
    echo "Running with container ID ${OS_CONTAINER}"

    echo "Retrieving kernel-rt rpms"
    RT_CORE=$( podman exec ${OS_CONTAINER} /usr/bin/find /extensions/kernel-rt -iname "kernel-rt-core*")
    RT_DEVEL=$(podman exec ${OS_CONTAINER} /usr/bin/find /extensions/kernel-rt -iname "kernel-rt-devel*")
    echo "Kernel RT Core: ${RT_CORE}"
    echo "Kernel RT Devel: ${RT_DEVEL}"

    podman cp ${OS_CONTAINER}:${RT_CORE} ${FILES_DIR}/kernel-rt/
    if [[ ! $? -eq 0 ]]; then echo "Error copying files from container -- podman cp ${OS_CONTAINER}:${RT_CORE} ${FILES_DIR}/kernel-rt/"; exit 1; fi
    podman cp ${OS_CONTAINER}:${RT_DEVEL} ${FILES_DIR}/kernel-rt/
    if [[ ! $? -eq 0 ]]; then echo "Error copying files from container"; exit 1; fi

    echo "Retrieving kernel (regular) rpms"
    KBASE_CORE=$( podman exec ${OS_CONTAINER} /usr/bin/find /extensions/kernel-devel -iname "kernel-core-*")
    KBASE_DEVEL=$(podman exec ${OS_CONTAINER} /usr/bin/find /extensions/kernel-devel -iname "kernel-devel-*")
    echo "Kernel Core: ${KBASE_CORE}"
    echo "Kernel Devel: ${KBASE_DEVEL}"

    podman cp ${OS_CONTAINER}:${KBASE_CORE} ${FILES_DIR}/kernel/
    podman cp ${OS_CONTAINER}:${KBASE_DEVEL} ${FILES_DIR}/kernel/

    # Stop machine-os-content container as we don't need it anymore
    podman rm ${OS_CONTAINER} -f
}

get_driver () {
    if [[ ! -f ${FILES_DIR}/driver/dpdk.tar.xz ]]; then
        curl -L -o ${FILES_DIR}/driver/dpdk.tar.xz http://fast.dpdk.org/rel/dpdk-${DPDK_VERSION}.tar.xz
    else
        echo "Driver already in directory"
    fi
}

build-container-driver() {
	podman build -t ${IMAGE}:${OCP_RELEASE} \
        --build-arg=DPDK_VERSION=${DPDK_VERSION} \
        --build-arg=KERNEL_DIR=kernel \
        --build-arg=OCP_RELEASE=${OCP_RELEASE} -f Containerfile

	podman build -t ${IMAGE}:${OCP_RELEASE}-rt \
        --build-arg=DPDK_VERSION=${DPDK_VERSION} \
        --build-arg=KERNEL_DIR=kernel-rt \
        --build-arg=OCP_RELEASE=${OCP_RELEASE} -f Containerfile
}

push-container-driver() {
    podman push ${IMAGE}:${OCP_RELEASE}
	podman push ${IMAGE}:${OCP_RELEASE}-rt
}

create-ds-yaml() {
    echo "TODO: generate DS definition for each kernel type"
}

main () {
    kernels_from_machine_os_content
    get_driver
    build-container-driver
    push-container-driver
}

main