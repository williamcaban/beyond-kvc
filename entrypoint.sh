#!/bin/bash
# NOTE: Some functions base on work from kmods-via-containers

# The MIT License

# Copyright (c) 2019 Dusty Mabe

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

set -eu

# include host binaries
export PATH=$PATH:/host/usr/local/sbin:/host/usr/local/bin:/host/usr/sbin:/host/usr/bin:/host/sbin:/host/bin

# - KVER
#   - The kernel version we are targeting
KVER=`uname -r`

# - KMOD_NAMES
#   - A space separated list kernel module names that are part of the
#     module software bundle and are to be checked/loaded/unloaded
KMOD_NAMES=${KMOD_NAMES:-"simple-kmod simple-procfs-kmod"}

is_kmod_loaded() {
    module=${1//-/_} # replace any dashes with underscore
    if lsmod | grep "${module}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

load_kmods() {
    echo "Loading kernel modules using the kernel module container..."
    for module in ${KMOD_NAMES}; do
        if is_kmod_loaded ${module}; then
            echo "Kernel module ${module} already loaded"
        else
            module=${module//-/_} # replace any dashes with underscore
            insmod /kmod/${KVER}/${module}
            echo "Kernel module loaded"
        fi
    done
}

unload_kmods() {
    echo "Unloading kernel modules..."
    for module in ${KMOD_NAMES}; do
        if is_kmod_loaded ${module}; then
            module=${module//-/_} # replace any dashes with underscore
            rmmod "${module}"
        else
            echo "Kernel module ${module} already unloaded"
        fi
    done
}

fix_paths() {
    echo "Creating symlinks for path assumed by '/usr/sbin/weak-modules'"
    ln -s /host/usr/bin/dracut /usr/bin/dracut
    ln -s /host/sbin/modinfo /sbin/modinfo
    ln -s /host/usr/sbin/depmod /usr/sbin/depmod
    ln -s /host/lib/modules/${KVER} /lib/modules/${KVER}
}

main () {
    trap "{ echo Unloading ${KMOD_NAMES} ; unload_kmods ; }" SIGINT SIGTERM SIGKILL EXIT
    load_kmods
    echo "Going for an infinite nap... my job is done"
    sleep infinity 
}

main