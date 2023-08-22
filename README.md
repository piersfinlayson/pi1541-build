# pi1541-build

These scripts build a pi1541 SD card, using the pi1541, Vice, acme and Raspberry Pi firmware repositories.

To use:

```
./create_sd.sh /dev/sdh # Substitute for your SD card path
```

Note that this will wipe whatever drive you enter the path to.

Pre-requisites:
* docker
* wipefs
* parted

