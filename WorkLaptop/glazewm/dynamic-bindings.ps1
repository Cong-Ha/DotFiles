# dynamic-bindings.ps1
# Launches GlazeWM with monitor bindings computed from whatever displays are
# actually connected - no per-location config needed - then supervises the
# daemon so a crash does not silently take the desktop and Zebar down with it.
#
# Bindings come from a DESK PROFILE, not from a positional rule. GlazeWM 3.x can
# only bind a workspace to a monitor INDEX, and that index is the monitor's
# left-to-right position - so the same number lands on a different screen at every
# desk. Profiles are keyed on hardwareId, which is stable, and the index is
# resolved at run time from whatever Windows reports. See $deskProfiles below.
# A desk that matches no profile falls back to the old positional rule.
#
# Registered as a login startup item; can also be run manually any time after
# docking/undocking to re-detect. A manual re-run takes over from the supervisor
# already running, which is stopped first.

# NOTE: deliberately NOT 'Stop'. Windows PowerShell 5.1 promotes native-command
# stderr (e.g. GlazeWM's expected "Failed to connect to IPC server" while the
# daemon is still warming up) into terminating errors under 'Stop', which would
# abort the probe wait-loop. We check $LASTEXITCODE / return values explicitly.
$ErrorActionPreference = 'Continue'
$glzr     = Join-Path $env:USERPROFILE '.glzr\glazewm'
$config   = Join-Path $glzr 'config.yaml'
$log      = Join-Path $glzr 'supervisor.log'
$pidFile  = Join-Path $glzr 'supervisor.pid'
$daemon   = 'C:\Program Files\glzr.io\GlazeWM\glazewm.exe'
$cli      = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'
$zebar    = 'C:\Program Files\glzr.io\Zebar\zebar.exe'
$laptopHw = 'BOE0BCA'   # built-in laptop panel - stable across all docks

# Let the WM settle before starting Zebar, which reads workspaces over the WM's
# IPC socket and renders an empty bar if it connects too early.
$zebarGraceSec = 3

# Circuit breaker: this many crashes inside this window means GlazeWM cannot
# stay up at all, so stop restarting it and leave a note in the log.
$maxCrashes     = 5
$crashWindowMin = 5

$startMarker = '# >>> GENERATED-WORKSPACES-START <<<'
$endMarker   = '# >>> GENERATED-WORKSPACES-END <<<'

#region Logging

function Write-Log([string]$msg) {
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    try {
        # Keep the tail only, so an unattended supervisor cannot grow this
        # without bound over months of uptime.
        if ((Test-Path $log) -and ((Get-Item $log).Length -gt 262144)) {
            $keep = Get-Content -Path $log -Tail 500
            [System.IO.File]::WriteAllLines($log, $keep)
        }
        Add-Content -Path $log -Value $line -Encoding UTF8
    } catch { }
    Write-Host $line
}

#endregion

#region Config rewriting

# Rewrite only the text between the two markers, preserving the rest of the file.
function Set-WorkspacesBlock([string]$body) {
    # Read as UTF-8 explicitly. Windows PowerShell 5.1's `Get-Content -Raw` reads
    # using the legacy ANSI codepage, which corrupts any non-ASCII byte on a
    # round-trip write. ReadAllText honors a BOM and defaults to UTF-8.
    $raw = [System.IO.File]::ReadAllText($config)
    $pattern = "(?s)($([regex]::Escape($startMarker))\r?\n).*?(\s*$([regex]::Escape($endMarker)))"
    $new = [regex]::Replace($raw, $pattern, { param($m) $m.Groups[1].Value + $body + "`r`n  " + $endMarker })
    # Write UTF-8 WITHOUT a BOM. Windows PowerShell 5.1's `Set-Content -Encoding UTF8`
    # prepends a BOM that the YAML parser can choke on; this is host-agnostic.
    [System.IO.File]::WriteAllText($config, $new, (New-Object System.Text.UTF8Encoding($false)))
}

# Emission order is the number row: 1-9, then 0. Both the Zebar bar and
# `focus --next-active-workspace` follow config order, so cycling matches the keys.
$workspaceOrder = @('1', '2', '3', '4', '5', '6', '7', '8', '9', '0')

# Build a workspaces YAML body from a hashtable of {workspaceName = monitorIndex}.
# A $null index emits no bind_to_monitor line, which leaves GlazeWM to place that
# workspace itself - the correct result when its monitor is not connected.
function Build-Body([hashtable]$bind, [string]$note) {
    $lines = @("  # $note")
    foreach ($n in $workspaceOrder) {
        $lines += "  - name: '$n'"
        if ($null -ne $bind[$n]) { $lines += "    bind_to_monitor: $($bind[$n])" }
        # Workspace 0 is a fixed slot at both desks, so hold it open when empty.
        if ($n -eq '0') { $lines += '    keep_alive: true' }
    }
    return ($lines -join "`r`n")
}

#endregion

#region Desk profiles

# Signature = the sorted multiset of connected hardwareIds. Match is exact, so a
# desk with one screen missing does NOT match, and falls through to the generic
# rule rather than binding half a layout to the wrong screens.
#
# A Map target is 'HWID' or 'HWID#n'. The '#n' suffix picks the n-th monitor with
# that hardwareId in x,y order, 1-based. The office desk needs it: both LG 4K
# panels report the same hardwareId (GSM7750) and differ only by a serial that
# GlazeWM does not expose. Left and right there follow cable position, not
# identity - swap the two cables and workspaces 9 and 0 swap with them.
$deskProfiles = @(
    @{
        Name      = 'home'
        Signature = @('BOE0BCA', 'GSM5BD2', 'GSM5CA8', 'VTK3200')
        Map       = @{
            '0' = 'BOE0BCA'   # laptop panel, right of the stack
            '1' = 'GSM5CA8'   # LG ULTRAGEAR+, main
            '2' = 'GSM5CA8'
            '3' = 'GSM5CA8'
            '4' = 'GSM5CA8'
            '5' = 'GSM5CA8'
            '6' = 'GSM5CA8'
            '7' = 'GSM5CA8'
            '8' = 'VTK3200'   # GN32DB, stacked above the ULTRAGEAR+
            '9' = 'GSM5BD2'   # LG ULTRAGEAR, portrait, far left
        }
    },
    @{
        Name      = 'office'
        Signature = @('BOE0BCA', 'GSM7750', 'GSM7750')
        Map       = @{
            '1' = 'BOE0BCA'   # laptop panel takes 1-8
            '2' = 'BOE0BCA'
            '3' = 'BOE0BCA'
            '4' = 'BOE0BCA'
            '5' = 'BOE0BCA'
            '6' = 'BOE0BCA'
            '7' = 'BOE0BCA'
            '8' = 'BOE0BCA'
            '9' = 'GSM7750#1' # LG HDR 4K, left
            '0' = 'GSM7750#2' # LG HDR 4K, right
        }
    }
)

function Get-Signature($mons) {
    return ((@($mons | ForEach-Object { $_.hw }) | Sort-Object) -join '+')
}

# Returns the monitor index for a Map target, or $null when that monitor is absent.
function Resolve-Target([string]$target, $mons) {
    $hw  = $target
    $nth = 1
    if ($target -match '^(.+)#(\d+)$') {
        $hw  = $Matches[1]
        $nth = [int]$Matches[2]
    }
    $hits = @($mons | Where-Object { $_.hw -eq $hw } | Sort-Object index)
    if ($hits.Count -lt $nth) { return $null }
    return $hits[$nth - 1].index
}

#endregion

#region Process control

# A manual re-run after docking must not leave the previous supervisor running:
# it would read our Stop-Glaze as a crash and race us relaunching the daemon.
# Target the PID we recorded last run, NOT a command-line scan. A scan also
# matches whatever shell launched us, because this script's path appears in that
# shell's own command line - which makes the script kill its own launcher.
function Stop-OtherSupervisors {
    if (-not (Test-Path $pidFile)) { return }
    $old = 0
    $raw = Get-Content -Path $pidFile -TotalCount 1 -ErrorAction SilentlyContinue
    if (-not [int]::TryParse($raw, [ref]$old)) { return }
    if ($old -le 0 -or $old -eq $PID) { return }

    $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$old" -ErrorAction SilentlyContinue
    # Confirm the PID was not recycled onto some unrelated process.
    if ($proc -and $proc.Name -match '^(powershell|pwsh)\.exe$' -and $proc.CommandLine -match 'dynamic-bindings\.ps1') {
        Write-Log "Stopping previous supervisor (pid $old)."
        Stop-Process -Id $old -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
}

function Get-Zebar { return @(Get-Process zebar -ErrorAction SilentlyContinue) }

function Stop-Zebar {
    for ($i = 0; $i -lt 20; $i++) {
        $procs = Get-Zebar
        if (-not $procs) { return }
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 200
    }
}

# This supervisor is the SINGLE owner of Zebar: `startup_commands` in config.yaml
# is deliberately empty, because a WM that also launches Zebar races this check
# and leaves two bars stacked on every monitor. Owning it here means the bar
# survives a WM crash, and survives Zebar dying on its own.
function Ensure-Zebar {
    if (Get-Zebar) { return }
    Write-Log 'Zebar not running; starting it directly.'
    Start-Process -FilePath $zebar -ArgumentList 'startup'
}

function Stop-Glaze {
    # Clean exit first so GlazeWM runs shutdown_commands (kills zebar).
    try { & $cli command 'wm-exit' 2>$null | Out-Null } catch { }
    # Then force-kill the daemon, its watcher, and zebar - polling until the
    # process table is actually clear so the next Start-Glaze can't race a
    # half-dead instance into a duplicate daemon.
    #
    # glazewm-watcher is a child of the daemon and only un-cloaks orphaned
    # windows when the WM dies unexpectedly; it never restarts the WM. That is
    # why the restart loop below has to exist.
    for ($i = 0; $i -lt 20; $i++) {
        $procs = Get-Process glazewm, glazewm-watcher, zebar -ErrorAction SilentlyContinue
        if (-not $procs) { return }
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 300
    }
}

# Starts the daemon and waits for its IPC server. Returns the Process object on
# success, or $null if it never came up.
function Start-Glaze {
    $proc = Start-Process -FilePath $daemon -PassThru
    # Touching Handle caches it, which is what keeps ExitCode readable after the
    # process dies. Without this, PowerShell can throw on ExitCode.
    $null = $proc.Handle
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 500
        if ($proc.HasExited) { return $null }
        $out = & $cli query monitors 2>$null
        if ($LASTEXITCODE -eq 0 -and $out) { return $proc }
    }
    return $null
}

function Get-ExitCode($proc) {
    try { return $proc.ExitCode } catch { return $null }
}

#endregion

#region Supervisor

# GlazeWM 3.x can die with an access violation (0xC0000005 in combase.dll) some
# minutes after login. Nothing in the GlazeWM install restarts it, and Zebar is
# only ever launched from the daemon, so one crash silently costs both the tiling
# and the bar for the rest of the session. Supervise instead: exit code 0 is a
# deliberate shutdown (wm-exit, tray Exit) and ends the loop; anything else is a
# crash and gets restarted.
function Invoke-Supervisor {
    $crashes  = New-Object System.Collections.ArrayList
    $restarts = 0

    while ($true) {
        $proc = Start-Glaze
        if (-not $proc) {
            Write-Log 'GlazeWM IPC never came up. Supervisor stopping.'
            Ensure-Zebar   # at least keep the bar, even with no WM
            return 1
        }

        Write-Log "GlazeWM running (pid $($proc.Id)). Supervising."
        Start-Sleep -Seconds $zebarGraceSec
        Ensure-Zebar

        # Poll rather than block, so an independent Zebar death is caught too.
        while (-not $proc.WaitForExit(5000)) { Ensure-Zebar }

        $code = Get-ExitCode $proc
        if ($code -eq 0) {
            Write-Log 'GlazeWM exited cleanly. Supervisor stopping.'
            Stop-Zebar
            return 0
        }

        $restarts++
        if ($null -eq $code) { $shown = 'unknown' } else { $shown = '0x{0:X8}' -f $code }
        Write-Log "GlazeWM died with exit code $shown. Restart #$restarts."

        $now = Get-Date
        [void]$crashes.Add($now)
        $cutoff = $now.AddMinutes(-$crashWindowMin)
        $recent = @($crashes | Where-Object { $_ -gt $cutoff })
        if ($recent.Count -ge $maxCrashes) {
            Write-Log "$($recent.Count) crashes in $crashWindowMin min - crash loop. Supervisor stopping, leaving Zebar up."
            Ensure-Zebar
            return 1
        }

        # shutdown_commands do NOT run on a crash, so Zebar is orphaned and the
        # next start would produce a second one. Clear the whole set first.
        Stop-Zebar
        Stop-Glaze
        Start-Sleep -Seconds 3
    }
}

#endregion

# --- 0. Take over from any supervisor already running ---
Stop-OtherSupervisors
Set-Content -Path $pidFile -Value $PID -Encoding ASCII
Write-Log "Supervisor starting (pid $PID)."

# --- 1. Probe: start with binding-free workspaces so every monitor is detectable ---
$probeLines = @('  # (probing monitors - regenerated below)')
$workspaceOrder | ForEach-Object { $probeLines += "  - name: '$_'" }
Set-WorkspacesBlock ($probeLines -join "`r`n")

Stop-Glaze
if (-not (Start-Glaze)) {
    Write-Log 'GlazeWM IPC never came up during probe.'
    Ensure-Zebar
    exit 1
}

# --- 2. Read layout. GlazeWM monitor index = position sorted by x, then y. ---
# The y tie-break matters for stacked screens. At the home desk the GN32DB sits
# directly above the ULTRAGEAR+, so their x values differ by a single pixel and an
# x-only sort lets a nudge in display settings swap two workspaces between them.
$mons = (& $cli query monitors | ConvertFrom-Json).data.monitors |
    Select-Object @{N='hw'; E={$_.hardwareId}}, @{N='x'; E={$_.x}}, @{N='y'; E={$_.y}} |
    Sort-Object x, y
$indexed = @()
for ($i = 0; $i -lt $mons.Count; $i++) {
    $indexed += [pscustomobject]@{ index = $i; hw = $mons[$i].hw; x = $mons[$i].x; y = $mons[$i].y }
}

$laptop    = $indexed | Where-Object { $_.hw -eq $laptopHw } | Select-Object -First 1
$laptopIdx = if ($laptop) { $laptop.index } else { $null }
$signature = Get-Signature $indexed
Write-Log "Monitors: [$signature]"

# --- 3. Bind from the matching desk profile, else fall back to the generic rule ---
$desk = $deskProfiles |
    Where-Object { ((@($_.Signature) | Sort-Object) -join '+') -eq $signature } |
    Select-Object -First 1

if ($desk) {
    $bind    = @{}
    $missing = @()
    foreach ($ws in $workspaceOrder) {
        $target = $desk.Map[$ws]
        if (-not $target) { $bind[$ws] = $null; continue }
        $idx = Resolve-Target $target $indexed
        if ($null -eq $idx) {
            # Exact signature matching means this cannot normally happen, so a hit
            # here is a typo in the profile. Degrade to the laptop and say so.
            $missing += "$ws=$target"
            $idx = $laptopIdx
        }
        $bind[$ws] = $idx
    }

    $note = "AUTO-GENERATED $(Get-Date -Format 'yyyy-MM-dd HH:mm') | profile=$($desk.Name) | $signature"
    Set-WorkspacesBlock (Build-Body $bind $note)
    $shown = (@($workspaceOrder | ForEach-Object { "$_=$($bind[$_])" })) -join ' '
    Write-Log "Profile '$($desk.Name)' applied: $shown"
    if ($missing.Count -gt 0) {
        Write-Log "Unresolved profile targets, sent to the laptop: $($missing -join ', ')"
    }
}
elseif ($laptop) {
    # Unknown desk. Keep the original positional rule: the laptop takes
    # 0,1,2,3,7,8,9 and the externals take 4,5,6 left to right. A number with no
    # monitor goes to the laptop.
    $externalIdx = @($indexed | Where-Object { $_.index -ne $laptopIdx } | Sort-Object index | ForEach-Object { $_.index })

    $bind = @{}
    '0', '1', '2', '3', '7', '8', '9' | ForEach-Object { $bind[$_] = $laptopIdx }
    $extWorkspaces = '4', '5', '6'
    for ($k = 0; $k -lt $extWorkspaces.Count; $k++) {
        if ($k -lt $externalIdx.Count) { $bind[$extWorkspaces[$k]] = $externalIdx[$k] }
        else { $bind[$extWorkspaces[$k]] = $laptopIdx }
    }

    $note = "AUTO-GENERATED $(Get-Date -Format 'yyyy-MM-dd HH:mm') | profile=none (generic) | $signature"
    Set-WorkspacesBlock (Build-Body $bind $note)
    Write-Log "No profile for [$signature]. Generic rule: laptop(idx $laptopIdx) -> 0,1,2,3,7,8,9 ; externals(idx $($externalIdx -join ',')) -> 4,5,6"
}
else {
    # No profile and no laptop panel, e.g. clamshell at an unknown desk. Leave the
    # probe config in place so GlazeWM still runs, just with no bindings.
    Write-Log "No profile for [$signature] and no laptop panel ($laptopHw); leaving workspaces unbound."
}

# --- 4. Restart with the computed bindings, then supervise for the session ---
Stop-Glaze
exit (Invoke-Supervisor)
