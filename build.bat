@echo off
setlocal

set "ZMAC_BIN=zmac"
if defined ZMAC set "ZMAC_BIN=%ZMAC%"

"%ZMAC_BIN%" src\seawolf2_disassembly.asm
if errorlevel 1 exit /b 1

if not exist roms mkdir roms

powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('src\seawolf2_disassembly.bin'); 0..3 | ForEach-Object { [IO.File]::WriteAllBytes(('roms\sw2x{0}.bin' -f ($_+1)), $b[($_*2048)..(($_*2048)+2047)]) }"
if errorlevel 1 exit /b 1

powershell -NoProfile -Command "Compress-Archive -Force -Path roms\sw2x1.bin,roms\sw2x2.bin,roms\sw2x3.bin,roms\sw2x4.bin -DestinationPath roms\seawolf2.zip"
if errorlevel 1 exit /b 1

certutil -hashfile roms\sw2x1.bin SHA1
certutil -hashfile roms\sw2x2.bin SHA1
certutil -hashfile roms\sw2x3.bin SHA1
certutil -hashfile roms\sw2x4.bin SHA1

