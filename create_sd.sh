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
docker build . -t $IMG_NAME

# Get the files out of the container image
$CONT_NAME=pi1541-cont
$FILES_DIR=/tmp/pi1541-files
$CONT_FILES_DIR=/tmp/pi1541-cont-files
rm -fr $FILES_DIR
rm -fr $CONT_FILES_DIR
docker rm -f $CONT_NAME
mkdir $FILES_DIR
mkdir $CONT_FILES_DIR
docker run -d --name $CONT_NAME -v $CONT_FILES_DIR:/output $IMG_NAME
sudo cp -pr $CONT_FILES_DIR/* $FILES_DIR/
docker rm -f $CONT_NAME
rm -fr $CONT_FILES_DIR

# Format the SD card
sudo wipefs --all --force $SDCARD
sudo parted -s $SDCARD mklabel msdos
sudo parted -s $SDCARD mkpart primary fat32 1MiB 100%

# Mount the SD card and copy the files over
$MNT_DIR=/tmp/pi1541-sd
rm -fr $MNT_DIR
mkdir $MNT_DIR
sudo mount ${SDCARD}1 $MNT_DIR
sudo cp -r $FILES_DIR/* $MNT_DIR/
echo "All files created on SD Card: $SDCARD"
find $MNT_DIR/
sudo umount $MNT_DIR
rm -fr $MNT_DIR

# Remove the files
rm -fr $FILES_DIR

echo "Done"
