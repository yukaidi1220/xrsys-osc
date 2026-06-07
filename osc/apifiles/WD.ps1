$ErrorActionPreference = 'Stop'

# 尝试获取 Windows Defender 首选项（验证 Defender 服务是否可用）
Get-MpPreference

# 后续操作如果出错不终止（部分设置可能因权限或策略原因失败）
$ErrorActionPreference = 'SilentlyContinue'

# 添加排除路径（Windows Defender 不会扫描这些目录）
Add-MpPreference -ExclusionPath 'C:\Windows\Setup\Set\*'            # 系统安装脚本目录
Add-MpPreference -ExclusionPath 'C:\Program Files\EEEOS\*'        # 软件目录（64 位）
Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\EEEOS\*'  # 软件目录（32 位）
# 设置 Defender 扫描时 CPU 使用优先级为低（减少对前台应用的影响）
Set-MpPreference -EnableLowCpuPriority $true
# 仅在 CPU 空闲时才执行定时扫描（避免拖慢系统响应）
Set-MpPreference -ScanOnlyIfIdleEnabled $true
# 设置 CPU 平均使用率上限（范围 5~100，建议小于 10，此为平均值而非严格限制）
Set-MpPreference -ScanAvgCPULoadFactor 6
# 关闭快速扫描的追加扫描（延迟扫描补上之前错过的扫描）
Set-MpPreference -DisableCatchupQuickScan $true
# 关闭全部扫描的追加扫描
Set-MpPreference -DisableCatchupFullScan $true
# 暂时关闭实时防护（降低后台资源占用，需手动重新开启）
Set-MpPreference -DisableRealtimeMonitoring $true