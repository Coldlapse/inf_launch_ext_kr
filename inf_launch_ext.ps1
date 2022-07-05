# INFINITAS??É¨?∏„Çπ?à„É™ ?§„É≥?π„Éà?º„É´?à„ÅÆ?ñÂæó?´‰Ωø??
$InfRegistry = "HKLM:\SOFTWARE\KONAMI\beatmania IIDX INFINITAS"

# ?≤„Éº?†Êú¨‰Ωì„ÅÆ?ë„Çπ ?öÂ∏∏??É¨?∏„Çπ?à„É™?ã„Çâ?ñÂæó
#$InfPath = "C:\Games\beatmania IIDX INFINITAS\"
$InfPath = Get-ItemPropertyValue -LiteralPath $InfRegistry -Name "InstallDir"
$InfExe = Join-Path $InfPath "\game\app\bm2dx.exe"
$InfLauncher = Join-Path $InfPath "\launcher\modules\bm2dx_launcher.exe"
cd $InfPath | Out-Null

# bm2dxinf:// ??É¨?∏„Çπ?à„É™
$InfOpen = "HKCR:bm2dx-kr\shell\open\command\"

# ?ì„ÅÆ?π„ÇØ?™„Éó?à„ÅÆ?ï„É´?ë„Çπ
$ScriptPath = $MyInvocation.MyCommand.Path

# Ë®?Æö?ï„Ç°?§„É´
$ConfigJson = Join-Path $PSScriptRoot "config.json"

$Config = @{
    "Option"="0"
    "WindowWidth"="1280"
    "WindowHeight"="720"
    "WindowPositionX"="0"
    "WindowPositionY"="0"
    "Borderless"=$false
}

# ?¶„Ç£?≥„Éâ?¶„Çπ?ø„Ç§?´ÔºàË™ø„Åπ?¶„ÇÇ?à„Åè?è„Åã?ì„Å™?ã„Å£?üÔºâ
$WSDefault = 348651520
$WSBorderless = 335544320

# Win32API?¢Êï∞??ÆöÁæ?
Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class Win32Api {
        [DllImport("user32.dll")]
        public static extern int MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

        [DllImport("user32.dll")]
        public static extern int SetWindowLong(IntPtr hWnd, int nIndex, long dwLong);

        [DllImport("user32.dll")]
        public static extern long GetWindowLong(IntPtr hWnd, int nIndex);

        [DllImport("user32.dll")]
        internal static extern bool GetWindowRect(IntPtr hwnd, out RECT lpRect);

        [DllImport("user32.dll")]
        internal static extern bool GetClientRect(IntPtr hwnd, out RECT lpRect);

        [StructLayout(LayoutKind.Sequential)]
		internal struct RECT
		{
			public int left, top, right, bottom;
        }
        
        // Â§ñÊû†??§ß?ç„Åï?íËÄÉÊÖÆ?ó„Åü?¶„Ç£?≥„Éâ?¶„Çµ?§„Ç∫Â§âÊõ¥
        public static void MoveWindow2(IntPtr hndl, int x, int y, int w, int h, bool isBl){
            if(isBl){
                MoveWindow(hndl, x, y, w, h, true);
            }else{
                RECT cRect = new RECT();
                RECT wRect = new RECT();

                GetClientRect(hndl, out cRect);
                GetWindowRect(hndl, out wRect);

                int cWidth = cRect.right - cRect.left;
                int cHeight = cRect.bottom - cRect.top;

                int wWidth = wRect.right - wRect.left;
                int wHeight = wRect.bottom - wRect.top;

                int newW = w + (wWidth - cWidth);
                int newH = h + (wHeight - cHeight);

                MoveWindow(hndl, x, y, newW, newH, true);
            }

        }
        
    }
"@

function Save-Config() {
    $Config | ConvertTo-Json | Out-File -FilePath $ConfigJson -Encoding utf8
}

function Start-Exe($exe, $workDir, $arg){
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $exe
    $info.WorkingDirectory = $workDir
    $info.Arguments = $arg
    $info.UseShellExecute = $false

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $info
    
    $p.Start() | Out-Null

    return $p
}

function Switch-Borderless($isBl){
    if ($isBl) {
        [Win32Api]::SetWindowLong($handle, -16, $WSBorderless) | Out-Null
    }else{
        [Win32Api]::SetWindowLong($handle, -16, $WSDefault) | Out-Null
    }
}


# ÂºïÊï∞?íÊåáÂÆö„Åó?™„Åã?£„Åü?®„Åç?´„É¨?∏„Çπ?à„É™Â§âÊõ¥
if ([string]::IsNullOrEmpty($Args[0])) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    $val = Get-ItemPropertyValue -LiteralPath $InfOpen -Name "(default)"

    echo("currently command: " + $val)
    echo ""
    echo("script path: " + $ScriptPath)
    echo("game path: " + $InfPath)
    echo ""
    
    echo "0 : revert to default"
    echo "1 : set to this script path"
    echo "3 : copy script file to game directory and set to new script path (recommended)"
    $num = Read-Host "number->"

    switch ($num) {
        0 {
            $val = """${InfLauncher}"" ""%1"""
        }
        1 {
            $val = """powershell"" ""-file"" ""${ScriptPath}"" ""%1"""
        }
        3 {
            $NewScriptPath = Join-Path $InfPath "inf_launch_ext.ps1"
            Copy-Item $ScriptPath $NewScriptPath
            $val = """powershell"" ""-file"" ""${NewScriptPath}"" ""%1"""
        }
        Default {
            exit
        }
    }
    Set-ItemProperty $InfOpen -name "(default)" -value $val
    echo "done. Press enter key to exit."
    Read-Host
    exit
}

# ?≤„Éº?†„ÇíËµ∑Âãï?ô„Çã?ü„ÇÅ??ÇÇ??ÄÄ?ì„Åì?ã„Çâ
# Ë®?Æö?ï„Ç°?§„É´?íË™≠?øËæº?Ä
if(Test-Path $ConfigJson){
    $Config = @{}
(ConvertFrom-Json (Get-Content $ConfigJson -Encoding utf8 -Raw )).psobject.properties | Foreach { $Config[$_.Name] = $_.Value }
}


# ?≤„Éº?†Êú¨‰Ωì„Å´Ê∏°„ÅôÂºïÊï∞
$InfArgs = ""

# ÂºïÊï∞?ã„Çâ?à„Éº??É≥?íÊãæ??
$Args[0] -match "tk=(.{64})" | Out-Null
$InfArgs += " -t "+$Matches[1]

# ?à„É©?§„Ç¢?´„É¢?º„Éâ?™„Çâ--trial?í„Å§?ë„Çã
if ($Args[0].Contains("trial")) {
    $InfArgs += " --trial"
}

echo "Please select option."
echo "0 : Launcher"
echo "1 : Normal"
echo "2 : Normal + window mode"
echo "3 : ASIO"
echo "4 : ASIO + window mode"

$num = Read-Host "number(last time: $($Config["Option"]))"
if([string]::IsNullOrEmpty($num)){
    $num=$Config["Option"]
}

switch ($num) {
    0 {
        Start-Process -FilePath $InfLauncher -ArgumentList $Args[0]
        exit
    }
    1 {
        $InfArgs += " --kr"
    }
    2 {
        $InfArgs += " -w"
        $InfArgs += " --kr"
    }
    3 {
        $InfArgs += " --asio"
        $InfArgs += " --kr"
    }
    4 {
        $InfArgs += " -w"
        $InfArgs += " --asio"
        $InfArgs += " --kr"
    }
    Default {
        exit
    }
}

# Ë®?Æö?í‰øùÂ≠?
$Config["Option"] = [string]$num
Save-Config

# INFINITAS?íËµ∑??
$p = Start-Exe($InfExe,"",""""+$InfArgs+"""")

# ?¶„Ç£?≥„Éâ?¶„É¢?º„Éâ??Å®??
if($InfArgs.Contains("-w")){
    # ?¶„Ç£?≥„Éâ?¶‰Ωú?ê„Åæ?ßÂæÖ??
    $p.WaitForInputIdle() | Out-Null

    # ?¶„Ç£?≥„Éâ?¶„Éè?≥„Éâ?´„ÅÆ?ñÂæó
    $handle = $p.MainWindowHandle

    # ?çÂõû??ΩçÁΩ?Å®Â§ß„Åç?ï„Å´?ô„Çã
    Switch-Borderless($Config["Borderless"])
    [Win32Api]::MoveWindow2($handle, $Config["WindowPositionX"], $Config["WindowPositionY"], $Config["WindowWidth"], $Config["WindowHeight"], $Config["Borderless"])

    echo ""
    echo "window mode setting"
    echo "example:"
    echo "window size -> 1280x720"
    echo "window position -> 100,100"
    echo "Press enter key to switch to Borderless window."

    while($true){
        $inputStr=Read-Host " "
        if([string]::IsNullOrEmpty($inputStr)){
            $Config["Borderless"] = (-Not $Config["Borderless"])
        }elseif($inputStr.Contains("x")){
            $val = $inputStr.Split('x')
            $Config["WindowWidth"]=$val[0]
            $Config["WindowHeight"]=$val[1]
        }elseif($inputStr.Contains(",")){
            $val = $inputStr.Split(',')
            $Config["WindowPositionX"]=$val[0]
            $Config["WindowPositionY"]=$val[1]
        }

        # ?ú„Éº?Ä?º„É¨?πÂåñ
        Switch-Borderless($Config["Borderless"])

        # ‰ΩçÁΩÆ?®„Çµ?§„Ç∫?íÂèç??
        [Win32Api]::MoveWindow2($handle, $Config["WindowPositionX"], $Config["WindowPositionY"], $Config["WindowWidth"], $Config["WindowHeight"], $Config["Borderless"])

        # Ë®?Æö?ï„Ç°?§„É´?´Êõ∏?çËæº?Ä
        Save-Config
    }
}




