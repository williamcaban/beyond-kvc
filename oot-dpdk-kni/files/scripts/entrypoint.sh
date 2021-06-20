#!/bin/bash
# NOTE: Originally some ideas were base on work from kmods-via-containers
# then they were re-written.

set -eu

# include host binaries
export PATH=$PATH:/host/usr/local/sbin:/host/usr/local/bin:/host/usr/sbin:/host/usr/bin:/host/sbin:/host/bin

# - KVER
#   - The kernel version of where the script is running
KVER=`uname -r`

# - KMOD_NAMES
#   - A space separated list kernel module names that are part of the
#     module software bundle and are to be checked/loaded/unloaded
KMOD_NAMES=${KMOD_NAMES:-"my_kmod1 my_kmod2"}

# - MPROBEPARAMS
#   - modprobe params to pass while loading kmod
#   MPROBEPARAMS="--force"
MPROBEPARAMS=${MPROBEPARAMS:""}

is_kmod_loaded() {
    match_module=$(lsmod | grep ${module} | cut -f1 -d' ')
    if [[ "${module}" = "${match_module}" ]]; then
        return 1
    else
        return 0
    fi
}

load_kmods() {
    echo "Loading kernel modules..."
    for module in ${KMOD_NAMES}; do
        moprobe ${MPROBEPARAMS} ${module}
        if $?; then
            echo "Error loading Kernel module ${module} "
        else
            echo "Kernel module ${module} loaded"
        fi
    done
}

unload_kmods() {
    echo "Unloading kernel modules..."
    for module in ${KMOD_NAMES}; do
        echo "Unloading ${module}"
        modprobe -r ${module}
        if $?; then
            echo "Error unloading Kernel module ${module} "
        else
            echo "Kernel module ${module} unloaded"
        fi
    done
}

create_kmod_symlinks() {
    echo "Creating symlinnks for kernel modules..."
    KMODEXTRA="/lib/modules/${KVER}/extra"
    mkdir -pv ${KMODEXTRA}

    # link for kmods to work with modprobe
    ln -s /kmod/${KVER}/*.ko ${KMODEXTRA}
    # modprobe kmod config params
    ln -s /kmod/*.conf /etc/modprobe.d/

    # Fenerate modules.dep and map files
    depmod 
}

main () {
    create_kmod_symlinks
    trap "{ echo Unloading ${KMOD_NAMES} ; unload_kmods ; }" SIGINT SIGTERM SIGKILL EXIT
    load_kmods
    echo "Going for an infinite nap... my job is done"
    sleep infinity & wait
}

main