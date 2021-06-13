# Beyond KMOD

`DaemonSet` for running manually compiled driver containers.

## Manually building driver container

Create a container where the kmods (one or more) to load using this container follow the format `/kmod/${KVER}/${KMOD}` where the layout looks like this:

```bash
KVER=`uname -r`
KMOD=name-of-kmod.ko
/kmod/${KVER}/${KMOD}
```

Copy all the kmods intended to be loaded with the DS to `/kmod/${KVER}/`

```bash
# Create tgz containing the kmods and structure
tar czf kmod.tgz /kmod

# Put the tgz on a webserver accessible by the build process
# and update Cotnainerfile.rhel to point to it
ARG KMODTGZ=http://bastion8.shift.zone:8080/kmod.tgz

# Build the container and upload to registry accessible by the platform
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
                values: "rte_kni.ko"
    ```

    Loading multiple kmods looks like this:

    ```yaml
            env:
            - name: KMOD_NAMES
                values: "rte_kni.ko kmod2.ko kmod3.ko"
    ```

## Running the DaemonSet

- Label nodes where the DS should run `oc label node worker-0 unsupported.example.com/beyond-kvc=""`
- Deploy DaemonSet `oc create -f 01-beyond-kvc-ds.yaml`
