# HCane-X Project - Windows / FiveM tweak tool (original work)
# Run: right-click > Run with PowerShell, or use Run_HCaneX.bat
# Every registry value / power plan changed is backed up first and can be restored.

$ErrorActionPreference = 'Continue'

# ---------- Elevation ----------
# If you host this file, put its raw URL here so "irm | iex" can re-launch itself as Admin.
$ScriptUrl = https://raw.githubusercontent.com/mooastun13-stack/HCane-X-V2.0/main/HCaneX.ps1

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($PSCommandPath) {
        # Started from a file
        Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"") -Verb RunAs
    } elseif ($ScriptUrl -notmatch 'YOUR-HOST') {
        # Started via: irm <url> | iex
        $cmd = "irm '$ScriptUrl' | iex"
        Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-Command',$cmd) -Verb RunAs
    } else {
        Write-Host 'Please open PowerShell as Administrator and run the command again.' -ForegroundColor Yellow
    }
    return
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ---------- State / backup ----------
$StateDir   = Join-Path $env:LOCALAPPDATA 'HCane-X'
$BackupFile = Join-Path $StateDir 'backup.json'
$LogFile    = Join-Path $StateDir 'log.txt'
if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }

$script:RegBackup   = New-Object System.Collections.ArrayList
$script:PowerScheme = $null

function Load-Backup {
    if (Test-Path $BackupFile) {
        try {
            $raw = Get-Content -LiteralPath $BackupFile -Raw | ConvertFrom-Json
            if ($raw.PowerScheme) { $script:PowerScheme = [string]$raw.PowerScheme }
            foreach ($e in @($raw.Registry)) { if ($e) { [void]$script:RegBackup.Add($e) } }
        } catch {}
    }
}
function Save-Backup {
    try {
        $obj = [pscustomobject]@{ PowerScheme = $script:PowerScheme; Registry = @($script:RegBackup) }
        ConvertTo-Json -InputObject $obj -Depth 5 | Set-Content -LiteralPath $BackupFile -Encoding UTF8
    } catch {}
}
Load-Backup

# ---------- UI ----------
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="HCane-X Project" Width="960" Height="540"
        WindowStartupLocation="CenterScreen" WindowStyle="None" ResizeMode="NoResize"
        Background="Black">
  <Window.Resources>
    <Style x:Key="HexBtn" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="26"/>
      <Setter Property="FontStyle" Value="Italic"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid>
              <Polygon x:Name="Bg" Points="0.06,0 0.94,0 1,0.5 0.94,1 0.06,1 0,0.5" Stretch="Fill"
                       Fill="#CC111111" Stroke="#FFFF1A1A" StrokeThickness="2">
                <Polygon.Effect>
                  <DropShadowEffect Color="Red" BlurRadius="20" ShadowDepth="0" Opacity="0.85"/>
                </Polygon.Effect>
              </Polygon>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bg" Property="Fill" Value="#FF4A0000"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="Bg" Property="Opacity" Value="0.4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="SmallBtn" TargetType="Button">
      <Setter Property="Foreground" Value="#FFFF4040"/>
      <Setter Property="Background" Value="#CC111111"/>
      <Setter Property="BorderBrush" Value="#FFFF1A1A"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="18,6"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
  </Window.Resources>

  <Grid>
    <Grid.Background>
      <RadialGradientBrush Center="0.5,0.5" RadiusX="0.9" RadiusY="0.9">
        <GradientStop Color="#FF050505" Offset="0.0"/>
        <GradientStop Color="#FF000000" Offset="0.55"/>
        <GradientStop Color="#FF3A0000" Offset="1.0"/>
      </RadialGradientBrush>
    </Grid.Background>

    <Button x:Name="BtnClose" Content="&#10005;" HorizontalAlignment="Right" VerticalAlignment="Top"
            Margin="0,10,14,0" Width="32" Height="28" Foreground="#FFFF4040" Background="Transparent"
            BorderThickness="0" FontSize="16" Cursor="Hand" Panel.ZIndex="10"/>

    <!-- Splash -->
    <Grid x:Name="Splash">
      <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
        <TextBlock Text="&#9819;" Foreground="#FFFF1A1A" FontSize="30" HorizontalAlignment="Center">
          <TextBlock.Effect><DropShadowEffect Color="Red" BlurRadius="14" ShadowDepth="0"/></TextBlock.Effect>
        </TextBlock>
        <Border BorderBrush="#FFB30000" BorderThickness="0,1,0,1" Background="#AA0A0A0A" Padding="70,14,70,12">
          <Border.Effect><DropShadowEffect Color="Red" BlurRadius="25" ShadowDepth="0" Opacity="0.6"/></Border.Effect>
          <StackPanel>
            <TextBlock HorizontalAlignment="Center" FontSize="84" FontStyle="Italic" FontWeight="Black">
              <Run Text="HCane-" Foreground="#FFEDEDED"/><Run Text="X" Foreground="#FFFF1A1A"/>
            </TextBlock>
            <TextBlock Text="Project" HorizontalAlignment="Center" Foreground="#FFEDEDED"
                       FontSize="30" FontStyle="Italic" FontWeight="SemiBold" Margin="60,-8,0,0"/>
          </StackPanel>
        </Border>
        <Button x:Name="BtnStart" Style="{StaticResource HexBtn}" Content="&#9654;   Start"
                Width="340" Height="76" Margin="0,38,0,0"/>
        <Button x:Name="BtnRestoreSplash" Style="{StaticResource SmallBtn}" Content="Restore original settings"
                HorizontalAlignment="Center" Margin="0,26,0,0"/>
      </StackPanel>
    </Grid>

    <!-- Log -->
    <Grid x:Name="LogPanel" Visibility="Collapsed" Margin="36,28,36,28">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>
      <TextBlock Grid.Row="0" FontSize="30" FontStyle="Italic" FontWeight="Black">
        <Run Text="HCane-X " Foreground="#FFEDEDED"/><Run Text="Project" Foreground="#FFFF1A1A"/>
      </TextBlock>
      <ProgressBar x:Name="Bar" Grid.Row="1" Height="8" Margin="0,10,0,10" Foreground="#FFFF1A1A"
                   Background="#FF1A1A1A" BorderThickness="0" Minimum="0" Maximum="100" Value="0"/>
      <TextBox x:Name="TxtLog" Grid.Row="2" IsReadOnly="True" Background="#EE050505" Foreground="#FFFF6A6A"
               BorderBrush="#FFB30000" FontFamily="Consolas" FontSize="13" TextWrapping="Wrap"
               VerticalScrollBarVisibility="Auto" Padding="8"/>
      <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
        <Button x:Name="BtnRestore" Style="{StaticResource SmallBtn}" Content="Restore original settings" Margin="0,0,10,0"/>
        <Button x:Name="BtnDone" Style="{StaticResource SmallBtn}" Content="Close"/>
      </StackPanel>
    </Grid>
  </Grid>
</Window>
'@

$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$xaml)))
$Splash     = $window.FindName('Splash')
$LogPanel   = $window.FindName('LogPanel')
$BtnStart   = $window.FindName('BtnStart')
$BtnRestoreSplash = $window.FindName('BtnRestoreSplash')
$BtnRestore = $window.FindName('BtnRestore')
$BtnDone    = $window.FindName('BtnDone')
$BtnClose   = $window.FindName('BtnClose')
$TxtLog     = $window.FindName('TxtLog')
$Bar        = $window.FindName('Bar')

function Pump {
    $window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
}
function Write-Log([string]$m) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $m
    $TxtLog.AppendText($line + "`r`n")
    $TxtLog.ScrollToEnd()
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch {}
    Pump
}

# ---------- Registry helper with backup ----------
function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    $key = "$Path|$Name"
    $already = $false
    foreach ($e in $script:RegBackup) { if ($e.Key -eq $key) { $already = $true; break } }
    if (-not $already) {
        $existed = $false; $old = $null; $kind = $null
        try {
            if (Test-Path -LiteralPath $Path) {
                $item = Get-Item -LiteralPath $Path
                if ($item.GetValueNames() -contains $Name) {
                    $existed = $true
                    $old  = $item.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
                    $kind = $item.GetValueKind($Name).ToString()
                }
            }
        } catch {}
        [void]$script:RegBackup.Add([pscustomobject]@{ Key = $key; Path = $Path; Name = $Name; Existed = $existed; Value = $old; Kind = $kind })
    }
    try {
        if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Log "   ! could not set $Path\$Name"
        return $false
    }
}

function Clear-Dir([string]$p) {
    if (Test-Path -LiteralPath $p) {
        Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "   cleared $p"
    }
}

# ---------- Tweaks ----------
$Tweaks = @(
    @{ Name = 'Game DVR / background recording -> Off'
       Desc = 'Stops Xbox Game DVR background capture, which costs CPU/GPU while gaming.'
       Run  = {
            Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 | Out-Null
            Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0 | Out-Null
            Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0 | Out-Null
       } }
    @{ Name = 'Game Bar overlay -> Off, Game Mode -> On'
       Desc = 'Disables the Game Bar startup panel and enables Windows Game Mode.'
       Run  = {
            Set-Reg 'HKCU:\SOFTWARE\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0 | Out-Null
            Set-Reg 'HKCU:\SOFTWARE\Microsoft\GameBar' 'ShowStartupPanel' 0 | Out-Null
            Set-Reg 'HKCU:\SOFTWARE\Microsoft\GameBar' 'AllowAutoGameMode' 1 | Out-Null
            Set-Reg 'HKCU:\SOFTWARE\Microsoft\GameBar' 'AutoGameModeEnabled' 1 | Out-Null
       } }
    @{ Name = 'Ultimate Performance power plan'
       Desc = 'Creates/activates the Ultimate Performance plan so the CPU does not down-clock mid-game. Previous plan is restored on Restore.'
       Run  = {
            $cur = (powercfg /getactivescheme) | Out-String
            if (-not $script:PowerScheme -and $cur -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
                $script:PowerScheme = $Matches[1]
            }
            $out = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) | Out-String
            if ($out -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
                powercfg /setactive $Matches[1] | Out-Null
            } else { Write-Log '   ! Ultimate Performance plan not available on this edition' }
       } }
    @{ Name = 'Power Throttling -> Off'
       Desc = 'Prevents Windows from throttling background-process power, keeping performance steady.'
       Run  = { Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1 | Out-Null } }
    @{ Name = 'Mouse acceleration -> Off (1:1 movement)'
       Desc = 'Disables Enhance Pointer Precision. Takes effect after next sign-in.'
       Run  = {
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String' | Out-Null
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String' | Out-Null
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String' | Out-Null
       } }
    @{ Name = 'Sticky / Toggle / Filter Keys shortcuts -> Off'
       Desc = 'Stops the Sticky Keys popup when tapping Shift repeatedly in-game.'
       Run  = {
            Set-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String' | Out-Null
            Set-Reg 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' 'String' | Out-Null
            Set-Reg 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122' 'String' | Out-Null
       } }
    @{ Name = "Nagle's algorithm -> Off (per network interface)"
       Desc = 'Sets TcpAckFrequency=1 and TCPNoDelay=1 so small packets (position/shooting updates) are sent immediately.'
       Run  = {
            $base = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
            Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
                Set-Reg $_.PSPath 'TcpAckFrequency' 1 | Out-Null
                Set-Reg $_.PSPath 'TCPNoDelay' 1 | Out-Null
            }
       } }
    @{ Name = 'TCP TIME_WAIT delay -> 30s'
       Desc = 'Releases ports sooner after connections close (default is 240s). Helps with frequent reconnects.'
       Run  = { Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' 'TcpTimedWaitDelay' 30 | Out-Null } }
    @{ Name = 'Network throttling -> Off, MMCSS gaming profile'
       Desc = 'Removes the multimedia network throttle and raises GPU/CPU priority for the Games task. SystemResponsiveness is set to 10 (safe value).'
       Run  = {
            $sp = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
            Set-Reg $sp 'NetworkThrottlingIndex' ([int]-1) | Out-Null
            Set-Reg $sp 'SystemResponsiveness' 10 | Out-Null
            $g = "$sp\Tasks\Games"
            Set-Reg $g 'GPU Priority' 8 | Out-Null
            Set-Reg $g 'Priority' 6 | Out-Null
            Set-Reg $g 'Scheduling Category' 'High' 'String' | Out-Null
            Set-Reg $g 'SFIO Priority' 'High' 'String' | Out-Null
       } }
    @{ Name = 'Win32PrioritySeparation -> 0x2E'
       Desc = 'Short, fixed quanta with foreground boost: favors the game window for lower input delay.'
       Run  = { Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 46 | Out-Null } }
    @{ Name = 'QoS reserved bandwidth -> 0%'
       Desc = 'Same effect as the gpedit "Limit reservable bandwidth" policy set to 0.'
       Run  = { Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched' 'NonBestEffortLimit' 0 | Out-Null } }
    @{ Name = 'Delivery Optimization (P2P updates) -> Off'
       Desc = 'Stops Windows from uploading update pieces to other PCs in the background.'
       Run  = { Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' 'DODownloadMode' 0 | Out-Null } }
    @{ Name = 'FiveM_GTAProcess.exe -> AboveNormal CPU priority (IFEO)'
       Desc = 'Windows applies this priority automatically every time FiveM_GTAProcess.exe starts, even if the game is not running now.'
       Run  = { Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FiveM_GTAProcess.exe\PerfOptions' 'CpuPriorityClass' 3 | Out-Null } }
    @{ Name = 'Clear FiveM cache, shader caches and old temp files'
       Desc = 'Deletes FiveM cache folders, GPU shader caches (rebuilt automatically) and temp files older than 2 days. Cannot be undone by Restore.'
       Run  = {
            $fm = Join-Path $env:LOCALAPPDATA 'FiveM\FiveM.app\data'
            foreach ($d in 'cache','server-cache','server-cache-priv') { Clear-Dir (Join-Path $fm $d) }
            foreach ($d in 'D3DSCache','NVIDIA\DXCache','NVIDIA\GLCache','AMD\DxCache') { Clear-Dir (Join-Path $env:LOCALAPPDATA $d) }
            $limit = (Get-Date).AddDays(-2)
            Get-ChildItem -LiteralPath $env:TEMP -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt $limit } |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "   cleared old files in $env:TEMP"
       } }
)

# ---------- Actions ----------
$script:Busy = $false

function Invoke-Start {
    if ($script:Busy) { return }
    $script:Busy = $true
    $Splash.Visibility = 'Collapsed'
    $LogPanel.Visibility = 'Visible'
    $BtnRestore.IsEnabled = $false; $BtnDone.IsEnabled = $false
    $Bar.Maximum = $Tweaks.Count + 1; $Bar.Value = 0
    try {
        Write-Log 'Creating System Restore Point...'
        try {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
            Checkpoint-Computer -Description 'HCane-X Project' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
            Write-Log '   restore point created'
        } catch {
            Write-Log '   ! restore point skipped (Windows allows one per 24h, or System Protection is off)'
        }
        $Bar.Value = 1

        $i = 0
        foreach ($t in $Tweaks) {
            $i++
            Write-Log ("[{0}/{1}] {2}" -f $i, $Tweaks.Count, $t.Name)
            Write-Log ("   " + $t.Desc)
            try { & $t.Run } catch { Write-Log ("   ! error: " + $_.Exception.Message) }
            Save-Backup
            $Bar.Value = $i + 1
            Pump
        }
        Write-Log ''
        Write-Log 'DONE. Original values were saved - use "Restore original settings" to undo.'
        Write-Log 'Sign out / restart Windows for all changes (mouse, priority) to fully apply.'
    } finally {
        $BtnRestore.IsEnabled = $true; $BtnDone.IsEnabled = $true
        $script:Busy = $false
    }
}

function Invoke-Restore {
    if ($script:Busy) { return }
    $script:Busy = $true
    $Splash.Visibility = 'Collapsed'
    $LogPanel.Visibility = 'Visible'
    $BtnRestore.IsEnabled = $false; $BtnDone.IsEnabled = $false
    try {
        Write-Log 'Restoring original settings...'
        if ($script:RegBackup.Count -eq 0 -and -not $script:PowerScheme) {
            Write-Log '   nothing to restore (no backup found)'
        }
        for ($n = $script:RegBackup.Count - 1; $n -ge 0; $n--) {
            $e = $script:RegBackup[$n]
            try {
                if ($e.Existed) {
                    $val = $e.Value
                    $type = [string]$e.Kind
                    if ($type -eq 'DWord') { $val = [int]$val }
                    elseif ($type -eq 'QWord') { $val = [long]$val }
                    if (-not (Test-Path -LiteralPath $e.Path)) { New-Item -Path $e.Path -Force | Out-Null }
                    Set-ItemProperty -LiteralPath $e.Path -Name $e.Name -Value $val -Type $type -Force -ErrorAction Stop
                } else {
                    Remove-ItemProperty -LiteralPath $e.Path -Name $e.Name -Force -ErrorAction SilentlyContinue
                }
                Write-Log ("   restored {0}\{1}" -f $e.Path, $e.Name)
            } catch { Write-Log ("   ! failed {0}\{1}" -f $e.Path, $e.Name) }
        }
        if ($script:PowerScheme) {
            powercfg /setactive $script:PowerScheme | Out-Null
            Write-Log "   power plan restored ($($script:PowerScheme))"
        }
        $script:RegBackup.Clear(); $script:PowerScheme = $null
        if (Test-Path $BackupFile) { Remove-Item -LiteralPath $BackupFile -Force -ErrorAction SilentlyContinue }
        Write-Log 'Restore finished. Sign out / restart Windows to fully apply.'
        Write-Log '(Cache cleanup cannot be restored; those files are rebuilt automatically.)'
    } finally {
        $BtnRestore.IsEnabled = $true; $BtnDone.IsEnabled = $true
        $script:Busy = $false
    }
}

$BtnStart.Add_Click({ Invoke-Start })
$BtnRestoreSplash.Add_Click({ Invoke-Restore })
$BtnRestore.Add_Click({ Invoke-Restore })
$BtnDone.Add_Click({ $window.Close() })
$BtnClose.Add_Click({ if (-not $script:Busy) { $window.Close() } })
$window.Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })

[void]$window.ShowDialog()
