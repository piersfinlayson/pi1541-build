#!/usr/bin/bash
set -e

SDCARD=$1
if [ -z $SDCARD ]; then
    echo "Usage $0 sd_card_path"
    exit
fi
if [ $SDCARD = "/dev/sda" ]; then
    echo "You probably don't want me to reformat /dev/sda.  Exiting"
    exit
fi

# Make container image to provide all the necessary files
IMG_NAME=pi1541-img
docker build . -q -t $IMG_NAME 1> /dev/null

# Get the files out of the container image
CONT_NAME=pi1541-cont
FILES_DIR=/tmp/pi1541-files
rm -fr $FILES_DIR
docker rm -f $CONT_NAME 2>/dev/null
mkdir $FILES_DIR
docker run -qd --name $CONT_NAME $IMG_NAME 1> /dev/null
docker cp -q $CONT_NAME:/pi1541.tar $FILES_DIR
docker rm -f $CONT_NAME 1> /dev/null
tar xf $FILES_DIR/pi1541.tar -C $FILES_DIR

# Format the SD card
sudo wipefs -q --all --force $SDCARD
sudo parted -s $SDCARD mklabel msdos
sudo parted -s $SDCARD mkpart primary fat32 1MiB 100%
sudo mkfs -t vfat ${SDCARD}1 1> /dev/null

# Mount the SD card and copy the files over
MNT_DIR=/tmp/pi1541-sd
rm -fr $MNT_DIR
mkdir $MNT_DIR
sudo mount ${SDCARD}1 $MNT_DIR
sudo cp -r $FILES_DIR/* $MNT_DIR/
echo "All files created on SD Card: $SDCARD"
cd $MNT_DIR
find .
sleep 1
sudo umount -l ${SDCARD}1
rm -r $MNT_DIR

# Remove the files
rm -r $FILES_DIR

echo "Done"
