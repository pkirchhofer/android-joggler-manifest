#!/bin/bash -ex
# Create bootable Android system image for Joggler (RAW format)

IMAGE_FILE=joggler-android-kitkat-$(date +%F).img
ANDROID_BASEDIR=..

# Create 2GB image file
dd if=/dev/zero of=${IMAGE_FILE} bs=1M seek=$[2*1024] count=0

# Create partitions
# For partition layout see "howto-build-joggler-ics.txt"
parted ${IMAGE_FILE} mklabel msdos
parted --align optimal ${IMAGE_FILE} "mkpart primary fat32 1MiB 500MiB"
parted --align optimal ${IMAGE_FILE} "mkpart primary fat32 500MiB 550MiB"
parted --align optimal ${IMAGE_FILE} "mkpart primary ext4 550MiB 1000MiB"
parted --align optimal ${IMAGE_FILE} "mkpart primary ext4 1000MiB 100%"
parted ${IMAGE_FILE} "set 1 boot on"

# Connect partitions to device nodes
sudo losetup /dev/loop0 ${IMAGE_FILE}
sudo kpartx -a -v /dev/loop0

# Format previously created partitions
sudo mkfs.vfat -n droid-user /dev/mapper/loop0p1
sudo mkfs.vfat -n droid-boot /dev/mapper/loop0p2
sudo mkfs.ext4 -L android-system /dev/mapper/loop0p3
sudo mkfs.ext4 -L android-data /dev/mapper/loop0p4

# Mount partitions
mkdir -p joggler-image/{user,boot,system}
sudo mount /dev/mapper/loop0p1 joggler-image/user
sudo mount /dev/mapper/loop0p2 joggler-image/boot
sudo mount /dev/mapper/loop0p3 joggler-image/system

# Copy Android files
sudo cp ${ANDROID_BASEDIR}/joggler-boot/{boot,startup}.nsh joggler-image/user
sudo cp -R ${ANDROID_BASEDIR}/joggler-boot/* joggler-image/boot
sudo cp -R ${ANDROID_BASEDIR}/out/target/product/joggler/root/* joggler-image/system
sudo cp -R ${ANDROID_BASEDIR}/out/target/product/joggler/system/* joggler-image/system/system
sync

# Unmount partitions
sudo umount joggler-image/{user,boot,system}

# Disconnect image from device nodes
sudo kpartx -d -v /dev/loop0
sudo losetup -d /dev/loop0
