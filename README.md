# Beyond KMOD

`DaemonSet` for running manually compiled driver containers.

## Manually building driver container

Create a container where the kmods (one or more) to load using this container follow the format `/kmod/${KVER}/${KMOD}` where the layout looks like this:

```bash
KVER=`uname -r`
KMOD=name-of-kmod.ko
/kmod/${KVER}/${KMOD}
```

- Copy all the kmods intended to be loaded and their corresponding `.conf` file for any partameters to `/kmod/${KVER}/`
- There are several ways to pass the kmods `.ko` during build:

```bash
# Path to the actual .ko
--build-arg=KMODKO=./path/my_kmod.ko
# Path to tgz containing the .ko's to load and their corresponding .config
--build-arg=KMODKO=./path/my_kmod.tgz
# Web server withtgz containing the .ko's to load and their corresponding .config
--build-arg=KMODKO=http://example.com/path/to/my_kmod.tgz
```

```bash
# Example with my_kmod.tgz containing .ko and .conf
my_kmod.tgz
    +-- my_kmod.ko
    +-- my_kmod.conf

# Build the container and upload to registry accessible by the platform
podman build \
  --build-arg=KVER=${KVER} \
  --build-arg=KMODKO=http://example.com/path/to/my_kmod.tgz \
  -t quay.io/wcaban/beyond-kvc:${OCP_RELEASE} \
  -f Containerfile.rhel

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
              value: "rte_kni.ko kmod2.ko kmod3.ko"
    ```

    Passing parameters to `modprobe`:

    ```yaml
            env:
            - name: MPROBEPARAMS
              value: "--force"
    ```

## Running the DaemonSet

- Label nodes where the DS should run `oc label node worker-0 unsupported.example.com/beyond-kvc=""`
- Deploy DaemonSet `oc create -f 01-beyond-kvc-ds.yaml`
