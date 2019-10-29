#!/bin/bash

# This 'test' script generates all job templates from lava-job-definitions,
# verifies that they are valid YAML, and saves them all to ./tmp/. When making
# lava job template changes in lava-job-definitions, run this beforehand, save
# /tmp to a new path, and then run it after and diff the directories to see the
# effects the change had on the job definitions.
#
# These generated templates can also be verified by lava by using the following
# commandline, which requires lavacli to be configured with authentication
# against some LAVA host.
#
#    drue@xps:~/src/configs/openembedded-lkft$ rm -rf tmp && ./test_submit_for_testing.sh && for file in $(find tmp -name '*.yaml'); do echo $file && lavacli -i therub jobs validate $file || break; done

set -e

virtualenv --python=$(which python2) .venv
source .venv/bin/activate
pip install Jinja2 requests urllib3 ruamel.yaml

get_artifact() {
    local local_prefix=${1}
    local local_postfix=${2}
    local artifact=$(grep ${local_prefix} index.txt|grep ${local_postfix}|tail -1|sed "s|.*${local_prefix}|${local_prefix}|"|sed "s|${local_postfix}.*|${local_postfix}|")
    echo ${artifact}
}

export OE_VERSION=sumo
export LINUX_TREE=linux-mainline
export BUILD_NUMBER=latest
export BASE_URL=http://snapshots.linaro.org
export KERNEL_BRANCH=master
export KERNEL_COMMIT=ff5abbe799e29099695cb8b5b2f198dd8b8bdf26
export KERNEL_DESCRIBE=v4.14-rc4-84-gff5abbe799e2
export KERNEL_RECIPE=linux-hikey-mainline
export KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
export KERNEL_VERSION=git
export KERNEL_VERSION_OVERRIDE=mainline
export KSELFTEST_PATH="/opt/"
export KSELFTESTS_URL=https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.13.tar.xz
export KSELFTESTS_VERSION=4.13
export KSELFTESTS_REVISION=g4.13
export KSELFTESTS_NEXT_URL=git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
export KSELFTESTS_NEXT_VERSION=4.13+gitAUTOINC+49827b977a
export LAVA_SERVER=https://lkft.validation.linaro.org/RPC2/
export LIBHUGETLBFS_REVISION=e44180072b796c0e28e53c4d01ef6279caaa2a99
export LIBHUGETLBFS_URL=git://github.com/libhugetlbfs/libhugetlbfs.git
export LIBHUGETLBFS_VERSION=2.20
export LTP_REVISION=e671f2a13c695bbd87f7dfec2954ca7e3c43f377
export LTP_URL=git://github.com/linux-test-project/ltp.git
export LTP_VERSION=20170929
export MAKE_KERNELVERSION=4.14.0-rc4
export MANIFEST_BRANCH=morty
export QA_REPORTS_TOKEN=qa-reports-token
export QA_SERVER=https://qa-reports.linaro.org
export QA_SERVER_PROJECT=linux-mainline-oe
export SKIP_LAVA=
export SRCREV_kernel=ff5abbe799e29099695cb8b5b2f198dd8b8bdf26
export BUILD_NAME="openembedded-lkft-linux-mainline"
export LAVA_JOB_PRIORITY="50"
export SANITY_LAVA_JOB_PRIORITY="55"
export QA_SERVER="http://localhost:8000"
export QA_REPORTS_TOKEN="secret"
export DEVICE_TYPE="x86"
export KSELFTEST_SKIPLIST="pstore"
export QA_BUILD_VERSION=${KERNEL_DESCRIBE}
export TOOLCHAIN="arm-linaro-linux-gnueabi linaro-6.2"

export DRY_RUN=true

for device in hi6220-hikey i386 x86 juno-r2 x15 dragonboard-410c qemu_arm qemu_arm64 qemu_i386 qemu_x86_64; do
    export DEVICE_TYPE=$device
    case ${device} in
        x15)
            MACHINE=am57xx-evm
            ;;
        dragonboard-410c)
            MACHINE=dragonboard-410c
            ;;
        hi6220-hikey)
            MACHINE=hikey
            ;;
        i386)
            MACHINE=intel-core2-32
            ;;
        x86)
            MACHINE=intel-corei7-64
            ;;
        juno-r2)
            MACHINE=juno
            ;;
        qemu_arm)
            MACHINE=am57xx-evm
            ;;
        qemu_arm64)
            MACHINE=hikey
            ;;
        qemu_i386)
            MACHINE=intel-core2-32
            ;;
        qemu_x86_64)
            MACHINE=intel-corei7-64
            ;;
    esac
    export PUB_DEST=openembedded/lkft/lkft/${OE_VERSION}/${MACHINE}/lkft/${LINUX_TREE}/${BUILD_NUMBER}
    curl -sL "${BASE_URL}/${PUB_DEST}" -o index.txt
    export BOOT_URL="${BASE_URL}/${PUB_DEST}/$(get_artifact "boot-" ".uefi.img")"
    export KERNEL_URL="${BASE_URL}/${PUB_DEST}/$(get_artifact "Image-" ".bin")"
    export MODULES_URL="${BASE_URL}/${PUB_DEST}/$(get_artifact "modules-" ".tgz")"
    export DTB_URL="${BASE_URL}/${PUB_DEST}/$(get_artifact "Image-" ".dtb")"
    export SYSTEM_URL="${BASE_URL}/${PUB_DEST}/$(get_artifact "rpb-console-image-" ".rootfs.img.gz")"
    export EXT4_IMAGE_URL="${BASE_URL}/${PUB_DEST}/$(get_artifact "rpb-console-image-" ".rootfs.ext4.gz")"
    export NFSROOTFS_URL="${BASE_URL}/${PUB_DEST}/$(get_artifact "rpb-console-image-" ".rootfs.tar.xz")"
    export RECOVERY_IMAGE_URL=${BASE_URL}/${PUB_DEST}/juno-oe-uboot.zip

    export BUILD_URL="https://ci.linaro.org/job/openembedded-lkft-${LINUX_TREE}/DISTRO=rpb,MACHINE=${MACHINE},label=docker-stretch-amd64/NOT_CORRECT/"
    export JOB_BASE_NAME="DISTRO=rpb,MACHINE=${MACHINE},label=docker-stretch-amd64"
    export JOB_NAME="openembedded-lkft-linux-mainline/DISTRO=rpb,MACHINE=${MACHINE},label=docker-stretch-amd64"
    export JOB_URL="https://ci.linaro.org/job/openembedded-lkft-${LINUX_TREE}/DISTRO=rpb,MACHINE=${MACHINE},label=docker-stretch-amd64/"
    export KERNEL_CONFIG_URL=${BASE_URL}/${PUB_DEST}/config
    export KERNEL_DEFCONFIG_URL=${BASE_URL}/${PUB_DEST}/defconfig
    mv index.txt "${MACHINE}"-rootfs.index.txt
    bash submit_for_testing.sh
done

# cleanup virtualenv
deactivate
rm -rf .venv
## vim: set sw=4 sts=4 et foldmethod=syntax : ##
