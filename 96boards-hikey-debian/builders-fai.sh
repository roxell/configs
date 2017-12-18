#!/bin/bash

set -e

trap cleanup_exit INT TERM EXIT

cleanup_exit()
{
  cd ${WORKSPACE}
  sudo kpartx -dv /tmp/work.raw || true
  umount -f /tmp||true
  rm -rf out

}

if ! sudo DEBIAN_FRONTEND=noninteractive apt-get -q=2 update; then
  echo "INFO: apt update error - try again in a moment"
  sleep 15
  sudo DEBIAN_FRONTEND=noninteractive apt-get -q=2 update || true
fi
pkg_list="fai-server fai-setup-storage qemu-utils procps pigz android-tools-fsutils android-tools-mkbootimg kpartx "
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

h4. Hikey build - $BUILD_DISPLAY_NAME

Build description:
* Build URL: "$BUILD_URL":$BUILD_URL
* OS flavour: $OS_FLAVOUR
* FAI: "$GIT_URL":$GIT_URL
* FAI commit: "$GIT_COMMIT":$GIT_URL/commit/?id=$GIT_COMMIT
EOF

sudo mount -t tmpfs tmpfs /tmp

for rootfs in ${ROOTFS}; do

    VERSION=$(cat build-version)
    image_name=${VENDOR}-${OS_FLAVOUR}-${rootfs}-${PLATFORM_NAME}-${VERSION}

    # make bootable sd card
    sudo fai-diskimage -v --cspace $(pwd) \
         --hostname linaro-${rootfs} \
         -S ${rootfs_sz} \
         --class $(echo SAVECACHE,${OS_FLAVOUR},DEBIAN,LINARO,${rootfs},${PLATFORM_NAME},GRUB_PC | tr '[:lower:]' '[:upper:]') \
         /tmp/work.raw

    # snatch the rootfs and bootfs for fastboot
    for device in $(sudo kpartx -avs /tmp/work.raw | cut -d' ' -f3); do
        partition=$(echo ${device} | cut -d'p' -f3)
        sudo dd if=/dev/mapper/${device} of=/tmp/partition.raw
        if [ "${partition}" = "2" ]; then
            img2simg /tmp/partition.raw out/rootfs-${image_name}.img
        fi
        if [ "${partition}" = "1" ]; then
            cp /tmp/partition.raw out/boot-${image_name}.img
        fi
        sudo rm -f /tmp/partition.raw
    done
    sudo kpartx -dv /tmp/work.raw
    mv /tmp/${image_name}.raw out/${image_name}.sd

    # Compress image(s)
    pigz -9 out/rootfs-${image_name}.img out/boot-${image_name}.img out/${image_name}.sd

    # dpkg -l output
    mv out/packages.txt out/${image_name}.packages
done
