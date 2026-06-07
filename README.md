<div align="center">

<img src="./osc.ico" alt="xrsys-osc" width="20%" />

# XRSYS-OSC 系统部署组件

[![GitHub Release](https://img.shields.io/github/v/release/yukaidi1220/xrsys-osc?label=最新版本)](https://github.com/yukaidi1220/xrsys-osc/releases)
[![GitHub last commit](https://img.shields.io/github/last-commit/yukaidi1220/xrsys-osc?label=上次提交)](https://github.com/yukaidi1220/xrsys-osc/commits)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/yukaidi1220/xrsys-osc/build.yml?label=CI构建)](https://github.com/yukaidi1220/xrsys-osc/actions)
[![License](https://img.shields.io/github/license/yukaidi1220/xrsys-osc?label=开源许可)](https://github.com/yukaidi1220/xrsys-osc/blob/main/LICENSE)

</div>

> 🍴 本仓库 **Fork 自** [xrgzs/xrsys-osc](https://github.com/xrgzs/xrsys-osc)，在原版基础上进行定制化修改。原项目所有权与版权归原作者所有，本仓库仅作个人使用与二次开发。

---

## 📖 简介

XRSYS-OSC（`osc.exe`）是一个 **Windows 系统部署与优化组件**，在系统首次登录进入桌面后接管整个部署流程，完成包括但不限于：

- 🛠️ 注册表 / 电源 / 服务优化
- 🚗 万能驱动安装
- 👤 用户名、计算机名、密码、RDP 端口配置
- 🌐 网络（IP / DNS / WiFi）配置
- 🛡️ Windows Defender 处理
- 📦 运行库（DirectX / VC++ / .NET）安装
- 📊 Office 自动安装与 KMS 激活
- 🎨 主题、壁纸恢复
- 🔄 Windows Update 策略

---

## 🚀 使用方式

直接运行 `osc.exe` 即可，无需依赖系统镜像版本。

也可通过部署 API 在各阶段调用：

```cmd
api.bat /1    REM 部署前
api.bat /2    REM 部署中
api.bat /3    REM 部署后
api.bat /4    REM 登录时
api.bat /5    REM 清理 / 最终化
```

行为通过 `%SystemDrive%\Windows\Setup\` 下的标记文件控制（如 `xrsyspasswd.txt`、`xrsyspcname.txt`、`xrsysrdp.txt` 等）。

详细配置请参考原项目文档：[📄 sys.xrgzs.top/diy/osc/](https://sys.xrgzs.top/diy/osc/)

---

## ⚠️ 注意事项

- 使用前请**备份浏览器中的重要数据**，OSC 会自动清理浏览器数据。
- 仅适用于 Windows 7 / 8 / 8.1 / 10 / 11。
- 需要管理员权限运行。

---

## 🏗️ 构建

CI 自动构建产物为 NSIS 打包的 `osc.exe`，版本号格式为 `YY.M.D.HHmm`（中国标准时间自动生成）。

本地构建：
```powershell
.\build.ps1
```

依赖：
- NSIS（`choco install nsis -y`）
- PowerShell 7+

---

## 🙏 致谢

### 上游项目

- **[xrgzs/xrsys-osc](https://github.com/xrgzs/xrsys-osc)** —— 本项目 Fork 来源，所有核心架构与逻辑均来自原项目

### 使用到的开源项目

- [7-zip](https://7-zip.org/)
- [NSIS](https://nsis.sourceforge.io/)
- [dmidecode](http://savannah.nongnu.org/projects/dmidecode/)
- [nircmd](https://www.nirsoft.net/utils/nircmd.html)
- [PECMD](http://wuyou.net/forum.php?mod=viewthread&tid=205402)
- [Wbox / Winput](https://www.horstmuc.de/w32dial.htm)
- [Curl](https://curl.se/)
- [M2TeamArchived/NSudo](https://github.com/M2TeamArchived/NSudo)
- [Windows Update Blocker](https://www.sordum.org/9470)
- [stdin82/htfx](https://github.com/stdin82/htfx)
- [abbodi1406/KMS_VL_ALL_AIO](https://github.com/abbodi1406/KMS_VL_ALL_AIO)
- [zbezj/HEU_KMS_Activator](https://github.com/zbezj/HEU_KMS_Activator)
- [Wind4/vlmcsd](https://github.com/Wind4/vlmcsd)
- [q3aql/aria2-static-builds](https://gitlab.com/q3aql/aria2-static-builds)

> 🌄 图标来自：[icons8.com/icons/fluency](https://icons8.com/icons/fluency)

---

## 📜 许可

遵循上游项目的开源许可（见 [LICENSE](./LICENSE)）。
