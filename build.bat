@echo off
setlocal

echo Sea Wolf II ROM build
echo Input: src\seawolf2.asm
echo.
echo [1/4] Assemble the 8 KB program image
echo ^> tools\zmac.exe -o src\seawolf2.bin src\seawolf2.asm
tools\zmac.exe -o src\seawolf2.bin src\seawolf2.asm
if errorlevel 1 exit /b 1
echo Created: src\seawolf2.bin
echo Created: src\seawolf2.lst

echo.
echo [2/4] Split the image into four 2 KB ROMs
if not exist roms mkdir roms
powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('src\seawolf2.bin'); 0..3 | ForEach-Object { [IO.File]::WriteAllBytes(('roms\sw2x{0}.bin' -f ($_+1)), $b[($_*2048)..(($_*2048)+2047)]) }"
if errorlevel 1 exit /b 1
echo Created: roms\sw2x1.bin
echo Created: roms\sw2x2.bin
echo Created: roms\sw2x3.bin
echo Created: roms\sw2x4.bin

echo.
echo [3/4] Package the MAME ROM set
echo ^> powershell Compress-Archive ... roms\seawolf2.zip
powershell -NoProfile -Command "Compress-Archive -Force -Path roms\sw2x1.bin,roms\sw2x2.bin,roms\sw2x3.bin,roms\sw2x4.bin -DestinationPath roms\seawolf2.zip"
if errorlevel 1 exit /b 1
echo Created: roms\seawolf2.zip

echo.
echo [4/4] SHA1
powershell -NoProfile -Command "'roms\sw2x1.bin','roms\sw2x2.bin','roms\sw2x3.bin','roms\sw2x4.bin' | ForEach-Object { $h=(Get-FileHash $_ -Algorithm SHA1).Hash.ToLower(); '{0}  {1}' -f $h,$_ }"
if errorlevel 1 exit /b 1

echo.
echo Build complete: roms\seawolf2.zip
