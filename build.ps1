# 要求 PowerShell 7 或更高版本运行
#Requires -Version 7
# 遇到错误时立即终止脚本（严格模式）
$ErrorActionPreference = 'Stop'

# 切换到当前目录
Set-Location $PSScriptRoot

# 下载文件

# 验证文件哈希值是否匹配（通用函数）
# 参数: $Hashes - 文件路径与期望哈希值的哈希表; $Algorithm - 哈希算法名称
function Test-Hashes {
    param (
        [hashtable]$Hashes,
        [string]$Algorithm
    )
    return $Hashes.GetEnumerator() | ForEach-Object {
        $file = $_.Key            # 当前文件路径
        $expectedHash = $_.Value  # 期望的哈希值
        Write-Host -ForegroundColor Blue "正在验证 $file 的 $Algorithm 哈希值..."
        Write-Host -ForegroundColor Gray "期望值: $expectedHash"
        # 计算文件的实际哈希值
        $actualHash = (Get-FileHash -Path $file -Algorithm $Algorithm).Hash
        Write-Host -ForegroundColor Gray "实际值: $actualHash"
        if ($actualHash -ne $expectedHash) {
            # return $false
            Write-Error "$file 哈希值不匹配。"
        }
        else {
            Write-Host -ForegroundColor Green "$file 哈希值匹配。"
        }
    }
}
# SHA256 哈希验证的便捷封装
function Test-SHA256 ([hashtable]$Hashes) { return Test-Hashes -Hashes $Hashes -Algorithm "SHA256" }

# 带重试机制的 HTTP 文件下载函数（最多重试 3 次）
function Invoke-RobustRequest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,       # 下载链接
        [Parameter(Mandatory = $true)]
        [string]$OutFile    # 保存路径
    )
    # 校验 URL 非空
    if ([string]::IsNullOrWhiteSpace($Uri)) {
        throw "URL 不能为空！输出文件: $OutFile"
    }

    # 最多重试 3 次
    for ($retry = 1; $retry -le 3; $retry++) {
        try {
            # 发起 HTTP 请求，超时 5 秒，允许不安全重定向
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -ConnectionTimeoutSeconds 5 -AllowInsecureRedirect
            return
        }
        catch {
            if ($retry -eq 3) {
                throw "重试 3 次后失败！URL: '$Uri', 错误: $_"
            }
            Write-Host "'$Uri' 第 $retry 次重试失败，正在重试 ($retry / 3)... 错误: $_"
            Start-Sleep -Seconds 2
        }
    }
}

# 从蓝奏云网盘下载文件（带多源解析回退）
# 优先使用 api.xrgzs.top，失败后回退到 lz.qaiu.top
function Get-LanzouFile {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Uri,       # 蓝奏云分享链接

        [Parameter(Mandatory = $true, Position = 1)]
        [string]
        $OutFile    # 保存路径
    )

    Write-Host "正在下载 $Uri 到 $OutFile..."
    try {
        # 主解析源: api.xrgzs.top
        Write-Host "正在使用 api.xrgzs.top 解析链接..."
        Invoke-RobustRequest -Uri "https://api.xrgzs.top/sdlp/lanzou/?type=down&url=$Uri" -OutFile $OutFile
    }
    catch {
        try {
            # 备用解析源: lz.qaiu.top
            Write-Host "正在使用 lz.qaiu.top 解析链接..."
            Invoke-RobustRequest -Uri "https://lz.qaiu.top/parser?url=$Uri" -OutFile $OutFile
        }
        catch {
            Write-Error "下载 $Uri 失败。($_)"
        }
    }
}

# 检查 NSIS 安装路径
# 优先使用环境变量 NSISDIR，其次尝试默认安装路径
if (Test-Path "$env:NSISDIR\makensis.exe") {
    $nsisDir = "$env:NSISDIR"
}
elseif (Test-Path "C:\Program Files (x86)\NSIS\makensis.exe") {
    $nsisDir = "C:\Program Files (x86)\NSIS"
}
else {
    Write-Host "未找到 NSIS！"
    exit 1
}
# 输出构建环境信息
Write-Host "版本号: $env:GITHUB_WORKFLOW_VERSION"
Write-Host "NSIS 目录: $nsisDir"
if (Test-Path 'osc\xrsoft.exe') {
    Write-Host "xrsoft.exe 已存在。"
}
else {
    # 下载所需文件（KMS 激活工具、HEU 激活工具、主程序、TSforge 激活脚本）
    # Get-LanzouFile -Uri "https://xrgzs.lanzoum.com/iy02F3ppu8mj" -OutFile "osc\xrkms\KMS_VL_ALL_AIO.cmd"
    Invoke-RobustRequest -Uri "https://nos.netease.com/ysf/3380523d9ee1fbc12a84e5a5b7994890.cmd" -OutFile "osc\xrkms\KMS_VL_ALL_AIO.cmd"
    # Get-LanzouFile -Uri "https://xrgzs.lanzoum.com/iDhqm3ppuagf" -OutFile "osc\xrkms\HEU.exe"
    Invoke-RobustRequest -Uri "https://nos.netease.com/ysf/11c1b3885cf104fa5bef53d571e5156d.exe" -OutFile "osc\xrkms\HEU.exe"
    # Get-LanzouFile -Uri "https://xrgzs.lanzouv.com/iqnTr2wxjufc" -OutFile "osc\xrsoft.exe"
    Invoke-RobustRequest -Uri "https://nos.netease.com/ysf/e68b8f58127b7680debf16b120cad91a.exe" -OutFile "osc\xrsoft.exe"
    Invoke-RobustRequest -Uri "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/refs/heads/master/MAS/Separate-Files-Version/Activators/TSforge_Activation.cmd" -OutFile "osc\xrkms\TSforge_Activation.cmd"

    # 下载其他文件（在线配置和软件列表）
    Invoke-RobustRequest -Uri "https://url.xrgzs.top/osconline" -OutFile "osc\oscoffline.bat" -ErrorAction Stop
    Invoke-RobustRequest -Uri "https://url.xrgzs.top/oscsoft" -OutFile "osc\oscsoftof.txt" -ErrorAction Stop
}

# 验证已下载文件的 SHA256 哈希值，确保文件完整且未被篡改
Test-SHA256 -Hashes @{
    "osc\xrkms\KMS_VL_ALL_AIO.cmd" = "CEE80B2DE0CA33BE709C33E6725E81D28FC366565211B4E1D996951512AA0049"
    "osc\xrkms\HEU.exe"            = "DBE10240FC4841A60410DF3EE1704487F43A8E19158AEA99DDD8EA214BAB23B6"
    "osc\xrsoft.exe"               = "9C863AE73272D7470D0BC48CB1E70D5B3172FEDF532CB14ECE502718726A220E"
}

# 构建阶段：使用 NSIS 编译安装包
# 如果未设置版本号环境变量，则使用默认版本号
if (-not $env:GITHUB_WORKFLOW_VERSION) {
    $env:GITHUB_WORKFLOW_VERSION = "2.5.0.0"
}
# 将版本号写入版本文件
Set-Content -Path "osc\apifiles\Version.txt" -Value $env:GITHUB_WORKFLOW_VERSION
# 调用 NSIS 编译器，详细级别 4，传入自定义版本号
& "$nsisDir\makensis.exe" /V4 /DCUSTOM_VERSION=$env:GITHUB_WORKFLOW_VERSION "osc.nsi" || exit 1

# 输出构建产物的版本号和校验信息
$env:GITHUB_WORKFLOW_VERSION | Out-File -FilePath "osc.exe.ver"
(Get-FileHash -Path "osc.exe" -Algorithm SHA256).Hash | Out-File -FilePath "osc.exe.sha256"
(Get-FileHash -Path "osc.exe" -Algorithm MD5).Hash | Out-File -FilePath "osc.exe.md5"
