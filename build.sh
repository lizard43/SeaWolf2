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
echo "[4/4] Verify official ROM SHA-1"

hash_failed=0

verify_sha1() {
    local rom_file="$1"
    local expected_sha1="$2"
    local actual_sha1

    actual_sha1="$(sha1sum "$rom_file" | awk '{print $1}')"
    printf '%s  %s\n' "$actual_sha1" "$rom_file"

    if [[ "$actual_sha1" != "$expected_sha1" ]]; then
        echo "WARNING: SHA-1 mismatch for $rom_file"
        echo "  Expected: $expected_sha1"
        echo "  Actual:   $actual_sha1"
        hash_failed=1
    fi
}

verify_sha1 roms/sw2x1.bin c6e411444a824ce54b0eee10f7dc15e4229ec070
verify_sha1 roms/sw2x2.bin 63d8c6b77e0aa536b4f5bb774bc9285f736d4265
verify_sha1 roms/sw2x3.bin c9dbeaa4540dc95f98970f501a420b18b9898c91
verify_sha1 roms/sw2x4.bin 57d0ddea9f8bf082f50d0468a726fd91aaabf4e4

echo
if [[ "$hash_failed" -ne 0 ]]; then
    echo "WARNING: Generated ROMs do not match the official Sea Wolf II ROMs."
    echo "Build failed ROM verification."
    exit 1
fi

echo "PASS: All generated ROMs match the official Sea Wolf II SHA-1 values."

echo
echo "Build complete: roms/seawolf2.zip"
