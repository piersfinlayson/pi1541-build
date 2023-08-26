#!/usr/bin/bash
set -e

SDCARD=$1
if [ -z $SDCARD ] || [ $SDCARD = '-?' ] || [ $SDCARD = '-h' ] || [ $SDCARD = '--help' ]; then
    echo "Usage $0 sd_card_path [raspi_type]"
    echo "  raspi_type: If provided must take a type from:"
    echo "              https://github.com/pi1541/Pi1541/blob/master/Makefile.rules"
    echo "              Current valid values: 0, 1BRev1, 1BRev2, 1BPlus, 2, 3"
    echo "              Default: 3"
    exit
fi
if [ $SDCARD = "/dev/sda" ]; then
    echo "You probably don't want me to reformat /dev/sda.  Exiting"
    exit
fi
PI_TYPE=$2
if [ -z $PI_TYPE ]; then
    PI_TYPE=3
fi

echo "Will create Pi1541 image for Pi $PI_TYPE on SD card: $SDCARD"

# Make container image to provide all the necessary files
IMG_NAME=pi1541-img
echo "Building"
docker build . -q -t $IMG_NAME --build-arg="RASPPI_TYPE=${PI_TYPE}" 1> /dev/null

# Get the files out of the container image
echo "Collating files"
CONT_NAME=pi1541-cont
FILES_DIR=/tmp/pi1541-files
rm -fr $FILES_DIR
docker rm -f $CONT_NAME 2>/dev/null
mkdir $FILES_DIR
docker run -qd --name $CONT_NAME $IMG_NAME 1> /dev/null
docker cp -q $CONT_NAME:/pi1541.tar $FILES_DIR
docker rm -f $CONT_NAME 1> /dev/null
tar xf $FILES_DIR/pi1541.tar -C $FILES_DIR
rm $FILES_DIR/pi1541.tar

# Format the SD card
echo "Formatting SD card: $SDCARD"
sudo wipefs -q --all --force $SDCARD
sudo parted -s $SDCARD mklabel msdos
sudo parted -s $SDCARD mkpart primary fat32 1MiB 100%
sudo mkfs -t vfat ${SDCARD}1 1> /dev/null

# Mount the SD card and copy the files over
echo "Writing files to SD card: $SDCARD"
MNT_DIR=/tmp/pi1541-sd
rm -fr $MNT_DIR
mkdir $MNT_DIR
sudo mount ${SDCARD}1 $MNT_DIR
sudo cp -r $FILES_DIR/* $MNT_DIR/
echo "All files created on SD Card: $SDCARD"
cd $MNT_DIR
find . -type f | xargs ls -ltr
sleep 1
sudo umount -l ${SDCARD}1
rm -r $MNT_DIR

# Remove the files
rm -r $FILES_DIR

echo "Done"
