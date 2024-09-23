# pi1541-build

These scripts build a pi1541 SD card, using the Pi1541, Vice, acme and Raspberry Pi firmware repositories.

IMPORTANT - This script will wipe anything on the path provided to the script.

To use:

```
./create_sd.sh /dev/sdh # Substitute for your SD card path
```

Then add any other files you want to be able to access to the 1541/ directory on the SD card.

Note that there is some code in the Dockerfile to generate a custom options.txt, specifically:
* To set up for hardware Option B (with a 7406)
* To set the LCD to ssd1306_128x64 and enale the I2C bus
* To turn on sound

You may need to modify the Dockerfile, or options.txt produced on the SD card, to fit your hardware and use case.

Pre-requisites:
* docker
* wipefs
* parted
* mkfs

