#!/bin/bash

set -ex

trap cleanup_exit INT TERM EXIT
BUILDDIR='builddir'

cleanup_exit()
{
  cd ${WORKSPACE}
  sudo kpartx -dv "$BUILDDIR"/work.raw || true
  sudo umount -f "$BUILDDIR"||true
}

if ! sudo DEBIAN_FRONTEND=noninteractive apt-get -q=2 update; then
  echo "INFO: apt update error - try again in a moment"
  sleep 15
  sudo DEBIAN_FRONTEND=noninteractive apt-get -q=2 update || true
fi
pkg_list="fai-server fai-setup-storage qemu-utils procps pigz kpartx u-boot-tools"
if ! sudo DEBIAN_FRONTEND=noninteractive apt-get -q=2 install -y ${pkg_list}; then
  echo "INFO: apt install error - try again in a moment"
  sleep 15
  sudo DEBIAN_FRONTEND=noninteractive apt-get -q=2 install -y ${pkg_list}
fi

set -ex

# Create version string
echo "$(date +%Y%m%d)-${BUILD_NUMBER}" > build-version

# Build information
mkdir -p out
cat > out/HEADER.textile << EOF

h4. Ledge - $BUILD_DISPLAY_NAME

Build description:
* Build URL: "$BUILD_URL":$BUILD_URL
* OS flavour: $OS_FLAVOUR
* FAI: "$GIT_URL":$GIT_URL
* FAI commit: "$GIT_COMMIT":$GIT_URL/commit/?id=$GIT_COMMIT
EOF

# speed up FAI
test -d "$BUILDDIR" || mkdir "$BUILDDIR"
sudo mount -t tmpfs -o size=6G tmpfs "$BUILDDIR"

sudo cp tools/udevadm /sbin

for rootfs in ${ROOTFS}; do

    rootfs_sz=$(echo $rootfs | cut -f2 -d,)
    rootfs=$(echo $rootfs | cut -f1 -d,)
    VERSION=$(cat build-version)

    image_name=${VENDOR}-${OS_FLAVOUR}-${rootfs}-${PLATFORM_NAME}-${VERSION}

    # make bootable sd card
    sudo fai-diskimage -v --cspace $(pwd) \
         --hostname linaro-${rootfs} \
         -S ${rootfs_sz} \
         --class $(echo SAVECACHE,${OS_FLAVOUR},DEBIAN,LINARO,LEDGE,${rootfs} | tr '[:lower:]' '[:upper:]') \
         "$BUILDDIR"/work.raw

    sudo cp /var/log/fai/linaro-${rootfs}/last/fai.log fai-${rootfs}.log
    if grep -E '^(ERROR:|WARNING: These unknown packages are removed from the installation list|Exit code task_)' fai-${rootfs}.log
    then
        echo "Errors during build"
        rm -rf out/
        exit 1
    fi

    # create rootfs
    # TODO add kernel from OE builds + EFI directory structure
    sudo kpartx -as "$BUILDDIR"/work.raw
    # rootfs is on the last partition
    device=$(sudo kpartx -l $BUILDDIR/work.raw | cut -d : -f1 | tail -n1)

    sudo mount -o loop /dev/mapper/$device /mnt/
    sudo tar caf out/rootfs-${image_name}.tar /mnt
    sudo chroot /mnt dpkg -l > out/${image_name}.packages
    sudo umount -f /mnt

    sudo kpartx -dv "$BUILDDIR"/work.raw
    # cp "$BUILDDIR"/work.raw out/${image_name}.sd

    # Compress image(s)
    pigz -9 out/rootfs-${image_name}.tar
done
