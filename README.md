# pi1541-build

These scripts build a pi1541 SD card, using the pi1541, Vice, acme and Raspberry Pi firmware repositories.

IMPORTANT - This script will wipe anything on the path provided to the script.

To use:

```
./create_sd.sh /dev/sdh # Substitute for your SD card path
```

Then add any other files you want to be able to access to the 1541/ directory on the SD card.

Pre-requisites:
* docker
* wipefs
* parted
* mkfs

