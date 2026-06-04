# 脚本参数: $StartsWith - 要取消固定的应用名称前缀（默认 "Outlook"）; $TimeoutSeconds - 操作超时秒数（默认 5 秒）
param(
    [string]$StartsWith = "Outlook",
    [int]$TimeoutSeconds = 5
)

# ===============================================
# 公共函数
# ===============================================

# 等待直到条件满足或超时的通用轮询函数
# 参数: $Condition - 要求值的脚本块; $TimeoutSeconds - 超时秒数; $IntervalMs - 轮询间隔毫秒数
function Wait-Until {
    param(
        [scriptblock]$Condition,
        [int]$TimeoutSeconds = 5,
        [int]$IntervalMs = 100
    )

    # 计算截止时间
    $deadline = [DateTime]::Now.AddSeconds($TimeoutSeconds)

    while ([DateTime]::Now -lt $deadline) {

        try {
            # 执行条件脚本块并获取结果
            $result = & $Condition

            if ($result) {
                return $result
            }
        }
        catch {}

        # 等待指定间隔后再次轮询
        Start-Sleep -Milliseconds $IntervalMs
    }

    # 超时返回 null
    return $null
}

# ===============================================
# 尝试 COM 方式
# ===============================================

# 通过 COM Shell.Application 接口取消任务栏固定
# 利用 Shell 命名空间遍历已固定的应用，找到目标后调用"取消固定"动词
function Invoke-UnpinTaskbarCOM {
    param(
        [string]$StartsWith   # 应用名称前缀
    )

    Write-Host "[COM] 正在尝试 Shell.Application..."

    # 定义 P/Invoke 方法，用于从 shell32.dll 读取本地化字符串资源
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class DllCaller {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    internal static extern int LoadString(
        IntPtr hInstance,
        uint uID,
        StringBuilder lpBuffer,
        int nBufferMax
    );

    // 从 shell32.dll 加载指定 ID 的字符串资源（用于获取本地化的"取消固定"文本）
    public static string GetString(uint strId)
    {
        IntPtr intPtr = GetModuleHandle("shell32.dll");

        StringBuilder sb = new StringBuilder(255);

        LoadString(intPtr, strId, sb, sb.Capacity);

        return sb.ToString();
    }
}
"@

    # 从 shell32.dll 获取本地化的"从任务栏取消固定"字符串（资源 ID 5387）
    $localizedString = [DllCaller]::GetString(5387)

    Write-Host "[COM] 动词 => $localizedString"

    # 打开 Shell 命名空间中的"开始菜单/任务栏固定项"文件夹
    # CLSID {4234d49b-0245-4df3-b780-3893943456e1} 对应所有已安装应用列表
    $items = (
        New-Object -ComObject Shell.Application
    ).NameSpace(
        "shell:::{4234d49b-0245-4df3-b780-3893943456e1}"
    ).Items()

    foreach ($item in $items) {

        # 跳过不匹配目标名称前缀的应用
        if ($item.Name -notlike "$StartsWith*") {
            continue
        }

        Write-Host "[COM] 找到 => $($item.Name)"

        # 遍历该应用的所有右键菜单动词
        foreach ($verb in $item.Verbs()) {

            # 移除快捷键标记 & 并去除首尾空格
            $verbName = $verb.Name.Replace("&", "").Trim()

            Write-Host "[COM] 动词 => $verbName"

            # 匹配到"取消固定"动词时执行
            if ($verbName -eq $localizedString) {

                Write-Host "[COM] 调用动词"

                $verb.DoIt()

                return $true
            }
        }
    }

    return $false
}

# ===============================================
# UI 自动化
# ===============================================

# 加载 .NET UI 自动化程序集（用于通过辅助功能树操控窗口控件）
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# 定义 Win32 键盘模拟函数和常量
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {

    // 模拟键盘按键事件（按下和释放）
    [DllImport("user32.dll")]
    public static extern void keybd_event(
        byte bVk,       // 虚拟键码
        byte bScan,     // 硬件扫描码
        uint dwFlags,   // 按键事件标志
        UIntPtr dwExtraInfo
    );

    // 键盘释放标志
    public const int KEYEVENTF_KEYUP = 0x0002;

    // 应用程序键（键盘上右侧 Win 键旁边的菜单键，键码 0x5D）
    public const byte VK_APPS = 0x5D;
}
"@

# 模拟按下并释放指定按键
function press_key {
    param([byte]$Key)   # 虚拟键码

    # 按下按键
    [Win32]::keybd_event(
        $Key,
        0,
        0,
        [UIntPtr]::Zero
    )

    # 等待 30 毫秒确保系统接收到按键事件
    Start-Sleep -Milliseconds 30

    # 释放按键
    [Win32]::keybd_event(
        $Key,
        0,
        [Win32]::KEYEVENTF_KEYUP,
        [UIntPtr]::Zero
    )
}

# 在任务栏中查找名称以指定前缀开头的按钮控件
function Find-TaskbarButton {
    param(
        [string]$StartsWith   # 按钮名称前缀
    )

    # 获取 UI 自动化根元素（桌面）
    $root = [System.Windows.Automation.AutomationElement]::RootElement

    # 查找任务栏窗口（类名 Shell_TrayWnd）
    $taskbar = $root.FindFirst(
        [System.Windows.Automation.TreeScope]::Descendants,
        (
            New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::ClassNameProperty,
                "Shell_TrayWnd"
            )
        )
    )

    if (-not $taskbar) {
        return $null
    }

    # 获取任务栏上所有按钮类型的控件
    $buttons = $taskbar.FindAll(
        [System.Windows.Automation.TreeScope]::Descendants,
        (
            New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
                [System.Windows.Automation.ControlType]::Button
            )
        )
    )

    # 遍历按钮，查找名称匹配的目标
    foreach ($btn in $buttons) {

        try {
            $name = $btn.Current.Name

            if (
                $name -and
                $name.StartsWith($StartsWith)
            ) {
                return $btn
            }

        }
        catch {}
    }

    return $null
}

# 通过 UI 自动化方式取消任务栏固定
# 流程: 查找按钮 → 设置焦点 → 模拟右键 → 等待上下文菜单 → 点击"取消固定"
function Invoke-UnpinTaskbarUIA {
    param(
        [string]$StartsWith,      # 应用名称前缀
        [int]$TimeoutSeconds      # 操作超时秒数
    )

    Write-Host "[UIA] 正在搜索任务栏按钮..."

    # 在任务栏中查找目标按钮
    $target = Find-TaskbarButton -StartsWith $StartsWith

    if (-not $target) {
        Write-Host "[UIA] 未找到目标"
        return $false
    }

    Write-Host "[UIA] 找到 => $($target.Current.Name)"

    # 将焦点设置到目标按钮上
    try {
        $target.SetFocus()
    }
    catch {
        Write-Host "[UIA] 设置焦点失败"
        return $false
    }

    # 模拟按下应用程序键（等同于右键点击）打开上下文菜单
    press_key ([Win32]::VK_APPS)

    # 轮询等待上下文菜单中出现"取消固定"选项（支持中文和英文系统）
    $focused = Wait-Until `
        -TimeoutSeconds $TimeoutSeconds `
        -Condition {

        try {
            # 获取当前获得焦点的 UI 元素
            $f = [System.Windows.Automation.AutomationElement]::FocusedElement

            if (-not $f) {
                return $null
            }

            $name = $f.Current.Name

            # 匹配"取消固定"（中文系统）或"Unpin"（英文系统）
            if (
                $name -match "取消固定" -or
                $name -match "Unpin"
            ) {
                return $f
            }

        }
        catch {}

        return $null
    }

    if (-not $focused) {
        Write-Host "[UIA] 未找到取消固定菜单"
        return $false
    }

    Write-Host "[UIA] 聚焦 => $($focused.Current.Name)"

    # 尝试方式1: 使用 InvokePattern 直接调用菜单项的点击操作
    try {

        $invoke = $focused.GetCurrentPattern(
            [System.Windows.Automation.InvokePattern]::Pattern
        )

        $invoke.Invoke()

        Write-Host "[UIA] 调用成功"

        return $true

    }
    catch {}

    # 尝试方式2: 使用 SelectionItemPattern 选择菜单项（某些控件不支持 Invoke）
    try {

        $sel = $focused.GetCurrentPattern(
            [System.Windows.Automation.SelectionItemPattern]::Pattern
        )

        $sel.Select()

        Write-Host "[UIA] 选择成功"

        return $true

    }
    catch {}

    Write-Host "[UIA] 调用失败"

    return $false
}

# ===============================================
# 主逻辑
# ===============================================

# 优先尝试 COM 方式（速度快、兼容性好）
if (
    Invoke-UnpinTaskbarCOM `
        -StartsWith $StartsWith
) {
    Write-Host "[成功] COM 方式成功"
    exit
}

# COM 方式失败时，回退到 UI 自动化方式（模拟键盘和鼠标操作）
Write-Host "[回退] 切换到 UI 自动化..."

if (
    Invoke-UnpinTaskbarUIA `
        -StartsWith $StartsWith `
        -TimeoutSeconds $TimeoutSeconds
) {
    Write-Host "[成功] UI 自动化成功"
    exit
}

# 两种方式均失败，返回错误码 1
Write-Host "[失败] 取消固定失败"
exit 1