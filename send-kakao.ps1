param(
    [Parameter(Mandatory=$true)][string]$ChatTitle,
    [Parameter(Mandatory=$true)][string]$Message,
    [switch]$CheckOnly,
    [switch]$ReplaceMatchingDraft
)
$ErrorActionPreference = 'Stop'
# KakaoTalk exposes its empty-input placeholder through ValuePattern.
$placeholder = -join ([char[]]@(0xBA54,0xC2DC,0xC9C0,0x20,0xC785,0xB825))
function Test-EmptyInput([string]$text) {
    $normalized = $text.TrimEnd([char]13, [char]10)
    return ($normalized -eq '' -or $normalized -eq $placeholder)
}
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class KakaoWindow {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
}
'@

$root = [System.Windows.Automation.AutomationElement]::RootElement
$condition = [System.Windows.Automation.PropertyCondition]::new(
    [System.Windows.Automation.AutomationElement]::NameProperty, $ChatTitle)
$windows = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $condition)
$matches = @($windows | Where-Object {
    (Get-Process -Id $_.Current.ProcessId).ProcessName -eq 'KakaoTalk'
})
if ($matches.Count -ne 1) { throw 'Expected exactly one KakaoTalk window with the specified title.' }
$window = $matches[0]
$editCondition = [System.Windows.Automation.PropertyCondition]::new(
    [System.Windows.Automation.AutomationElement]::ClassNameProperty,
    'RICHEDIT50W')
$edits = @($window.FindAll([System.Windows.Automation.TreeScope]::Descendants, $editCondition) |
    Where-Object { $_.Current.IsEnabled -and $_.Current.IsKeyboardFocusable -and -not $_.Current.IsOffscreen })
if ($edits.Count -ne 1) { throw 'Cannot uniquely identify the message input. No message sent.' }
$edit = $edits[0]
$value = $edit.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
$handle = [IntPtr]$window.Current.NativeWindowHandle
[void][KakaoWindow]::ShowWindow($handle, 9)
[void][KakaoWindow]::SetForegroundWindow($handle)
Start-Sleep -Milliseconds 300
$edit.SetFocus()
Start-Sleep -Milliseconds 300
if ([KakaoWindow]::GetForegroundWindow() -ne $handle) { throw 'Chat is not foreground. No message sent.' }
$matchingDraft = $ReplaceMatchingDraft -and ($value.Current.Value.TrimEnd([char]13, [char]10) -eq $Message)
if ($value.Current.IsReadOnly -or (-not (Test-EmptyInput $value.Current.Value) -and -not $matchingDraft)) {
    throw 'Focused message input is read-only or contains a draft. No message sent.'
}
if ($CheckOnly) { Write-Output 'READY'; exit 0 }
$savedClipboard = [System.Windows.Forms.Clipboard]::GetDataObject()
try {
    [System.Windows.Forms.Clipboard]::SetText($Message)
    if ([KakaoWindow]::GetForegroundWindow() -ne $handle -or -not $edit.Current.HasKeyboardFocus) {
        throw 'Chat input lost focus. No message sent.'
    }
    if ($matchingDraft) { [System.Windows.Forms.SendKeys]::SendWait('^a') }
    [System.Windows.Forms.SendKeys]::SendWait('^v')
    Start-Sleep -Milliseconds 500
} finally {
    if ([System.Windows.Forms.Clipboard]::ContainsText() -and
        [System.Windows.Forms.Clipboard]::GetText() -eq $Message) {
        if ($null -ne $savedClipboard) {
            [System.Windows.Forms.Clipboard]::SetDataObject($savedClipboard, $true)
        } else { [System.Windows.Forms.Clipboard]::Clear() }
    }
}
if ([KakaoWindow]::GetForegroundWindow() -ne $handle -or
    -not $edit.Current.HasKeyboardFocus -or $value.Current.Value.TrimEnd([char]13, [char]10) -ne $Message) {
    throw 'Input verification failed. Message may remain as a draft; not sent.'
}
[System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
Start-Sleep -Milliseconds 500
if (-not (Test-EmptyInput $value.Current.Value)) { throw 'Submission not confirmed. Do not automatically retry.' }
Write-Output 'SUBMITTED'
