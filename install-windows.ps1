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
    "oschwartz10612.Poppler",
    "GitHub.cli",
    "koalaman.shellcheck",
    "Nushell.Nushell",
    "Git.Git",
    "Schniz.fnm",
    "Python.Python.3.12",
    "astral-sh.uv",
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

function Get-WinGetLinkedCommand {
    param(
        [Parameter(Mandatory)] [string]$Name
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $shim = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\$Name.exe"
    if (Test-Path $shim) { return $shim }

    return $null
}

function Add-PowerShellProfileLine {
    param(
        [Parameter(Mandatory)] [string]$Line,
        [Parameter(Mandatory)] [string]$Pattern
    )

    $profilePath = $PROFILE.CurrentUserCurrentHost
    $profileDir = Split-Path $profilePath
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

    if (Test-Path $profilePath) {
        $existing = Get-Content $profilePath -Raw
        if ($existing -notmatch $Pattern) {
            Add-Content -Path $profilePath -Value "`n$Line`n"
        }
    }
    else {
        Set-Content -Path $profilePath -Value $Line
    }
}

function Enable-FnmPowerShellProfile {
    Add-PowerShellProfileLine -Line "fnm env --use-on-cd | Out-String | Invoke-Expression" -Pattern 'fnm env'
}

function Enable-StarshipPowerShellProfile {
    Add-PowerShellProfileLine -Line "if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell) }" -Pattern 'starship init powershell'
}

function Ensure-NodeLts {
    $fnm = Get-WinGetLinkedCommand -Name "fnm"
    if (-not $fnm) {
        Write-Warning "fnm not found yet. Start a new shell and run: fnm install --lts; fnm default lts-latest"
        return
    }

    $defaultNode = & $fnm default 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($defaultNode)) {
        & $fnm install --lts
        & $fnm default lts-latest
    }

    Enable-FnmPowerShellProfile
}

function Ensure-Pipx {
    $py = Get-Command "py" -ErrorAction SilentlyContinue
    $python = Get-Command "python" -ErrorAction SilentlyContinue
    $python312 = Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"

    if ($py) {
        & $py.Source -3.12 -m pip install --user pipx
        if ($LASTEXITCODE -ne 0) {
            & $py.Source -m pip install --user pipx
        }
        if ($LASTEXITCODE -eq 0) {
            & $py.Source -3.12 -m pipx ensurepath
            if ($LASTEXITCODE -ne 0) {
                & $py.Source -m pipx ensurepath
            }
        }
    }
    elseif (Test-Path $python312) {
        & $python312 -m pip install --user pipx
        if ($LASTEXITCODE -eq 0) {
            & $python312 -m pipx ensurepath
        }
    }
    elseif ($python) {
        & $python.Source -m pip install --user pipx
        if ($LASTEXITCODE -eq 0) {
            & $python.Source -m pipx ensurepath
        }
    }
    else {
        Write-Warning "Python not found yet. Start a new shell and run: py -3.12 -m pip install --user pipx; py -3.12 -m pipx ensurepath"
        return
    }

    $userScripts = Join-Path $env:APPDATA "Python\Python312\Scripts"
    $pipxBin = Join-Path $env:USERPROFILE ".local\bin"
    $env:Path = "$userScripts;$pipxBin;$env:Path"
}

Ensure-NodeLts
Ensure-Pipx
Enable-StarshipPowerShellProfile

function Set-WindowsTerminalGitBashDefault {
    $settingsPaths = @(
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
    )

    $gitBash = Join-Path $env:ProgramFiles "Git\bin\bash.exe"
    if (-not (Test-Path $gitBash)) {
        Write-Warning "Git Bash not found at $gitBash; Windows Terminal default profile was not changed."
        return
    }

    $profileGuid = "{4bf3b55f-8f52-45ff-93f8-5f4a191e3f3e}"
    foreach ($settingsPath in $settingsPaths) {
        if (-not (Test-Path $settingsPath)) { continue }

        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Could not parse Windows Terminal settings at $settingsPath"
            continue
        }

        if ($null -eq $settings.profiles) {
            $settings | Add-Member -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{ list = @() }) -Force
        }
        if ($null -eq $settings.profiles.list) {
            $settings.profiles | Add-Member -NotePropertyName list -NotePropertyValue @() -Force
        }
        if ($null -eq $settings.profiles.defaults) {
            $settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        if ($null -eq $settings.profiles.defaults.font) {
            $settings.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = "MesloLGS NF" }) -Force
        }
        else {
            $settings.profiles.defaults.font | Add-Member -NotePropertyName face -NotePropertyValue "MesloLGS NF" -Force
        }

        $profileList = @($settings.profiles.list)
        $profile = $profileList | Where-Object { $_.guid -eq $profileGuid -or $_.name -eq "Git Bash" } | Select-Object -First 1
        if (-not $profile) {
            $profile = [pscustomobject]@{
                guid = $profileGuid
                name = "Git Bash"
                commandline = "`"$gitBash`" -i -l"
                startingDirectory = "%USERPROFILE%"
                icon = "%PROGRAMFILES%\Git\mingw64\share\git\git-for-windows.ico"
                font = [pscustomobject]@{ face = "MesloLGS NF" }
            }
            $settings.profiles.list = @($profileList + $profile)
        }
        else {
            $profile | Add-Member -NotePropertyName guid -NotePropertyValue $profileGuid -Force
            $profile | Add-Member -NotePropertyName name -NotePropertyValue "Git Bash" -Force
            $profile | Add-Member -NotePropertyName commandline -NotePropertyValue "`"$gitBash`" -i -l" -Force
            $profile | Add-Member -NotePropertyName startingDirectory -NotePropertyValue "%USERPROFILE%" -Force
            $profile | Add-Member -NotePropertyName icon -NotePropertyValue "%PROGRAMFILES%\Git\mingw64\share\git\git-for-windows.ico" -Force
            if ($null -eq $profile.font) {
                $profile | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = "MesloLGS NF" }) -Force
            }
            else {
                $profile.font | Add-Member -NotePropertyName face -NotePropertyValue "MesloLGS NF" -Force
            }
        }

        $settings | Add-Member -NotePropertyName defaultProfile -NotePropertyValue $profileGuid -Force
        $settings | ConvertTo-Json -Depth 100 | Set-Content -Path $settingsPath -Encoding utf8
        Write-Host "Set Windows Terminal default profile to Git Bash in $settingsPath"
    }
}

function Install-UserFonts {
    param(
        [Parameter(Mandatory)] [string]$FontDir
    )

    if (-not (Test-Path $FontDir)) {
        Write-Warning "Font directory not found: $FontDir"
        return
    }

    $fontsDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Force -Path $fontsDir | Out-Null

    $registryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    $fontNames = @{
        "MesloLGS NF Regular.ttf"     = "MesloLGS NF Regular (TrueType)"
        "MesloLGS NF Bold.ttf"        = "MesloLGS NF Bold (TrueType)"
        "MesloLGS NF Italic.ttf"      = "MesloLGS NF Italic (TrueType)"
        "MesloLGS NF Bold Italic.ttf" = "MesloLGS NF Bold Italic (TrueType)"
    }

    foreach ($font in Get-ChildItem -Path $FontDir -Filter "*.ttf") {
        $destination = Join-Path $fontsDir $font.Name
        Copy-Item $font.FullName $destination -Force

        $registryName = $fontNames[$font.Name]
        if (-not $registryName) {
            $registryName = "$($font.BaseName) (TrueType)"
        }
        New-ItemProperty -Path $registryPath -Name $registryName -Value $destination -PropertyType String -Force | Out-Null
        Write-Host "Installed font $($font.Name)"
    }
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
$carapace = Get-WinGetLinkedCommand -Name "carapace"

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

Install-UserFonts -FontDir (Join-Path $Dotfiles "fonts")

# Links specific to Windows setup
New-SafeLink -Src (Join-Path $Dotfiles "config/helix/config.toml") -Dst (Join-Path $Roaming "helix/config.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/helix/languages.toml") -Dst (Join-Path $Roaming "helix/languages.toml")
New-SafeLink -Src (Join-Path $Dotfiles "shells/.bashrc") -Dst (Join-Path $UserHome ".bashrc")
New-SafeLink -Src (Join-Path $Dotfiles "shells/config.nu") -Dst (Join-Path $Roaming "nushell/config.nu")
New-SafeLink -Src (Join-Path $Dotfiles "config/starship/nushell/starship.toml") -Dst (Join-Path $UserHome ".config/starship.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/yazi") -Dst (Join-Path $Roaming "yazi/config")
New-SafeLink -Src (Join-Path $Dotfiles "config/ncspot/config.toml") -Dst (Join-Path $Roaming "ncspot/config.toml")
Set-WindowsTerminalGitBashDefault

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
