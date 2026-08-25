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
echo [4/4] Verify official ROM SHA-1
set "hash_failed=0"
call :verify_sha1 "roms\sw2x1.bin" "c6e411444a824ce54b0eee10f7dc15e4229ec070"
call :verify_sha1 "roms\sw2x2.bin" "63d8c6b77e0aa536b4f5bb774bc9285f736d4265"
call :verify_sha1 "roms\sw2x3.bin" "c9dbeaa4540dc95f98970f501a420b18b9898c91"
call :verify_sha1 "roms\sw2x4.bin" "57d0ddea9f8bf082f50d0468a726fd91aaabf4e4"

echo.
if "%hash_failed%"=="1" (
    echo WARNING: Generated ROMs do not match the official Sea Wolf II ROMs.
    echo Build failed ROM verification.
    exit /b 1
)

echo PASS: All generated ROMs match the official Sea Wolf II SHA-1 values.

echo.
echo Build complete: roms\seawolf2.zip
exit /b 0

:verify_sha1
set "rom_file=%~1"
set "expected_sha1=%~2"
set "actual_sha1="
for /f "usebackq delims=" %%H in (`powershell -NoProfile -Command "(Get-FileHash -LiteralPath '%rom_file%' -Algorithm SHA1).Hash.ToLower()"`) do set "actual_sha1=%%H"
echo %actual_sha1%  %rom_file%
if /I not "%actual_sha1%"=="%expected_sha1%" (
    echo WARNING: SHA-1 mismatch for %rom_file%
    echo   Expected: %expected_sha1%
    echo   Actual:   %actual_sha1%
    set "hash_failed=1"
)
exit /b 0
