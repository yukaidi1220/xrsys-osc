# 开发注意事项

> 本文件记录在维护 xrsys-osc（EEEOS fork）过程中踩过的坑与硬性规则。
> 面向：本仓库的维护者、以及协助本仓库的 AI Agent。

---

## ⚠️ 绝对禁止：在宿主机上运行部署脚本

`osc.exe` 解包后是一组**为 PE / 全新部署环境设计的一次性破坏性脚本**。在正常使用的 Windows 上直接执行其中任何一个 `.bat`，都可能造成不可逆破坏。

### 真实事故（2026-10-26）

一次代码审查中，为「验证脚本能运行」而在仓库根目录执行了 `api/api.bat`：

```
api.bat 第 23 行: if not exist apifiles\DriveCleaner.exe (
api.bat 第 24 行:     shutdown -s -t 30 -c "系统部署文件损坏，即将关机终止部署（API）"
```

因为仓库根目录没有 `apifiles\DriveCleaner.exe`（它在 `osc\apifiles\`），完整性检查失败，直接触发了 **30 秒后关机**。系统事件日志 `ID 1074` 记录 `shutdown.exe` 代表用户发起关机，用户屏幕上弹出关机提示。

### 这些脚本里的破坏性命令

| 命令 | 出现位置 | 后果 |
|---|---|---|
| `shutdown -s/-r` | api.bat（3 处）、osc.bat、runonce.bat | 关机/重启 |
| `taskkill /f /im explorer.exe` | start.bat 等 | 桌面崩溃 |
| `rd /s /q` | postsoftware.bat、DelDrvCeo.bat | 删目录 |
| `reg add` / `reg delete` | 大量脚本 | 改注册表 |
| `NET USER ... /ACTIVE:` | api.bat | 改账户状态 |
| `del /f /s /q` | 多处 | 批量删文件 |

### 允许的验证方式

| 方式 | 说明 |
|---|---|
| ✅ 静态分析 | 括号配平、标签/goto 对应、变量定义与引用一致性 |
| ✅ 语法解析 | PowerShell `[ScriptBlock]::Create()`；批处理无法真正解析，只能静态检查 |
| ✅ 字节检查 | 编码（GBK/UTF-8 BOM/UTF-16LE）、换行（CRLF） |
| ✅ `common/env.bat` 单独执行 | 它是纯 `set` 变量定义，无副作用 |
| ✅ 目录结构模拟 | 在 `D:\tmp` 建镜像布局，只跑 `env.bat` 验证变量解析 |
| ✅ CI 构建 | `build.yml` 编译 NSIS 安装包 |
| ✅ 7-Zip 解包 | `7z x osc.exe` 检查内部文件字节，**不执行** |
| ✅ 虚拟机开机测试 | 在 QEMU/VM 里跑完整部署（唯一能验证行为的方式） |
| ❌ 在宿主机执行任何 `.bat` | **绝对禁止** |

**给 AI Agent 下任务时必须显式写明：禁止执行任何 .bat/.cmd 文件，只做静态检查。**

---

## 编码与换行（Windows 下错误即静默失败）

### 现状与要求

| 文件类型 | 编码 | 换行 | 说明 |
|---|---|---|---|
| `.bat` / `.cmd` | **GBK**（无 BOM） | CRLF | 脚本内 `chcp 936`，文件必须是 GBK，否则中文全乱、`find`/`goto` 匹配失败 |
| `.ps1` | **UTF-8 with BOM** | CRLF | 无 BOM 时 PowerShell 5.1 按 ANSI 读，中文乱码、正则匹配失效 |
| `.ps1`（LockScreenStatus） | **UTF-16LE** | 原样 | 特例，`.gitattributes` 里标 `binary` |
| `.nsi` / `.wcs` | UTF-8 with BOM | CRLF | NSIS 需 BOM 才按 UTF-8 读 |
| `.reg` | **UTF-16LE** | 原样 | 标 `binary`，禁止任何转换 |
| `.txt`（软件清单） | GBK | CRLF | `software.bat` 按行解析 |

### `.gitattributes` 的作用

```gitattributes
* text=auto eol=lf                 # 仓库内存 LF
*.bat text eol=crlf                # 检出时转 CRLF（GBK 字节不动）
*.ps1 text eol=crlf
*.nsi text eol=crlf
*.wcs text eol=crlf
*.txt text eol=crlf
osc/optimize/LockScreenStatus.ps1 binary   # UTF-16LE 例外
*.reg binary
*.exe binary
...
```

**关键陷阱**：
- ❌ 不要用 `binary` 锁 `.bat`——`binary` 表示 git 完全不管换行，仓库存 LF 检出还是 LF
- ✅ 用 `text eol=crlf`，git 会自动在检出时转 CRLF，仓库内保持 LF
- ⚠️ 新增 `.gitattributes` 后**必须全量重检出**（`git rm -r --cached . && git reset --hard`），否则工作区文件不会自动变 CRLF

### 编码校验命令

```bash
# 换行：按字节计数（grep -c 数的是行数，会把全 LF 文件误判为通过）
crlf=$(xxd -p "$f" | tr -d '\n' | grep -o '0d0a' | wc -l)
lf=$(xxd -p "$f"   | tr -d '\n' | grep -o '0a'   | wc -l)
cr=$(xxd -p "$f"   | tr -d '\n' | grep -o '0d'   | wc -l)
# 纯 CRLF 判定：crlf == lf && cr == lf
```

```powershell
# GBK 合法性：严格解码（默认 GetString 用 BestFit 回退，非法字节不报错，检查无效）
$strict = [Text.Encoding]::GetEncoding(936,
    [Text.EncoderFallback]::ExceptionFallback,
    [Text.DecoderFallback]::ExceptionFallback)
try { $null = $strict.GetString([IO.File]::ReadAllBytes($f)) }
catch { "非 GBK 字节: $f" }
```

```powershell
# .ps1 落盘必须显式带 BOM（PS 5.1 的 Set-Content/Out-File 会丢 BOM 变 ANSI）
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($true))
```

---

## 架构：common/env.bat 变量体系

### 设计

所有脚本的环境变量统一由 `common/env.bat` 定义，脚本开头 `call` 它：

```bat
chcp 936 > nul
@echo off
cd /d "%~dp0"
call "%~dp0..\common\env.bat" OSC
if not defined XRSYS_OSC_WINDOWS_VERSION_LEVEL exit
```

### 路径规则（各脚本不同，必须逐一核对）

| 脚本位置 | call 路径 |
|---|---|
| `osc\osc.bat` | `..\common\env.bat` |
| `api.bat`（根） | `common\env.bat`（防御式：`%~dp0common` 优先，回退 `..\common`） |
| `osc\runtime\runtime.bat` | `..\..\common\env.bat` |
| `osc\optimize\*.bat` | `..\..\common\env.bat` |
| `osc\themerec\themerec.bat` | `..\..\common\env.bat` |
| `osc\xrkms\xrkms.bat` | `..\..\common\env.bat` |
| `osc\Office\MSOInst.bat` | `..\..\common\env.bat` |

### 致命陷阱：独立进程不继承变量

`osc.bat` 用 `start "" /wait /min xxx.bat` 启动的脚本都是**独立进程**，**拿不到**调用方的变量（包括 `setlocal` 内的）。

以下脚本被独立进程启动，**必须自带 `call env.bat`**：
`runtime.bat`、`online.bat`（已删）、`start.bat`、`regimporter.bat`、`themerec.bat`、`xrkms.bat`、`MSOInst.bat`、`software.bat`、`postsoftware.bat`

**反过来**：需要传给独立进程的变量，必须在 `setlocal` **之前**定义（如 `software.bat` 里的 `zjsoftxrgzs`）。

### 变量映射表（旧名 → 新名）

| 旧 | 新 |
|---|---|
| `osver` | `XRSYS_OSC_WINDOWS_VERSION_LEVEL` |
| `osname` | `XRSYS_OSC_WINDOWS_NAME` |
| `aria` | `XRSYS_OSC_ARIA2_CMD` |
| `dmi` / `netuser` / `nircmd` / `winput` / `wbox` / `nsudo` / `pecmd` / `drvindex` / `srtool` / `wlan` / `zip` | `XRSYS_OSC_DMI_EXE` / `_NETUSER_EXE` / `_NIRCMD_EXE` / `_WINPUT_EXE` / `_WBOX_EXE` / `_NSUDO_EXE` / `_PECMD_EXE` / `_DRVINDEX_EXE` / `_SRTOOL_EXE` / `_WLAN_EXE` / `_7Z_EXE` |

**迁移时的坑**：
- `if not defined osver exit` 这类**守卫判断**必须同步改名，否则整段功能静默跳过（`runtime.bat` 曾踩过：不改则运行库安装全失效）
- `if defined wbox` / `if defined pecmd` 这类**门控**也必须改，否则分支永假（`xrkms.bat` 曾踩过：授权弹窗和 PECMD 包装全失效）
- 代码块内用 `%var%` 还是 `!var!`：只在块内**修改**变量时才需要 `!var!`；env.bat 的变量只在开头赋值一次，用 `%var%` 即可

---

## 上游同步工作流

本仓库是 [xrgzs/xrsys-osc](https://github.com/xrgzs/xrsys-osc) 的 fork，定期同步上游。

### 分支约定

```bash
git remote add upstream https://github.com/xrgzs/xrsys-osc.git
git fetch upstream main
git log --oneline main..upstream/main    # 看落后多少
```

### 冲突处理原则

| 文件类型 | 策略 |
|---|---|
| 品牌文案（title/路径/注册表键） | **保留我方**（EEEOS） |
| 功能脚本（`.ps1` 功能性改进） | **取上游** + 移植我方加固 |
| 二进制 `.reg` | **取上游 blob 覆盖**（`git show upstream:path > path`） |
| 构建 CI | **保留我方** |
| GPL 版权头 | **必须保留**（上游要求） |

### 品牌回填字典

| 上游 | 我方 |
|---|---|
| `%%a:\Xiaoran\OSC\...` | `%%a:\EEEOS\OSC\...` |
| `%%a:\Xiaoran\API\...` | `%%a:\EEEOS\API\...` |
| `XRSYSAPI`（Run 键） | `EEEOSAPI` |
| `title 潇然系统优化组件 XRSYS-OSC` | `title 鹅鹅鹅OS优化组件 EEEOS-OSC` |
| `C:\Program Files\Xiaoran\*` | `C:\Program Files\EEEOS\*` |
| `潇然系统部署背景插件` | `鹅鹅鹅OS部署背景插件` |
| `Xiaoran.ico` / `XRSYSVER` | `EEEOS.ico` / `EEEOSVER` |

**明确不回填**（内部协议 / 功能依赖）：
- 小写 `xrsys` 前缀：`xrsyssoft.txt`、`xrsysdriverdebug.log`、`isxrsys` 标记
- `url.xrgzs.top` 等功能 URL（改了会导致下载失败）
- `XRSYS_OSC_*` 变量名（技术标识）

---

## SPDX 版权头规范

### 格式

`.bat`（放在 `@echo off` **之后**，避免被回显）：
```bat
chcp 936 > nul
@echo off
REM ===========================================================
REM SPDX-License-Identifier: GPL-3.0-or-later
REM 版权所有 (C) 潇然工作室
REM 未经作者许可，不得删除或修改此文件中的版权和许可信息
REM ===========================================================
```

`.ps1`（文件开头）：
```powershell
# ===========================================================
# SPDX-License-Identifier: GPL-3.0-or-later
# 版权所有 (C) 潇然工作室
# 未经作者许可，不得删除或修改此文件中的版权和许可信息
# ===========================================================
```

### 例外
- `osc/optimize/LockScreenStatus.ps1`（UTF-16LE）：跳过
- `osc/xrkms/KMS_VL_ALL_AIO.cmd`（第三方软件）：跳过

---

## 构建与发布

```bash
# CI 自动：push 到 main 触发 build.yml → 构建 → 发 Release
# 版本号格式：YY.M.D.HHmm（北京时间）
```

### 构建红线
1. **不能丢 `build.ps1` 的 aria2c 下载块**（二进制入库策略）
2. **哈希表不能混用**：我方入库的 KMS/HEU 哈希 ≠ 上游 icve 源哈希，套错会构建中断
3. `xrsoft.exe` 从 `file.icve.com.cn` 下载（原 `nos.netease.com` 已失效）

### 产物验证（只读）
```bash
gh release download <tag> -p "osc.exe"
7z x osc.exe -oextracted        # 只解包，不运行
# 检查内部文件编码、关键脚本内容
```
