chcp 936 > nul
title OSConline
cd /d "%~dp0"
call "%~dp0..\common\env.bat" OSC
set url1=https://url.xrgzs.top
set url2=https://dl.xrgzs.top/d/url
set url3=https://list.xrgzs.top/d/url
set url=%url1%


if exist pack.7z (
    echo [OSC]正在解压pack...>"%systemdrive%\Windows\Setup\wallname.txt"
    %XRSYS_OSC_7Z_EXE% x -r -y -p123 pack.7z
    del /f /q pack.7z
    echo ok >unpacked.log
)

if exist "%SystemDrive%\Windows\Setup\Set\zjsoftforceoffline.txt" goto offline
if exist "%SystemDrive%\Windows\Setup\zjsoftforceoffline.txt" goto offline
ping www.aliyun.com -4 -n 2 >nul
if %errorlevel% GEQ 1 goto offline
goto try

:try
%XRSYS_OSC_ARIA2_CMD% -o checkconnect.txt "%url%/checkconnect"
type checkconnect.txt | find /i "isconnected" > nul && goto online
goto retry

:retry
echo 服务器%url%连接失败，
if "%url%"=="%url1%" (
    set "url=%url2%"
) else if "%url%"=="%url2%" (
    set "url=%url3%"
) else if "%url%"=="%url3%" goto offline
echo 更换下一个服务器%url%！
goto try

:offline
if exist oscoffline.bat (
    copy /y oscoffline.bat osconline.bat
    goto online
)
if exist pack.bat (
    copy /y pack.bat osconline.bat
    goto online
)
goto local2

:online
REM ── 兼容映射：oscoffline.bat/osconline.bat 由上游在线下发，仍用旧变量名 ──
set aria=%XRSYS_OSC_ARIA2_CMD%
set zip=%XRSYS_OSC_7Z_EXE%
set pecmd=%XRSYS_OSC_PECMD_EXE%
set wbox=%XRSYS_OSC_WBOX_EXE%
set nsudo=%XRSYS_OSC_NSUDO_EXE%
set dmi=%XRSYS_OSC_DMI_EXE%
set netuser=%XRSYS_OSC_NETUSER_EXE%
set nircmd=%XRSYS_OSC_NIRCMD_EXE%
set winput=%XRSYS_OSC_WINPUT_EXE%
set drvindex=%XRSYS_OSC_DRVINDEX_EXE%
set srtool=%XRSYS_OSC_SRTOOL_EXE%
set wlan=%XRSYS_OSC_WLAN_EXE%
set osver=%XRSYS_OSC_WINDOWS_VERSION_LEVEL%
set osname=%XRSYS_OSC_WINDOWS_NAME%
REM ──────────────────────────────────────────
cd /d "%~dp0"
if exist osconline.bat (
    call osconline.bat
) else (
    %XRSYS_OSC_ARIA2_CMD% -o osconline.bat "%url%/osconline"
    if exist osconline.bat (
        call osconline.bat
    )
)
goto local2

:local2
if exist "%SystemDrive%\Windows\Setup\Run\2\api2.bat" (
    echo [OSC]正在应用DIY接口api2.bat...>"%systemdrive%\Windows\Setup\wallname.txt"
    start "" /max /wait "%SystemDrive%\Windows\Setup\Run\2\api2.bat"
)
for %%b in (%SystemDrive%\Windows\Setup\Run\2\*.exe) do (
    echo [OSC]正在安装预装软件%%b...>"%systemdrive%\Windows\Setup\wallname.txt"
    start "" /wait "%%b" /S
    del /f /q "%%b"
)
for %%b in (%SystemDrive%\Windows\Setup\Run\2\*.msi) do (
    echo [OSC]正在安装预装软件%%b...>"%systemdrive%\Windows\Setup\wallname.txt"
    start "" /wait "%%b" /passive /qb-! /norestart
    del /f /q "%%b"
)
for %%b in (%SystemDrive%\Windows\Setup\Run\2\*.reg) do (
    echo [OSC]正在应用注册表%%b...>"%systemdrive%\Windows\Setup\wallname.txt"
    regedit /s "%%b"
    del /f /q "%%b"
)

if exist "%SystemDrive%\Windows\Setup\xrsyssearchapi.txt" (
    for %%a in (C D E F G H) do (
        if exist "%%a:\EEEOS\OSC\api2.bat" (
            echo [OSC]正在应用搜到的DIY接口%%a:\~\api2.bat...>"%systemdrive%\Windows\Setup\wallname.txt"
            start "" /max /wait "%%a:\EEEOS\OSC\api2.bat"
        )
        for %%b in (%%a:\EEEOS\OSC\2\*.exe) do (
            echo [OSC]正在运行搜到的%%b...>"%systemdrive%\Windows\Setup\wallname.txt"
            start "" /wait "%%b" /S
            del /f /q "%%b"
        )
        for %%b in (%%a:\EEEOS\OSC\2\*.msi) do (
            echo [OSC]正在安装搜到的%%b...>"%systemdrive%\Windows\Setup\wallname.txt"
            start "" /wait "%%b" /passive /qb-! /norestart
            del /f /q "%%b"
        )
        for %%b in (%%a:\EEEOS\OSC\2\*.reg) do (
            echo [OSC]正在应用搜到的%%b...>"%systemdrive%\Windows\Setup\wallname.txt"
            regedit /s "%%b"
            del /f /q "%%b"
        )
    )
)
goto end

:end
exit