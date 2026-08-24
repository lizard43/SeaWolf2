#!/usr/bin/env bash
set -e

echo "Sea Wolf II ROM build"
echo "Input: src/seawolf2.asm"
echo
echo "[1/4] Assemble the 8 KB program image"
echo "+ ./tools/zmac -o src/seawolf2.bin src/seawolf2.asm"
./tools/zmac -o src/seawolf2.bin src/seawolf2.asm
echo "Created: src/seawolf2.bin"
echo "Created: src/seawolf2.lst"

echo
echo "[2/4] Split the image into four 2 KB ROMs"
mkdir -p roms
dd if=src/seawolf2.bin of=roms/sw2x1.bin bs=2048 skip=0 count=1 status=none
dd if=src/seawolf2.bin of=roms/sw2x2.bin bs=2048 skip=1 count=1 status=none
dd if=src/seawolf2.bin of=roms/sw2x3.bin bs=2048 skip=2 count=1 status=none
dd if=src/seawolf2.bin of=roms/sw2x4.bin bs=2048 skip=3 count=1 status=none
echo "Created: roms/sw2x1.bin"
echo "Created: roms/sw2x2.bin"
echo "Created: roms/sw2x3.bin"
echo "Created: roms/sw2x4.bin"

echo
echo "[3/4] Package the MAME ROM set"
echo "+ zip -jqFS roms/seawolf2.zip roms/sw2x1.bin roms/sw2x2.bin roms/sw2x3.bin roms/sw2x4.bin"
zip -jqFS roms/seawolf2.zip roms/sw2x1.bin roms/sw2x2.bin roms/sw2x3.bin roms/sw2x4.bin
echo "Created: roms/seawolf2.zip"

echo
echo "[4/4] SHA1"
sha1sum roms/sw2x1.bin roms/sw2x2.bin roms/sw2x3.bin roms/sw2x4.bin

echo
echo "Build complete: roms/seawolf2.zip"
