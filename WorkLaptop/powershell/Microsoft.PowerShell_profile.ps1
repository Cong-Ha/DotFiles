# zoxide - smarter cd
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Fix: zoxide query returns Object[] on Windows; cast to [string] before Set-Location
function global:__zoxide_z {
    if ($args.Length -eq 0) {
        __zoxide_cd ~ $true
    }
    elseif ($args.Length -eq 1 -and ($args[0] -eq '-' -or $args[0] -eq '+')) {
        __zoxide_cd $args[0] $false
    }
    elseif ($args.Length -eq 1 -and (Test-Path $args[0] -PathType Container)) {
        __zoxide_cd $args[0] $true
    }
    else {
        $result = __zoxide_pwd
        if ($null -ne $result) {
            $result = [string](__zoxide_bin query --exclude $result -- @args)
        }
        else {
            $result = [string](__zoxide_bin query -- @args)
        }
        if ($LASTEXITCODE -eq 0) {
            __zoxide_cd $result $true
        }
    }
}

& "C:\Program Files (x86)\oh-my-posh\bin\oh-my-posh.exe" init pwsh --config "$env:POSH_THEMES_PATH\spaceship.omp.json" | Invoke-Expression

function Set-PoshTheme {
    param([string]$Theme)

    if (-not $Theme) {
        Get-ChildItem $env:POSH_THEMES_PATH -Filter "*.omp.json" |
            Select-Object -ExpandProperty BaseName |
            ForEach-Object { $_ -replace '\.omp$', '' }
        return
    }

    $path = Join-Path $env:POSH_THEMES_PATH "$Theme.omp.json"
    if (-not (Test-Path $path)) {
        Write-Error "Theme '$Theme' not found. Run Set-PoshTheme to list available themes."
        return
    }

    & "C:\Program Files (x86)\oh-my-posh\bin\oh-my-posh.exe" init pwsh --config $path | Invoke-Expression
    Write-Host "Switched to theme: $Theme"
}

Set-Alias posh Set-PoshTheme

# yazi - file manager; 'y' exits into the last directory
function y {
	$tmp = (New-TemporaryFile).FullName
	yazi.exe @args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}
