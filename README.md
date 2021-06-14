# Beyond KMOD

This repository aims to create `DaemonSet` (DS) objects for running manually compiled driver containers.

## Manually building driver container

Create a container where the kmods (one or more) to load using this container follow the format `/kmod/${KVER}/${KMOD}` where the layout looks like this:

```bash
KVER=`uname -r`
KMOD=name-of-kmod.ko
/kmod/${KVER}/${KMOD}
```

Copy all the kmods intended to be loaded with the DS to `/kmod/${KVER}/`.  For example:

```bash
$ tree kmod/
kmod
└── 4.18.0-193.41.1.rt13.91.el8_2.x86_64
    └── rte_kni.ko
```

```bash
# Create tgz containing the kmods and structure
tar czf kmod.tgz /kmod

# Put the tgz archive on a webserver (apache, nginx, etc) accessible by the build process
# and update Containerfile.rhel to point to it
ARG KMODTGZ=http://bastion8.shift.zone:8080/kmod.tgz

# Build the container and push the resulting image to any container registry accessible by the platform
podman build -t quay.io/wcaban/beyond-kvc:my-kmod -f Containerfile.rhel
podman push quay.io/wcaban/beyond-kvc:my-kmod
```

## Updating the DaemonSet

- Update the `01-beyond-kvc-ds.yaml` to point to the right container with the kmods

    ```yaml
        containers:
        - name: beyond-kvc
            image: quay.io/wcaban/beyond-kvc:my-kmod
    ```

- Update the `01-beyond-kvc-ds.yaml` with the kmods to load in a space separated string. For example, loading a single kmod looks like this:

    ```yaml
            env:
            - name: KMOD_NAMES
                value: "rte_kni.ko"
    ```

    Loading multiple kmods looks like this:

    ```yaml
            env:
            - name: KMOD_NAMES
                values: "rte_kni.ko kmod2.ko kmod3.ko"
    ```

## Running the DaemonSet

- Label nodes where the DS should run `oc label node du1-fec1 unsupported.example.com/beyond-kvc=''`
- Deploy the DaemonSet with `oc create -f 01-beyond-kvc-ds.yaml`
