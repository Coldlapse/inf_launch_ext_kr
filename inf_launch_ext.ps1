# INFINITAS??��?�ス?�リ ?�ン?�ト?�ル?�の?�得?�使??
$InfRegistry = "HKLM:\SOFTWARE\KONAMI\beatmania IIDX INFINITAS"

# ?�ー?�本体の?�ス ?�常??��?�ス?�リ?�ら?�得
#$InfPath = "C:\Games\beatmania IIDX INFINITAS\"
$InfPath = Get-ItemPropertyValue -LiteralPath $InfRegistry -Name "InstallDir"
$InfExe = Join-Path $InfPath "\game\app\bm2dx.exe"
$InfLauncher = Join-Path $InfPath "\launcher\modules\bm2dx_launcher.exe"
cd $InfPath | Out-Null

# bm2dxinf:// ??��?�ス?�リ
$InfOpen = "HKCR:bm2dx-kr\shell\open\command\"

# ?�の?�ク?�プ?�の?�ル?�ス
$ScriptPath = $MyInvocation.MyCommand.Path

# �?��?�ァ?�ル
$ConfigJson = Join-Path $PSScriptRoot "config.json"

$Config = @{
    "Option"="0"
    "WindowWidth"="1280"
    "WindowHeight"="720"
    "WindowPositionX"="0"
    "WindowPositionY"="0"
    "Borderless"=$false
}

# ?�ィ?�ド?�ス?�イ?�（調べ?�も?�く?�か?�な?�っ?�）
$WSDefault = 348651520
$WSBorderless = 335544320

# Win32API?�数??���?
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
        
        // 外枠??��?�さ?�考慮?�た?�ィ?�ド?�サ?�ズ変更
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


# 引数?�指定し?�か?�た?�き?�レ?�ス?�リ変更
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

# ?�ー?�を起動?�る?�め??��??��?�こ?�ら
# �?��?�ァ?�ル?�読?�込?�
if(Test-Path $ConfigJson){
    $Config = @{}
(ConvertFrom-Json (Get-Content $ConfigJson -Encoding utf8 -Raw )).psobject.properties | Foreach { $Config[$_.Name] = $_.Value }
}


# ?�ー?�本体に渡す引数
$InfArgs = ""

# 引数?�ら?�ー??��?�拾??
$Args[0] -match "tk=(.{64})" | Out-Null
$InfArgs += " -t "+$Matches[1]

# ?�ラ?�ア?�モ?�ド?�ら--trial?�つ?�る
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

# �?��?�保�?
$Config["Option"] = [string]$num
Save-Config

# INFINITAS?�起??
$p = Start-Exe($InfExe,"",""""+$InfArgs+"""")

# ?�ィ?�ド?�モ?�ド??��??
if($InfArgs.Contains("-w")){
    # ?�ィ?�ド?�作?�ま?�待??
    $p.WaitForInputIdle() | Out-Null

    # ?�ィ?�ド?�ハ?�ド?�の?�得
    $handle = $p.MainWindowHandle

    # ?�回??���?��大き?�に?�る
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

        # ?�ー?�?�レ?�化
        Switch-Borderless($Config["Borderless"])

        # 位置?�サ?�ズ?�反??
        [Win32Api]::MoveWindow2($handle, $Config["WindowPositionX"], $Config["WindowPositionY"], $Config["WindowWidth"], $Config["WindowHeight"], $Config["Borderless"])

        # �?��?�ァ?�ル?�書?�込?�
        Save-Config
    }
}




