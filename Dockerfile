FROM ubuntu:22.04
LABEL maintainer="piers@piersandkatie.com"
LABEL website="https://piers.rocks"

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
        build-essential \
        git \
        vim \
        wget && \
    apt clean && \
    rm -fr /var/lib/apt/lists/*

# Set up output and build directories
RUN mkdir -p /output/1541/ && \
    mkdir /builds/ 

# Build acme (6502 compiler)
RUN cd /builds && \
    git clone https://github.com/meonwax/acme && \
    cd acme/src/ && \
    make 

# Install ARM GNU toolchain
ENV TOOLCHAIN="arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi"
ENV TOOLCHAIN_URL="https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz"
ENV TOOLCHAIN_PREFIX="arm-none-eabi-"
RUN cd /builds && \
    wget "${TOOLCHAIN_URL}" -O ${TOOLCHAIN}.tar.xz && \
    unxz ${TOOLCHAIN}.tar.xz && \
    tar xf ${TOOLCHAIN}.tar
ENV PREFIX=/builds/${TOOLCHAIN}/bin/${TOOLCHAIN_PREFIX}

# Build kernel.img
ARG RASPPI_TYPE=3
ENV RASPPI=${RASPPI_TYPE}
RUN cd /builds && \
    git clone https://github.com/pi1541/Pi1541 && \
    cd Pi1541/ && \
    echo "RASPPI=${RASPPI}" && \
    echo "PREFIX=${PREFIX}" && \
    make && \
    cp kernel.img /output/ 

# Build CBM File Browser
ENV ACME=/builds/acme/src/acme
RUN cd /builds/Pi1541/CBM-FileBrowser_v1.6/sources/ && \
    $ACME --cpu 6502 -f cbm -o fb64.prg c64.asm && \
    $ACME --cpu 6502 -f cbm -o fb64dtv.prg c64dtv.asm && \
    $ACME --cpu 6502 -f cbm -o fb20.prg vic20-unexp.asm && \
    $ACME --cpu 6502 -f cbm -o fb20-3k.prg vic20-3k.asm && \
    $ACME --cpu 6502 -f cbm -o fb20-8k.prg vic20-8k.asm && \
    $ACME --cpu 6502 -f cbm -o fb20-mc.prg vic20-mc.asm && \
    $ACME --cpu 6502 -f cbm -o fb16.prg c16.asm && \
    $ACME --cpu 6502 -f cbm -o fb128.prg c128.asm && \
    cp fb64.prg fb64dtv.prg fb20.prg fb20-3k.prg fb20-8k.prg fb20-mc.prg fb16.prg fb128.prg /output/1541/

# Modify options.txt for my Pi1541 Hat (Option B)
RUN cp /builds/Pi1541/options.txt /output/ && \
    sed -i -- 's/\/\/splitIECLines = 1/splitIECLines = 1/' /output/options.txt && \
    sed -i -- 's/\/\/LCDName = ssd1306_128x64/LCDName = ssd1306_128x64/' /output/options.txt && \
    sed -i -- 's/\/\/SoundOnGPIO = 1/SoundOnGPIO = 1/' /output/options.txt && \
    sed -i -- 's/\/\/SoundOnGPIODuration = 100/SoundOnGPIODuration = 1000/' /output/options.txt && \
    sed -i -- 's/\/\/SoundOnGPIOFreq = 200/SoundOnGPIOFreq = 1200/' /output/options.txt && \
    sed -i -- 's/\/\/i2cBusMaster = 1/i2cBusMaster = 1/' /output/options.txt

# Get Raspberry Pi firmware
RUN cd /output/ && \
    wget https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/bootcode.bin && \
    wget https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/start.elf && \
    wget https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/fixup.dat

# Get VICE files
RUN cd /output/ && \
    wget https://raw.githubusercontent.com/libretro/vice-libretro/master/vice/data/DRIVES/dos1541-325302-01+901229-05.bin -O /output/dos1541 && \
    wget https://raw.githubusercontent.com/libretro/vice-libretro/master/vice/data/C64/chargen-901225-01.bin -O /output/chargen

# Create config.txt
RUN echo "kernel_address=0x1f00000" > /output/config.txt && \
    echo "force_turbo=1" >> /output/config.txt

# Set file permissions on output files
RUN chmod -R 777 /output/

# Zip it up
RUN cd /output/ && \
    tar cvf /pi1541.tar ./* && \
    ls -ltra /

# Do nothing (allows host scripts to copy files from /output/
VOLUME ['output']
CMD tail -f /dev/null
