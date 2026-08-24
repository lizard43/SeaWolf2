#!/usr/bin/env bash
set -e

./tools/zmac -o src/seawolf2.bin src/seawolf2.asm

mkdir -p roms

dd if=src/seawolf2.bin of=roms/sw2x1.bin bs=2048 skip=0 count=1 status=none
dd if=src/seawolf2.bin of=roms/sw2x2.bin bs=2048 skip=1 count=1 status=none
dd if=src/seawolf2.bin of=roms/sw2x3.bin bs=2048 skip=2 count=1 status=none
dd if=src/seawolf2.bin of=roms/sw2x4.bin bs=2048 skip=3 count=1 status=none

zip -jqFS roms/seawolf2.zip roms/sw2x1.bin roms/sw2x2.bin roms/sw2x3.bin roms/sw2x4.bin
sha1sum roms/sw2x1.bin roms/sw2x2.bin roms/sw2x3.bin roms/sw2x4.bin
