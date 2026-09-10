# FAHRT — Fun Ad-Hoc Reminder Tool
#
# A configurable popup reminder. Run with -Setup to choose the reminder text
# (up to 4 lines, 20 chars each) and one of four sound combos; run with no
# arguments to show the reminder itself. Reads/writes a small JSON companion
# file (FAHRT.config.json) next to the exe — falls back to built-in defaults
# if that file is missing or unreadable.
#
# Scheduling is left to the user (Windows Task Scheduler) — see README.md.

param([switch]$Setup)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) }
$ConfigPath = Join-Path $ScriptDir "FAHRT.config.json"

# --- MP3 playback (winmm.dll MCI) — in-process, no spawned helper process ---
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class FahrtMci {
    [DllImport("winmm.dll")]
    public static extern int mciSendString(string c, StringBuilder r, int l, IntPtr h);
}
"@

function Play-Mp3 {
    param([string]$Path)
    $sb = New-Object System.Text.StringBuilder 128
    [FahrtMci]::mciSendString("close clip", $sb, 128, [IntPtr]::Zero) | Out-Null
    [FahrtMci]::mciSendString("open `"$Path`" type mpegvideo alias clip", $sb, 128, [IntPtr]::Zero) | Out-Null
    [FahrtMci]::mciSendString("play clip", $sb, 128, [IntPtr]::Zero) | Out-Null
}

function Play-Wav {
    param([string]$Path)
    (New-Object System.Media.SoundPlayer($Path)).Play()
}

# --- Sound combos ---
$SoundCombos = [ordered]@{
    "UpTrombone"       = @{ Entrance = "UpSound"; Dismiss = "SadTrombone"; Label = "Rising Tone -> Sad Trombone" }
    "RedAlertTrombone" = @{ Entrance = "RedAlert"; Dismiss = "SadTrombone"; Label = "Red Alert -> Sad Trombone" }
    "UpQuack"          = @{ Entrance = "UpSound"; Dismiss = "MacQuack";    Label = "Rising Tone -> Mac Quack" }
    "RedAlertQuack"    = @{ Entrance = "RedAlert"; Dismiss = "MacQuack";    Label = "Red Alert -> Mac Quack" }
}
$DismissDelayMs = @{ "SadTrombone" = 4000; "MacQuack" = 900 }

function Get-DefaultConfig {
    return @{ Items = @("List Item #1", "List Item number two"); SoundCombo = "UpQuack" }
}

function Load-FahrtConfig {
    $default = Get-DefaultConfig
    if (-not (Test-Path $ConfigPath)) { return $default }
    try {
        $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $items = @($json.Items) | Where-Object { $_ } | Select-Object -First 4
        $items = @($items | ForEach-Object { $_.Substring(0, [Math]::Min(20, $_.Length)) })
        if ($items.Count -eq 0) { $items = $default.Items }
        $combo = [string]$json.SoundCombo
        if (-not $SoundCombos.Contains($combo)) { $combo = $default.SoundCombo }
        return @{ Items = $items; SoundCombo = $combo }
    } catch {
        return $default
    }
}

function Save-FahrtConfig {
    param([string[]]$Items, [string]$SoundCombo)
    @{ Items = $Items; SoundCombo = $SoundCombo } | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8
}

if ($Setup) {
    $cfg = Load-FahrtConfig

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "FAHRT Setup"
    $form.Size = New-Object System.Drawing.Size(380, 430)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $y = 15
    $lbl1 = New-Object System.Windows.Forms.Label
    $lbl1.Text = "Reminder text (up to 4 lines, 20 characters each):"
    $lbl1.Location = New-Object System.Drawing.Point(15, $y)
    $lbl1.Size = New-Object System.Drawing.Size(340, 20)
    $form.Controls.Add($lbl1)
    $y += 24

    $textBoxes = @()
    for ($i = 0; $i -lt 4; $i++) {
        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Location = New-Object System.Drawing.Point(15, $y)
        $tb.Size = New-Object System.Drawing.Size(340, 22)
        $tb.MaxLength = 20
        if ($i -lt $cfg.Items.Count) { $tb.Text = $cfg.Items[$i] }
        $form.Controls.Add($tb)
        $textBoxes += $tb
        $y += 28
    }

    $y += 12
    $lbl2 = New-Object System.Windows.Forms.Label
    $lbl2.Text = "Sound combo:"
    $lbl2.Location = New-Object System.Drawing.Point(15, $y)
    $lbl2.Size = New-Object System.Drawing.Size(340, 20)
    $form.Controls.Add($lbl2)
    $y += 24

    $radios = @()
    foreach ($key in $SoundCombos.Keys) {
        $rb = New-Object System.Windows.Forms.RadioButton
        $rb.Text = $SoundCombos[$key].Label
        $rb.Tag = $key
        $rb.Location = New-Object System.Drawing.Point(25, $y)
        $rb.Size = New-Object System.Drawing.Size(320, 22)
        if ($key -eq $cfg.SoundCombo) { $rb.Checked = $true }
        $form.Controls.Add($rb)
        $radios += $rb
        $y += 26
    }

    $y += 15
    $saveBtn = New-Object System.Windows.Forms.Button
    $saveBtn.Text = "Save"
    $saveBtn.Location = New-Object System.Drawing.Point(150, $y)
    $saveBtn.Size = New-Object System.Drawing.Size(90, 30)
    $form.AcceptButton = $saveBtn
    $saveBtn.Add_Click({
        $items = @($textBoxes | ForEach-Object { $_.Text.Trim() } | Where-Object { $_ -ne "" })
        if ($items.Count -eq 0) { $items = (Get-DefaultConfig).Items }
        $selected = ($radios | Where-Object { $_.Checked } | Select-Object -First 1).Tag
        if (-not $selected) { $selected = (Get-DefaultConfig).SoundCombo }
        Save-FahrtConfig -Items $items -SoundCombo $selected
        [System.Windows.Forms.MessageBox]::Show("Saved to $ConfigPath", "FAHRT Setup") | Out-Null
        $form.Close()
    })
    $form.Controls.Add($saveBtn)

    [System.Windows.Forms.Application]::Run($form)
    exit
}

# --- Normal reminder mode ---
$cfg = Load-FahrtConfig
$combo = $SoundCombos[$cfg.SoundCombo]
$itemCount = $cfg.Items.Count

$popup = New-Object System.Windows.Forms.Form
$popup.Text = "Morning Reminder"
$popup.FormBorderStyle = "FixedDialog"
$popup.MaximizeBox = $false
$popup.MinimizeBox = $false
$popup.StartPosition = "CenterScreen"
$popup.TopMost = $true
$popup.ClientSize = New-Object System.Drawing.Size(320, (90 + ($itemCount * 24)))

$iconBox = New-Object System.Windows.Forms.PictureBox
$iconPath = Join-Path $ScriptDir "FAHRT.png"
if (Test-Path $iconPath) { $iconBox.Image = [System.Drawing.Image]::FromFile($iconPath) }
$iconBox.SizeMode = "Zoom"
$iconBox.Location = New-Object System.Drawing.Point(20, 20)
$iconBox.Size = New-Object System.Drawing.Size(48, 48)
$popup.Controls.Add($iconBox)

$textLabel = New-Object System.Windows.Forms.Label
$textLabel.Text = ($cfg.Items -join "`r`n")
$textLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$textLabel.Location = New-Object System.Drawing.Point(80, 20)
$textLabel.Size = New-Object System.Drawing.Size(220, ($itemCount * 24))
$popup.Controls.Add($textLabel)

$okBtn = New-Object System.Windows.Forms.Button
$okBtn.Text = "OK"
$okBtn.Size = New-Object System.Drawing.Size(80, 28)
$okBtn.Location = New-Object System.Drawing.Point(220, ($popup.ClientSize.Height - 40))
$popup.Controls.Add($okBtn)
$popup.AcceptButton = $okBtn

$closeTimer = New-Object System.Windows.Forms.Timer
$closeTimer.Add_Tick({ $closeTimer.Stop(); $popup.Close() })

$okBtn.Add_Click({
    $okBtn.Enabled = $false
    Play-Mp3 (Join-Path $ScriptDir ($combo.Dismiss + ".mp3"))
    $closeTimer.Interval = $DismissDelayMs[$combo.Dismiss]
    $closeTimer.Start()
})

$blastTimer = New-Object System.Windows.Forms.Timer
$blastTimer.Interval = 1400
$blastTimer.Add_Tick({ $blastTimer.Stop(); Play-Mp3 (Join-Path $ScriptDir "RedAlert.mp3") })

$popup.Add_Shown({
    if ($combo.Entrance -eq "RedAlert") {
        Play-Mp3 (Join-Path $ScriptDir "RedAlert.mp3")
        $blastTimer.Start()
    } else {
        Play-Wav (Join-Path $ScriptDir "UpSound.wav")
    }
})

[System.Windows.Forms.Application]::Run($popup)
