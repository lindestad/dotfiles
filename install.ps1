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
    "jftuga.less",
    "dandavison.delta",
    "Microsoft.PowerShell",
    "uutils.coreutils",
    "hrkfdn.ncspot",
    # Kanata is optional; installed only if selected
    # "jtroo.kanata_gui",
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
    Write-Host "Successfully created ~/.cache/carapace/init.nu"
}
else {
    Write-Warning "carapace not found yet. You can re-run this section after the install step or start a new shell."
}

function Prompt-YesNo([string]$Question) {
    while ($true) {
        $ans = Read-Host "$Question y/N"
        if ([string]::IsNullOrWhiteSpace($ans)) { return $false }
        switch -Regex ($ans) {
            '^[Yy]$' { return $true }
            '^[Nn]$' { return $false }
            default { Write-Host "Please answer y or n." }
        }
    }
}

# Optional: Kanata
$installKanata = Prompt-YesNo "Install Kanata (Keyboard remapping)?"
$chosenKanataCfg = $null
if ($installKanata) {
    winget install --id "jtroo.kanata_gui" --accept-source-agreements --accept-package-agreements -e

    $isoToAnsi = Prompt-YesNo "Remap ISO to ANSI like? Warning, remaps Enter key."
    $repo = Split-Path -Parent $MyInvocation.MyCommand.Definition
    if ($isoToAnsi) {
        $chosenKanataCfg = Join-Path $repo "config/kanata/config_iso_to_ansi.kbd"
    }
    else {
        $chosenKanataCfg = Join-Path $repo "config/kanata/config.kbd"
    }

    $appDataKanata = Join-Path $env:APPDATA "kanata"
    New-Item -ItemType Directory -Force -Path $appDataKanata | Out-Null
    $dstCfg = Join-Path $appDataKanata "config.kbd"
    # Create or update a symlink/junction for config; fallback to copy if not permitted
    try {
        if (Test-Path $dstCfg) { Remove-Item $dstCfg -Force }
        New-Item -ItemType SymbolicLink -Path $dstCfg -Target $chosenKanataCfg | Out-Null
    }
    catch {
        Copy-Item $chosenKanataCfg $dstCfg -Force
    }

    # Add kanata autostart
    .\config\kanata\add_to_startup_windows.ps1
}
else {
    Write-Host "Skipping Kanata install."
}

# --- Windows symlinks (inline, no external symlink.ps1) ---
function New-SafeLink {
    param(
        [Parameter(Mandatory)] [string]$Src,
        [Parameter(Mandatory)] [string]$Dst
    )
    $dstDir = Split-Path $Dst
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }

    $needsLink = $true
    if (Test-Path $Dst) {
        try {
            $existing = Get-Item $Dst -Force
            if ($existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $Src) {
                $needsLink = $false
            }
            else {
                Remove-Item $Dst -Force -Recurse
            }
        }
        catch {
            Remove-Item $Dst -Force -Recurse
        }
    }

    if ($needsLink) {
        try {
            New-Item -ItemType SymbolicLink -Path $Dst -Target $Src | Out-Null
        }
        catch {
            if (Test-Path $Src -PathType Container) {
                Copy-Item $Src $Dst -Recurse -Force
            }
            else {
                Copy-Item $Src $Dst -Force
            }
        }
        Write-Host "Linked $Src --> $Dst"
    }
    else {
        Write-Host "Already linked: $Dst"
    }
}

$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Definition
$UserHome = [Environment]::GetFolderPath('UserProfile')
$Roaming = [Environment]::GetFolderPath('ApplicationData')

# Links specific to Windows setup
New-SafeLink -Src (Join-Path $Dotfiles "config/helix/config.toml") -Dst (Join-Path $Roaming "helix/config.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/helix/languages.toml") -Dst (Join-Path $Roaming "helix/languages.toml")
New-SafeLink -Src (Join-Path $Dotfiles "shells/config.nu") -Dst (Join-Path $Roaming "nushell/config.nu")
New-SafeLink -Src (Join-Path $Dotfiles "config/starship/nushell/starship.toml") -Dst (Join-Path $UserHome ".config/starship.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/yazi") -Dst (Join-Path $Roaming "yazi/config")
New-SafeLink -Src (Join-Path $Dotfiles "config/ncspot/config.toml") -Dst (Join-Path $Roaming "ncspot/config.toml")

# Ensure ~/.gitconfig exists (copy, don't symlink)
$srcGitCfg = Join-Path $Dotfiles "config/git/gitconfig"
$dstGitCfg = Join-Path $UserHome ".gitconfig"
if (-not (Test-Path $dstGitCfg)) {
    if (Test-Path $srcGitCfg) {
        Copy-Item $srcGitCfg $dstGitCfg -Force
        Write-Host "Copied gitconfig to $dstGitCfg"
    }
    else {
        Write-Warning "Source gitconfig not found at $srcGitCfg"
    }
}
else {
    Write-Host "Existing ~/.gitconfig detected; leaving as-is."
}

Write-Host "Windows config links completed."
