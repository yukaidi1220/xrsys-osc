
# 从计算机中为所有用户卸载应用包
# Remove-AppxProvisionedPackage cmdlet 从 Windows 映像中移除应用包（.appx）。
# 新建用户帐户时不会安装这些应用包。
# 不会从现有用户帐户中移除这些包。
# 如需移除未预配的应用包（.appx）或仅针对特定用户移除包，请改用 Remove-AppxPackage。

# 逐个移除预配的应用包（从系统映像中删除，新用户不再安装）
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Clipchamp*”} | Remove-AppxProvisionedPackage -Online           # Clipchamp 视频编辑器
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.549981C3F5F10*”} | Remove-AppxProvisionedPackage -Online  # Cortana 语音助手
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.BingNews*”} | Remove-AppxProvisionedPackage -Online     # 必应新闻
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.BingWeather*”} | Remove-AppxProvisionedPackage -Online  # 必应天气
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.GetHelp*”} | Remove-AppxProvisionedPackage -Online      # 获取帮助
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.Getstarted*”} | Remove-AppxProvisionedPackage -Online   # 使用技巧（入门指南）
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.Microsoft3DViewer*”} | Remove-AppxProvisionedPackage -Online  # 3D 查看器
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.MicrosoftPCManager*”} | Remove-AppxProvisionedPackage -Online  # 微软电脑管家
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.MicrosoftTeams*”} | Remove-AppxProvisionedPackage -Online  # Microsoft Teams（旧版）
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.MixedReality.Portal*”} | Remove-AppxProvisionedPackage -Online  # Mixed Reality 混合现实门户
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.Office.OneNote*”} | Remove-AppxProvisionedPackage -Online  # OneNote 笔记
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.OneConnect*”} | Remove-AppxProvisionedPackage -Online    # 网络连接（已弃用）
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.OutlookForWindows*”} | Remove-AppxProvisionedPackage -Online  # 新版 Outlook
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.People*”} | Remove-AppxProvisionedPackage -Online        # 人脉（联系人）
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.PowerAutomateDesktop*”} | Remove-AppxProvisionedPackage -Online  # Power Automate 桌面版
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.Print3D*”} | Remove-AppxProvisionedPackage -Online       # Print 3D 打印
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.SkypeApp*”} | Remove-AppxProvisionedPackage -Online       # Skype 通讯
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.Todos*”} | Remove-AppxProvisionedPackage -Online         # 待办事项
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.WindowsMaps*”} | Remove-AppxProvisionedPackage -Online   # Windows 地图
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.XboxApp*”} | Remove-AppxProvisionedPackage -Online       # Xbox 应用
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.Wallet*”} | Remove-AppxProvisionedPackage -Online         # 钱包（支付）
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*MicrosoftCorporationII.MicrosoftFamily*”} | Remove-AppxProvisionedPackage -Online  # 微软家庭安全
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.MSTeams*”} | Remove-AppxProvisionedPackage -Online       # Microsoft Teams（新版）
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*MicrosoftWindows.Client.WebExperience*”} | Remove-AppxProvisionedPackage -Online  # Widgets 小组件
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.WidgetsPlatformRuntime*”} | Remove-AppxProvisionedPackage -Online  # 小组件平台运行时
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.Windows.DevHome*”} | Remove-AppxProvisionedPackage -Online  # Dev Home 开发者主页
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.windowscommunicationsapps*”} | Remove-AppxProvisionedPackage -Online  # 邮件和日历
Get-AppxProvisionedPackage -Online | Where-Object {$_.packagename -like “*Microsoft.Edge.GameAssist*”} | Remove-AppxProvisionedPackage -Online  # Edge 游戏辅助

# 为当前用户卸载应用包（从所有已登录用户帐户中移除）
# Remove-AppxPackage cmdlet 从用户帐户中移除应用包。

Get-AppxPackage *Clipchamp* -AllUsers | Remove-AppxPackage                        # Clipchamp 视频编辑器
Get-AppxPackage *Microsoft.549981C3F5F10* -AllUsers | Remove-AppxPackage           # Cortana 语音助手
Get-AppxPackage *Microsoft.BingNews* -AllUsers | Remove-AppxPackage                # 必应新闻
Get-AppxPackage *Microsoft.GetHelp* -AllUsers | Remove-AppxPackage                 # 获取帮助
Get-AppxPackage *Microsoft.Getstarted* -AllUsers | Remove-AppxPackage              # 使用技巧（入门指南）
Get-AppxPackage *Microsoft.Microsoft3DViewer* -AllUsers | Remove-AppxPackage       # 3D 查看器
Get-AppxPackage *Microsoft.MicrosoftPCManager* -AllUsers | Remove-AppxPackage      # 微软电脑管家
Get-AppxPackage *Microsoft.MicrosoftTeams* -AllUsers | Remove-AppxPackage          # Microsoft Teams（旧版）
Get-AppxPackage *Microsoft.MixedReality.Portal* -AllUsers | Remove-AppxPackage     # Mixed Reality 混合现实门户
Get-AppxPackage *Microsoft.Office.OneNote* -AllUsers | Remove-AppxPackage          # OneNote 笔记
Get-AppxPackage *Microsoft.OneConnect* -AllUsers | Remove-AppxPackage              # 网络连接（已弃用）
Get-AppxPackage *Microsoft.People* -AllUsers | Remove-AppxPackage                  # 人脉（联系人）
Get-AppxPackage *Microsoft.PowerAutomateDesktop* -AllUsers | Remove-AppxPackage    # Power Automate 桌面版
Get-AppxPackage *Microsoft.Print3D* -AllUsers | Remove-AppxPackage                 # Print 3D 打印
Get-AppxPackage *Microsoft.SkypeApp* -AllUsers | Remove-AppxPackage                # Skype 通讯
Get-AppxPackage *Microsoft.Todos* -AllUsers | Remove-AppxPackage                   # 待办事项
Get-AppxPackage *Microsoft.WindowsMaps* -AllUsers | Remove-AppxPackage             # Windows 地图
Get-AppxPackage *Microsoft.XboxApp* -AllUsers | Remove-AppxPackage                 # Xbox 应用
Get-AppxPackage *Microsoft.Wallet* -AllUsers | Remove-AppxPackage                  # 钱包（支付）
Get-AppxPackage *MicrosoftCorporationII.MicrosoftFamily* -AllUsers | Remove-AppxPackage  # 微软家庭安全
Get-AppxPackage *MicrosoftTeams* -AllUsers | Remove-AppxPackage                    # Microsoft Teams（新版，包名变体1）
Get-AppxPackage *MSTeams* -AllUsers | Remove-AppxPackage                           # Microsoft Teams（新版，包名变体2）
Get-AppxPackage *Microsoft.OutlookForWindows* -AllUsers | Remove-AppxPackage       # 新版 Outlook
Get-AppxPackage *MicrosoftWindows.Client.WebExperience* -AllUsers | Remove-AppxPackage  # Widgets 小组件
Get-AppxPackage *Microsoft.WidgetsPlatformRuntime* -AllUsers | Remove-AppxPackage  # 小组件平台运行时
Get-AppxPackage *Microsoft.Windows.DevHome* -AllUsers | Remove-AppxPackage         # Dev Home 开发者主页
Get-AppxPackage *Microsoft.BingWeather* -AllUsers | Remove-AppxPackage             # 必应天气
Get-AppxPackage *Microsoft.windowscommunicationsapps* -AllUsers | Remove-AppxPackage  # 邮件和日历
Get-AppxPackage *Microsoft.Edge.GameAssist* -AllUsers | Remove-AppxPackage         # Edge 游戏辅助
Get-AppxPackage *Microsoft.MicrosoftOfficeHub* -AllUsers | Remove-AppxPackage      # Microsoft 365 Copilot
Get-AppxPackage *Microsoft.Copilot* -AllUsers | Remove-AppxPackage                 # Copilot 助手
Get-AppxPackage *Microsoft.StartExperiencesApp* -AllUsers | Remove-AppxPackage     # “开始体验”应用
Get-AppxPackage *Microsoft.BingSearch* -AllUsers | Remove-AppxPackage              # 必应搜索
# 以下为已注释掉的可选卸载项（按需取消注释）
# Get-AppxPackage *Microsoft.GamingApp* -AllUsers | Remove-AppxPackage             # Xbox Game Bar 游戏栏
# Get-AppxPackage *Microsoft.MicrosoftSolitaireCollection* -AllUsers | Remove-AppxPackage  # 纸牌合集
# Get-AppxPackage *Microsoft.MicrosoftStickyNotes* -AllUsers | Remove-AppxPackage  # 便笺
# Get-AppxPackage *Microsoft.Todos* -AllUsers | Remove-AppxPackage                 # 待办事项（重复项）
# Get-AppxPackage *Microsoft.WindowsFeedbackHub* -AllUsers | Remove-AppxPackage    # 反馈中心
# Get-AppxPackage *Microsoft.Xbox* -AllUsers | Remove-AppxPackage                  # Xbox 核心服务
# Get-AppxPackage *Microsoft.YourPhone* -AllUsers | Remove-AppxPackage             # 手机连接
# Get-AppxPackage *MicrosoftCorporationII.QuickAssist* -AllUsers | Remove-AppxPackage  # 快速助手

# 导入注册表以禁用微软电脑管家（32 位注册表路径）
reg.exe import .\mspcmgr.reg /reg:32
