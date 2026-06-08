@echo off
chcp 936 > nul
setlocal enabledelayedexpansion
title Edge 主页测试 - master_preferences 方案

REM ===================================================================
REM   测试目标：验证 master_preferences 方案能否给全新 Edge 设置主页
REM   测试方法：清掉已有用户配置 → 写 master_preferences → 启动 Edge
REM   作者：测试用，请在虚拟机里跑
REM ===================================================================

REM ====== 可改参数 ======
set "HOMEPAGE=https://111"
set "STARTUP_URL=https://222"
REM ======================

echo.
echo ================================================================
echo                Edge 主页设置测试 ^(master_preferences^)
echo ================================================================
echo.
echo 目标主页 : %HOMEPAGE%
echo 启动页   : %STARTUP_URL%
echo.
echo 本脚本会做以下事情：
echo   1) 杀掉所有 Edge 进程
echo   2) 备份并清空 Edge 用户配置 ^(为了模拟全新用户^)
echo   3) 找到 Edge 安装目录，写入 master_preferences 和 initial_preferences
echo   4) 启动 Edge 观察效果
echo.
echo 提示：在虚拟机里跑，跑完前请确认 Edge 里没有重要数据！
echo.
pause

REM ============== 第 1 步：杀进程 ==============
echo.
echo [1/4] 杀掉 Edge 进程...
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
timeout /t 2 /nobreak >nul
pause


REM ============== 第 2 步：清用户配置 ==============
echo.
echo [2/4] 备份并清空 Edge 用户配置 ^(模拟全新用户^)...
set "EDGE_USERDATA=%LOCALAPPDATA%\Microsoft\Edge\User Data"
set "BACKUP_DIR=%TEMP%\EdgeBackup_%RANDOM%"
if exist "%EDGE_USERDATA%" (
    echo   备份到: %BACKUP_DIR%
    move "%EDGE_USERDATA%" "%BACKUP_DIR%" >nul 2>&1
    if exist "%EDGE_USERDATA%" (
        echo   [警告] 备份失败^(可能 Edge 还没完全退出^)，尝试强删
        rd /s /q "%EDGE_USERDATA%" 2>nul
    )
) else (
    echo   未发现已有配置，无需备份。
)
pause

REM ============== 第 3 步：定位 Edge 安装目录并写文件 ==============
echo.
echo [3/4] 定位 Edge 安装目录并写入配置...

set "EDGE_APPDIR="
for %%P in (
    "%ProgramFiles(x86)%\Microsoft\Edge\Application"
    "%ProgramFiles%\Microsoft\Edge\Application"
) do (
    if exist "%%~P\msedge.exe" (
        set "EDGE_APPDIR=%%~P"
        echo   找到 Edge: %%~P
        goto :writepref
    )
)
pause

echo   [错误] 没找到 msedge.exe，请确认 Edge 已安装！
pause
exit /b 1

:writepref
REM 写入 master_preferences（旧名）和 initial_preferences（新名）
REM Edge 新版本认 initial_preferences，老的认 master_preferences，两个都写最稳

set "PREF_FILE_OLD=%EDGE_APPDIR%\master_preferences"
set "PREF_FILE_NEW=%EDGE_APPDIR%\initial_preferences"

echo   写入 JSON 配置...
(
    echo {
    echo   "homepage": "%HOMEPAGE%",
    echo   "homepage_is_newtabpage": false,
    echo   "browser": {
    echo     "show_home_button": true,
    echo     "check_default_browser": false
    echo   },
    echo   "session": {
    echo     "restore_on_startup": 4,
    echo     "startup_urls": [ "%STARTUP_URL%" ]
    echo   },
    echo   "distribution": {
    echo     "skip_first_run_ui": true,
    echo     "import_search_engine": false,
    echo     "import_history": false,
    echo     "make_chrome_default": false,
    echo     "suppress_first_run_bubble": true,
    echo     "do_not_create_desktop_shortcut": false,
    echo     "do_not_create_quick_launch_shortcut": false,
    echo     "do_not_create_taskbar_shortcut": false,
    echo     "do_not_launch_chrome": false,
    echo     "system_level": true,
    echo     "verbose_logging": false
    echo   }
    echo }
) > "%PREF_FILE_OLD%"

copy /y "%PREF_FILE_OLD%" "%PREF_FILE_NEW%" >nul

if exist "%PREF_FILE_OLD%" (
    echo   [OK] 已写入: %PREF_FILE_OLD%
    echo   [OK] 已写入: %PREF_FILE_NEW%
) else (
    echo   [错误] 文件写入失败！可能需要管理员权限。
    pause
    exit /b 1
)

echo.
echo   ----- 写入的内容 -----
type "%PREF_FILE_OLD%"
echo   ----------------------

REM ============== 第 4 步：启动 Edge 测试 ==============
echo.
echo [4/4] 启动 Edge 测试...
echo.
echo 即将启动 Edge，请观察：
echo   - 首页是否变成 %HOMEPAGE%
echo   - 点首页按钮 ^(房子图标^) 是否跳转到 %HOMEPAGE%
echo   - 是否显示 "由你的组织管理" ^(应该没有^)
echo.
pause

start "" "%EDGE_APPDIR%\msedge.exe"

echo.
echo ================================================================
echo  测试启动完毕！如果不符合预期，把命令行输出截图给我。
echo.
echo  恢复方法：
echo    - 删除测试主页配置:
echo        del "%PREF_FILE_OLD%"
echo        del "%PREF_FILE_NEW%"
echo    - 恢复备份的用户数据:
if defined BACKUP_DIR if exist "%BACKUP_DIR%" (
    echo        move "%BACKUP_DIR%" "%EDGE_USERDATA%"
)
echo ================================================================
echo.

pause
endlocal
