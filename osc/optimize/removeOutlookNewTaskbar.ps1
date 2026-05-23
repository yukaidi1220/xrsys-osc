param(
    [string]$StartsWith = "Outlook",
    [int]$TimeoutSeconds = 5
)

# ===============================================
# Common
# ===============================================

function Wait-Until {
    param(
        [scriptblock]$Condition,
        [int]$TimeoutSeconds = 5,
        [int]$IntervalMs = 100
    )

    $deadline = [DateTime]::Now.AddSeconds($TimeoutSeconds)

    while ([DateTime]::Now -lt $deadline) {

        try {
            $result = & $Condition

            if ($result) {
                return $result
            }
        }
        catch {}

        Start-Sleep -Milliseconds $IntervalMs
    }

    return $null
}

# ===============================================
# Try COM Method
# ===============================================

function Invoke-UnpinTaskbarCOM {
    param(
        [string]$StartsWith
    )

    Write-Host "[COM] Trying Shell.Application..."

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

    public static string GetString(uint strId)
    {
        IntPtr intPtr = GetModuleHandle("shell32.dll");

        StringBuilder sb = new StringBuilder(255);

        LoadString(intPtr, strId, sb, sb.Capacity);

        return sb.ToString();
    }
}
"@

    # 5387 = "Unpin from taskbar"
    $localizedString = [DllCaller]::GetString(5387)

    Write-Host "[COM] Verb => $localizedString"

    $items = (
        New-Object -ComObject Shell.Application
    ).NameSpace(
        "shell:::{4234d49b-0245-4df3-b780-3893943456e1}"
    ).Items()

    foreach ($item in $items) {

        if ($item.Name -notlike "$StartsWith*") {
            continue
        }

        Write-Host "[COM] Found => $($item.Name)"

        foreach ($verb in $item.Verbs()) {

            $verbName = $verb.Name.Replace("&", "").Trim()

            Write-Host "[COM] Verb => $verbName"

            if ($verbName -eq $localizedString) {

                Write-Host "[COM] Invoke verb"

                $verb.DoIt()

                return $true
            }
        }
    }

    return $false
}

# ===============================================
# UIAutomation
# ===============================================

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {

    [DllImport("user32.dll")]
    public static extern void keybd_event(
        byte bVk,
        byte bScan,
        uint dwFlags,
        UIntPtr dwExtraInfo
    );

    public const int KEYEVENTF_KEYUP = 0x0002;

    public const byte VK_APPS = 0x5D;
}
"@

function press_key {
    param([byte]$Key)

    [Win32]::keybd_event(
        $Key,
        0,
        0,
        [UIntPtr]::Zero
    )

    Start-Sleep -Milliseconds 30

    [Win32]::keybd_event(
        $Key,
        0,
        [Win32]::KEYEVENTF_KEYUP,
        [UIntPtr]::Zero
    )
}

function Find-TaskbarButton {
    param(
        [string]$StartsWith
    )

    $root = [System.Windows.Automation.AutomationElement]::RootElement

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

    $buttons = $taskbar.FindAll(
        [System.Windows.Automation.TreeScope]::Descendants,
        (
            New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
                [System.Windows.Automation.ControlType]::Button
            )
        )
    )

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

function Invoke-UnpinTaskbarUIA {
    param(
        [string]$StartsWith,
        [int]$TimeoutSeconds
    )

    Write-Host "[UIA] Searching taskbar button..."

    $target = Find-TaskbarButton -StartsWith $StartsWith

    if (-not $target) {
        Write-Host "[UIA] Target not found"
        return $false
    }

    Write-Host "[UIA] Found => $($target.Current.Name)"

    try {
        $target.SetFocus()
    }
    catch {
        Write-Host "[UIA] SetFocus failed"
        return $false
    }

    press_key ([Win32]::VK_APPS)

    $focused = Wait-Until `
        -TimeoutSeconds $TimeoutSeconds `
        -Condition {

        try {
            $f = [System.Windows.Automation.AutomationElement]::FocusedElement

            if (-not $f) {
                return $null
            }

            $name = $f.Current.Name

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
        Write-Host "[UIA] Unpin menu not found"
        return $false
    }

    Write-Host "[UIA] Focused => $($focused.Current.Name)"

    # InvokePattern
    try {

        $invoke = $focused.GetCurrentPattern(
            [System.Windows.Automation.InvokePattern]::Pattern
        )

        $invoke.Invoke()

        Write-Host "[UIA] Invoke success"

        return $true

    }
    catch {}

    # SelectionItemPattern
    try {

        $sel = $focused.GetCurrentPattern(
            [System.Windows.Automation.SelectionItemPattern]::Pattern
        )

        $sel.Select()

        Write-Host "[UIA] Selection success"

        return $true

    }
    catch {}

    Write-Host "[UIA] Invoke failed"

    return $false
}

# ===============================================
# Main
# ===============================================

if (
    Invoke-UnpinTaskbarCOM `
        -StartsWith $StartsWith
) {
    Write-Host "[OK] COM success"
    exit
}

Write-Host "[Fallback] Switching to UIAutomation..."

if (
    Invoke-UnpinTaskbarUIA `
        -StartsWith $StartsWith `
        -TimeoutSeconds $TimeoutSeconds
) {
    Write-Host "[OK] UIAutomation success"
    exit
}

Write-Host "[FAIL] Unpin failed"
exit 1