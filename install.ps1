$apps = @(
    "Helix.Helix",           # or custom install if not in winget
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
    "nushell.Nushell",
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
    & $carapace _carapace nushell | Out-File -FilePath $initNu -Encoding utf8 -Force
}
else {
    Write-Warning "carapace not found yet. You can re-run this section after the install step or start a new shell."
}

# Symlink config files
.\symlink.ps1
