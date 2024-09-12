#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs
fi

echo "Adding the Image in outdir"
cd $OUTDIR
cp -a linux-stable/arch/arm64/boot/Image ./

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir rootfs/
cd rootfs/
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# TODO: Make and install busybox
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd "$OUTDIR"

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
aarch64-none-linux-gnu-readelf -a bin/busybox | grep "program interpreter"
aarch64-none-linux-gnu-readelf -a bin/busybox | grep "Shared library"

SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
INTERPRETER=$(find $SYSROOT -name "ld-linux-aarch64.so.1")
echo "$INTERPRETER"
cp ${INTERPRETER} ${OUTDIR}/rootfs/lib
cp ${INTERPRETER} ${OUTDIR}/rootfs/usr/lib
cp ${INTERPRETER} ${OUTDIR}/rootfs/home
SHARED_LIB_1=$(find $SYSROOT -name "libm.so.6")
echo "$SHARED_LIB_1"
cp ${SHARED_LIB_1} ${OUTDIR}/rootfs/lib64
cp ${SHARED_LIB_1} ${OUTDIR}/rootfs/usr/lib
cp ${SHARED_LIB_1} ${OUTDIR}/rootfs/home
SHARED_LIB_2=$(find $SYSROOT -name "libresolv.so.2")
echo "$SHARED_LIB_2"
cp ${SHARED_LIB_2} ${OUTDIR}/rootfs/lib64
cp ${SHARED_LIB_2} ${OUTDIR}/rootfs/usr/lib
cp ${SHARED_LIB_2} ${OUTDIR}/rootfs/home
SHARED_LIB_3=$(find $SYSROOT -name "libc.so.6")
echo "$SHARED_LIB_3"
cp ${SHARED_LIB_3} ${OUTDIR}/rootfs/lib64
cp ${SHARED_LIB_3} ${OUTDIR}/rootfs/usr/lib
cp ${SHARED_LIB_3} ${OUTDIR}/rootfs/home

# TODO: Make device nodes
cd rootfs/
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=1

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp finder.sh ${OUTDIR}/rootfs/home
cp finder-test.sh ${OUTDIR}/rootfs/home
cp writer ${OUTDIR}/rootfs/home
cp conf/username.txt ${OUTDIR}/rootfs/home
cp conf/assignment.txt ${OUTDIR}/rootfs/home
cp start-qemu-app.sh ${OUTDIR}/rootfs/home
cp autorun-qemu.sh ${OUTDIR}/rootfs/home

# TODO: Chown the root directory
cd "$OUTDIR"/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio
