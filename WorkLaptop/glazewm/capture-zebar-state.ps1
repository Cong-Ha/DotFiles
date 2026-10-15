# capture-zebar-state.ps1
# Diagnostic snapshot for the "Zebar missing from some monitors" problem.
# Run it WHILE the fault is visible. It only reads state; it changes nothing.
# Output is appended to zebar-diagnostics.log next to this script.

$ErrorActionPreference = 'SilentlyContinue'
$glzr = Join-Path $env:USERPROFILE '.glzr'
$out  = Join-Path $glzr 'glazewm\zebar-diagnostics.log'
$cli  = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'
$zb   = 'C:\Program Files\glzr.io\Zebar\zebar.exe'

$sig = @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class WinEnum {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    public static System.Collections.Generic.List<string> List(uint target) {
        var res = new System.Collections.Generic.List<string>();
        EnumWindows((h, l) => {
            uint pid; GetWindowThreadProcessId(h, out pid);
            if (pid != target) return true;
            var t = new StringBuilder(256); GetWindowTextW(h, t, 256);
            RECT r; GetWindowRect(h, out r);
            int w = r.Right - r.Left, ht = r.Bottom - r.Top;
            if (w < 2 || ht < 2) return true;   // skip the tray/helper stubs
            res.Add(string.Format("    {0,-8} title='{1}' at {2},{3} size {4}x{5}",
                IsWindowVisible(h) ? "visible" : "hidden", t.ToString(), r.Left, r.Top, w, ht));
            return true;
        }, IntPtr.Zero);
        return res;
    }
}
'@
Add-Type -TypeDefinition $sig

function W($s) { Add-Content -Path $out -Value $s -Encoding UTF8; Write-Host $s }

W ''
W ('=' * 78)
W ("SNAPSHOT $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
W ('=' * 78)

W ''
W '--- Windows / GlazeWM monitors ---'
$g = & $cli query monitors 2>$null | ConvertFrom-Json
if ($g) {
    $g.data.monitors | Sort-Object x, y | ForEach-Object {
        W ("    {0,-10} x={1,-7} y={2,-7} {3}x{4}  ws=[{5}]" -f $_.hardwareId, $_.x, $_.y, $_.width, $_.height, (($_.children | ForEach-Object { $_.name }) -join ','))
    }
} else { W '    GlazeWM did not answer.' }

W ''
W '--- Monitors that the RUNNING Zebar knows about ---'
$z = & $zb query monitors 2>$null | ConvertFrom-Json
if ($z) {
    $z | Sort-Object x, y | ForEach-Object {
        W ("    {0,-14} x={1,-7} y={2,-7} {3}x{4}  scale={5}  primary={6}" -f $_.name, $_.x, $_.y, $_.width, $_.height, $_.scaleFactor, $_.isPrimary)
    }
    W ("    COUNT: zebar sees $($z.Count), GlazeWM sees $($g.data.monitors.Count)")
} else { W '    Zebar did not answer. It is not running, or its IPC is dead.' }

W ''
W '--- Zebar bar windows ---'
$procs = @(Get-Process zebar -ErrorAction SilentlyContinue)
if ($procs.Count -eq 0) { W '    No zebar process.' }
foreach ($p in $procs) {
    W ("  pid $($p.Id), started $($p.StartTime)")
    $rows = [WinEnum]::List([uint32]$p.Id)
    if ($rows.Count -eq 0) { W '    (no windows)' } else { $rows | ForEach-Object { W $_ } }
}

W ''
W '--- Processes ---'
Get-Process glazewm, glazewm-watcher, zebar -ErrorAction SilentlyContinue |
    Sort-Object Name | ForEach-Object { W ("    {0,-16} pid {1,-7} started {2}" -f $_.Name, $_.Id, $_.StartTime) }

W ''
W '--- Supervisor ---'
$pf = Get-Content (Join-Path $glzr 'glazewm\supervisor.pid') -TotalCount 1
$sp = Get-CimInstance Win32_Process -Filter "ProcessId=$pf"
if ($sp) { W "    pid $pf ALIVE, started $($sp.CreationDate)" } else { W "    pid $pf is NOT running. Nothing is supervising." }

W ''
W '--- supervisor.log, last 10 ---'
Get-Content (Join-Path $glzr 'glazewm\supervisor.log') -Tail 10 | ForEach-Object { W "    $_" }

W ''
W '--- zebar errors.log, last 10 ---'
Get-Content (Join-Path $glzr 'zebar\errors.log') -Tail 10 | ForEach-Object { W ("    " + ($_ -replace "\x1b\[[0-9;]*m", '')) }

W ''
W '--- glazewm errors.log, last 5 ---'
Get-Content (Join-Path $glzr 'glazewm\errors.log') -Tail 5 | ForEach-Object { W ("    " + ($_ -replace "\x1b\[[0-9;]*m", '')) }

W ''
W "Saved to $out"
