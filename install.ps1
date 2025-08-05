$apps = @(
    "Helix.Helix",
    "Starship.Starship",
    "eza-community.eza",
    "BurntSushi.ripgrep.MSVC",
    "sharkdp.fd",
    "Gyan.FFmpeg",
    "7zip.7zip", 
    "jqlang.jq", 
    "sharkdp.fd", 
    "sharkdp.bat",
    "junegunn.fzf", 
    "ajeetdsouza.zoxide", 
    "ImageMagick.ImageMagick",
    "sxyazi.yazi",
    "Nushell.Nushell",
    "Git.Git",
    "Microsoft.PowerShell",
    "uutils.coreutils",
    "hrkfdn.ncspot",
    "jtroo.kanata_gui",
    "rsteube.Carapace"
)

foreach ($app in $apps) {
    winget install --id $app --accept-source-agreements --accept-package-agreements -e
}

# --- Nushell + Carapace wiring (Windows) ---
$nuDir = Join-Path $env:APPDATA "nushell"                 # Nushell config dir on Windows
$cache = Join-Path $env:USERPROFILE ".cache\carapace"
$envNu = Join-Path $nuDir "env.nu"
$initNu = Join-Path $cache "init.nu"

New-Item -ItemType Directory -Force -Path $nuDir, $cache | Out-Null

# Optional bridges
$bridgesLine = "$" + "env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'"
if (Test-Path $envNu) {
    $existing = Get-Content $envNu -Raw
    if ($existing -notmatch 'CARAPACE_BRIDGES') { Add-Content -Path $envNu -Value "`n$bridgesLine`n" }
}
else {
    Set-Content -Path $envNu -Value $bridgesLine
}

# Locate carapace (works even before a new shell picks up PATH)
$carapaceCmd = Get-Command carapace -ErrorAction SilentlyContinue
$carapace = $null
if ($carapaceCmd) {
    $carapace = $carapaceCmd.Source
}
if (-not $carapace) {
    $carapaceShim = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\carapace.exe"
    if (Test-Path $carapaceShim) { $carapace = $carapaceShim }
}

if ($carapace) {
    # Write UTF-8 *without BOM* in both PS 5.1 and PS 7+
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        # Preserves newlines and writes UTF-8 (no BOM) by default in PS7
        & $carapace _carapace nushell | Set-Content -Path $initNu -Encoding utf8 -Force
    }
    else {
        # Capture as lines, then join with CRLF and write as UTF-8 without BOM
        $lines = & $carapace _carapace nushell
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($initNu, ($lines -join "`r`n"), $utf8NoBom)
    }
    Write-Host "Successfully created ~\.cache\carapace\init.nu"
}
else {
    Write-Warning "carapace not found yet. You can re-run this section after the install step or start a new shell."
}

# Symlink config files
.\symlink.ps1

# Add kanata autostart
.\config\kanata\add_to_startup_windows.ps1
