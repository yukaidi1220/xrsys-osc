@echo off
REM ===========================================================
REM SPDX-License-Identifier: GPL-3.0-or-later
REM 版权所有 (C) 潇然工作室
REM 未经作者许可，不得删除或修改此文件中的版权和许可信息
REM ===========================================================
chcp 936 > nul
cd /d "%~dp0"
call "%~dp0..\..\common\env.bat" OSC
title 主题恢复
if exist "%SystemDrive%\Windows\Setup\xrsysnotheme.txt" exit

ver | find /i "10.0." > nul && (
    for /f "tokens=6 delims=[]. " %%a in ('ver') do set bigversion=%%a
    for /f "tokens=7 delims=[]. " %%b in ('ver') do set smallversion=%%b
)

if exist "%SystemDrive%\Windows\Setup\xrsyswall.jpg" (
    copy /y "%SystemDrive%\Windows\Setup\xrsyswall.jpg" wallpaper.jpg
)
if exist "%SystemDrive%\Windows\Setup\Set\wallpaper.jpg" (
    copy /y "%SystemDrive%\Windows\Setup\Set\wallpaper.jpg" wallpaper.jpg
)

if %XRSYS_OSC_WINDOWS_VERSION_LEVEL% GEQ 2 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\Tablet PC" /v DeviceKind') do if /i not "%%a"=="0x0" call :touch
)

:main
if exist "%SystemDrive%\Windows\Setup\xrsysdark.txt" (
    if exist "%SystemDrive%\Windows\Resources\Themes\dark.theme" (
        start "" "%SystemDrive%\Windows\Resources\Themes\dark.theme"
    )
) else (
    if exist "%SystemDrive%\Windows\Resources\Themes\Light.theme" (
        start "" "%SystemDrive%\Windows\Resources\Themes\Light.theme"
    ) else if exist "%SystemDrive%\Windows\Resources\Themes\aero.theme" (
        start "" "%SystemDrive%\Windows\Resources\Themes\aero.theme"
    )
)
timeout -t 3 2>nul || ping 127.0.0.1 -n 3 >nul
taskkill /F /IM SystemSettings.exe
if %XRSYS_OSC_WINDOWS_VERSION_LEVEL% GEQ 2 %XRSYS_OSC_PECMD_EXE% TEAM FIND --class:CabinetWClass --wid* R^|KILL @@%%R%% 
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Themes\Custom.theme"
goto setwall

:setwall
cd /d "%~dp0"
timeout /t 5
if exist "%SystemDrive%\Windows\Setup\xrsysnowall.txt" exit
if exist wallpaper.jpg (
    copy /y wallpaper.jpg "%SystemDrive%\Windows\Version.jpg"
    %XRSYS_OSC_PECMD_EXE% WALL "%SystemDrive%\Windows\Version.jpg"
    if %XRSYS_OSC_WINDOWS_VERSION_LEVEL% GEQ 2 (
        reg add "HKCU\Control Panel\Desktop" /f /v "Wallpaper" /d "%SystemDrive%\Windows\Version.jpg"
        reg add "HKCU\Control Panel\Desktop" /f /v "WallpaperStyle" /d "10"
        RunDll32.exe USER32.DLL,UpdatePerUserSystemParameters
    )
)
reg delete "HKCU\Control Panel\Desktop" /f /v "Wallpaper.PECMD"
exit

:touch
if exist "%ProgramW6432%" (
    PinToTaskbar.exe /pin "%SystemDrive%\Windows\System32\osk.exe"
) else (
    %XRSYS_OSC_PECMD_EXE% PINT "%SystemDrive%\Windows\System32\osk.exe",TaskBand
)
regedit /s touch.reg
goto :EOF
