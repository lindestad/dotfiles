function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Administrator {
    if (Test-IsAdministrator) { return }

    $answer = Read-Host "This installer creates symlinks and works best as Administrator. Restart elevated now? Y/n"
    if ($answer -match '^[Nn]$') {
        Write-Warning "Continuing without elevation; symlink creation may fall back to copying files."
        return
    }

    $hostExe = (Get-Process -Id $PID).Path
    if (-not $hostExe) { $hostExe = "powershell.exe" }
    $scriptPath = $PSCommandPath
    $arguments = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    Start-Process -FilePath $hostExe -ArgumentList $arguments -Verb RunAs
    exit
}

Request-Administrator

$apps = @(
    "Helix.Helix",
    "Neovim.Neovim",
    "Starship.Starship",
    "eza-community.eza",
    "bootandy.dust",
    "BurntSushi.ripgrep.MSVC",
    "sharkdp.fd",
    "Gyan.FFmpeg",
    "7zip.7zip",
    "jqlang.jq",
    "sharkdp.fd",
    "sharkdp.bat",
    "junegunn.fzf",
    "ajeetdsouza.zoxide",
    "Clement.bottom",
    "ImageMagick.ImageMagick",
    "sxyazi.yazi",
    "oschwartz10612.Poppler",
    "GitHub.cli",
    "koalaman.shellcheck",
    "Git.Git",
    "Schniz.fnm",
    "Python.Python.3.12",
    "Typst.Typst",
    "astral-sh.uv",
    "jftuga.less",
    "dandavison.delta",
    "Microsoft.PowerShell",
    "uutils.coreutils",
    "wez.wezterm",
    # Kanata is optional; installed only if selected
    # "jtroo.kanata_gui",
    "rsteube.Carapace"
)

function Invoke-WinGetImport {
    param(
        [Parameter(Mandatory)] [string[]]$Packages
    )

    $uniquePackages = @($Packages | Select-Object -Unique)
    $importPath = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-winget-packages.json"
    $packageEntries = @($uniquePackages | ForEach-Object {
        [ordered]@{ PackageIdentifier = $_ }
    })

    $import = [ordered]@{
        '$schema' = "https://aka.ms/winget-packages.schema.2.0.json"
        CreationDate = (Get-Date).ToString("o")
        Sources = @(
            [ordered]@{
                Packages = $packageEntries
                SourceDetails = [ordered]@{
                    Argument = "https://cdn.winget.microsoft.com/cache"
                    Identifier = "Microsoft.Winget.Source_8wekyb3d8bbwe"
                    Name = "winget"
                    Type = "Microsoft.PreIndexed.Package"
                }
            }
        )
    }

    $import | ConvertTo-Json -Depth 8 | Set-Content -Path $importPath -Encoding utf8

    Write-Host ""
    Write-Host "==> Installing or upgrading $($uniquePackages.Count) winget packages" -ForegroundColor Cyan
    Write-Host "    Import manifest: $importPath"

    winget import -i $importPath `
        --ignore-unavailable `
        --ignore-versions `
        --accept-source-agreements `
        --accept-package-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "winget import exited with code $LASTEXITCODE"
    }
}

Invoke-WinGetImport -Packages $apps

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

function Ensure-UvTools {
    param(
        [Parameter(Mandatory)] [string[]]$Tools
    )

    $uv = Get-WinGetLinkedCommand -Name "uv"
    if (-not $uv) {
        $commands = ($Tools | ForEach-Object { "uv tool install --upgrade $_" }) -join "; "
        Write-Warning "uv not found yet. Start a new shell and run: $commands"
        return
    }

    foreach ($tool in $Tools) {
        Write-Host ""
        Write-Host "==> Installing/upgrading uv tool: $tool" -ForegroundColor Cyan
        & $uv tool install --upgrade $tool
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "uv tool install --upgrade $tool exited with code $LASTEXITCODE"
        }
    }

    $uvToolBin = Join-Path $env:USERPROFILE ".local\bin"
    $env:Path = "$uvToolBin;$env:Path"
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
            $settings.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = "MonaspiceNe Nerd Font" }) -Force
        }
        else {
            $settings.profiles.defaults.font | Add-Member -NotePropertyName face -NotePropertyValue "MonaspiceNe Nerd Font" -Force
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
                font = [pscustomobject]@{ face = "MonaspiceNe Nerd Font" }
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
                $profile | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = "MonaspiceNe Nerd Font" }) -Force
            }
            else {
                $profile.font | Add-Member -NotePropertyName face -NotePropertyValue "MonaspiceNe Nerd Font" -Force
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
    foreach ($font in Get-ChildItem -Path (Join-Path $FontDir "*") -Include "*.ttf", "*.otf" -File) {
        $destination = Join-Path $fontsDir $font.Name

        $fontType = if ($font.Extension -ieq ".otf") { "OpenType" } else { "TrueType" }
        $registryName = "$($font.BaseName) ($fontType)"

        try {
            if (Test-Path $destination) {
                Write-Host "Font already present: $($font.Name)"
            }
            else {
                Copy-Item $font.FullName $destination -Force -ErrorAction Stop
                Write-Host "Installed font $($font.Name)"
            }

            New-ItemProperty -Path $registryPath -Name $registryName -Value $destination -PropertyType String -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "Could not install font $($font.Name): $($_.Exception.Message)"
        }
    }
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
            New-Item -ItemType SymbolicLink -Path $Dst -Target $Src -ErrorAction Stop | Out-Null
            Write-Host "Linked $Src --> $Dst"
        }
        catch {
            Write-Warning "Could not create symlink $Dst; copying instead. $($_.Exception.Message)"
            try {
                if (Test-Path $Src -PathType Container) {
                    Copy-Item $Src $Dst -Recurse -Force -ErrorAction Stop
                }
                else {
                    Copy-Item $Src $Dst -Force -ErrorAction Stop
                }
                Write-Host "Copied $Src --> $Dst"
            }
            catch {
                Write-Warning "Could not copy $Src to $Dst. $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Host "Already linked: $Dst"
    }
}

function Ensure-GitBashProfile {
    param(
        [Parameter(Mandatory)] [string]$UserHome
    )

    $bashProfile = Join-Path $UserHome ".bash_profile"
    $bashLogin = Join-Path $UserHome ".bash_login"
    $profile = Join-Path $UserHome ".profile"
    $bashrc = Join-Path $UserHome ".bashrc"

    if ((Test-Path $bashProfile) -or (Test-Path $bashLogin) -or (Test-Path $profile)) {
        Write-Host "Existing Bash login profile detected; leaving as-is."
        return
    }

    if (-not (Test-Path $bashrc)) {
        Write-Warning "Cannot create ~/.bash_profile because ~/.bashrc does not exist yet."
        return
    }

    $content = @'
# Load interactive Bash config for Git Bash login shells.
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
'@
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($bashProfile, $content, $utf8NoBom)
    Write-Host "Created $bashProfile"
}

$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Definition
$UserHome = [Environment]::GetFolderPath('UserProfile')
$Roaming = [Environment]::GetFolderPath('ApplicationData')

Install-UserFonts -FontDir (Join-Path $Dotfiles "fonts")

# Links specific to Windows setup
New-SafeLink -Src (Join-Path $Dotfiles "config/codex/AGENTS.md") -Dst (Join-Path $UserHome ".codex/AGENTS.md")
New-SafeLink -Src (Join-Path $Dotfiles "config/alacritty/alacritty-windows.toml") -Dst (Join-Path $Roaming "alacritty/alacritty.toml")
$weztermConfig = Join-Path $Dotfiles "config/wezterm/wezterm-windows.lua"
New-SafeLink -Src $weztermConfig -Dst (Join-Path $UserHome ".wezterm.lua")
New-SafeLink -Src $weztermConfig -Dst (Join-Path $UserHome ".config/wezterm/wezterm.lua")
New-SafeLink -Src (Join-Path $Dotfiles "config/copilot/copilot-instructions.md") -Dst (Join-Path $UserHome ".copilot/copilot-instructions.md")
New-SafeLink -Src (Join-Path $Dotfiles "config/git/ignore") -Dst (Join-Path $UserHome ".config/git/ignore")
New-SafeLink -Src (Join-Path $Dotfiles "config/helix/config.toml") -Dst (Join-Path $Roaming "helix/config.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/helix/languages.toml") -Dst (Join-Path $Roaming "helix/languages.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/nvim") -Dst (Join-Path $UserHome ".config/nvim")
New-SafeLink -Src (Join-Path $Dotfiles "shells/.bashrc") -Dst (Join-Path $UserHome ".bashrc")
Ensure-GitBashProfile -UserHome $UserHome
New-SafeLink -Src (Join-Path $Dotfiles "config/starship/windows/starship.toml") -Dst (Join-Path $UserHome ".config/starship.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/yazi") -Dst (Join-Path $Roaming "yazi/config")
Set-WindowsTerminalGitBashDefault

function Merge-GitConfig {
    param(
        [Parameter(Mandatory)] [string]$Src,
        [Parameter(Mandatory)] [string]$Dst
    )

    if (-not (Test-Path $Src)) {
        Write-Warning "Source gitconfig not found at $Src"
        return
    }

    if (-not (Test-Path $Dst)) {
        Copy-Item $Src $Dst -Force
        Write-Host "Copied gitconfig to $Dst"
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "git not found; cannot merge gitconfig into $Dst"
        return
    }

    $entries = & git config --file $Src --list
    foreach ($entry in $entries) {
        $separator = $entry.IndexOf("=")
        if ($separator -lt 0) { continue }

        $key = $entry.Substring(0, $separator)
        $value = $entry.Substring($separator + 1)
        $existing = & git config --global --get $key 2>$null

        if ($LASTEXITCODE -eq 0) {
            $existingValue = $existing -join "`n"
            if ($existingValue -ne $value) {
                Write-Warning "~/.gitconfig already has $key=$existingValue; leaving desired value unapplied: $value"
            }
        }
        else {
            & git config --global $key $value
            Write-Host "Added git config $key"
        }
    }
}

function Ensure-CodexConfig {
    param(
        [Parameter(Mandatory)] [string]$Dst
    )

    $dir = Split-Path $Dst
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    if (-not (Test-Path $Dst)) {
        [System.IO.File]::WriteAllText($Dst, "", $utf8NoBom)
    }

    $content = Get-Content $Dst -Raw
    if ($null -eq $content) { $content = "" }
    $content = Ensure-TomlRootValue -Content $content -Key "default_permissions" -Value '":danger-full-access"' -Path $Dst
    $content = Ensure-TomlRootValue -Content $content -Key "approval_policy" -Value '"never"' -Path $Dst
    $content = Ensure-TomlTableValue -Content $content -Table "tui" -Key "vim_mode_default" -Value "true" -Path $Dst

    [System.IO.File]::WriteAllText($Dst, $content, $utf8NoBom)
}

function Ensure-TomlRootValue {
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Content,
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value,
        [Parameter(Mandatory)] [string]$Path
    )

    $line = "$Key = $Value"
    $match = [regex]::Match($Content, "(?m)^\s*$([regex]::Escape($Key))\s*=\s*(.+)$")
    if ($match.Success) {
        $existing = $match.Groups[1].Value.Trim()
        if ($existing -ne $Value) {
            Write-Warning "$Path already has $Key=$existing; leaving desired value unapplied: $Value"
        }
        return $Content
    }

    $tableMatch = [regex]::Match($Content, "(?m)^\s*\[")
    if ($tableMatch.Success) {
        $Content = $Content.Insert($tableMatch.Index, "$line`n")
    }
    elseif ($Content.EndsWith("`n")) {
        $Content = "$Content$line`n"
    }
    else {
        $Content = "$Content`n$line`n"
    }

    Write-Host "Added Codex config $Key"
    return $Content
}

function Ensure-TomlTableValue {
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Content,
        [Parameter(Mandatory)] [string]$Table,
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value,
        [Parameter(Mandatory)] [string]$Path
    )

    $escapedTable = [regex]::Escape($Table)
    $escapedKey = [regex]::Escape($Key)
    $tablePattern = "(?ms)^\s*\[$escapedTable\]\s*`$(.*?)(?=^\s*\[|\z)"
    $match = [regex]::Match($Content, $tablePattern)
    if ($match.Success) {
        $body = $match.Groups[1].Value
        $keyMatch = [regex]::Match($body, "(?m)^\s*$escapedKey\s*=\s*(.+)$")
        if ($keyMatch.Success) {
            $existing = $keyMatch.Groups[1].Value.Trim()
            if ($existing -ne $Value) {
                Write-Warning "$Path already has [$Table].$Key=$existing; leaving desired value unapplied: $Value"
            }
            return $Content
        }

        $headerEnd = $Content.IndexOf("`n", $match.Index)
        Write-Host "Added Codex TUI config $Key"
        if ($headerEnd -lt 0) {
            return "$Content`n$Key = $Value`n"
        }
        return $Content.Insert($headerEnd + 1, "$Key = $Value`n")
    }

    if (-not $Content.EndsWith("`n") -and $Content.Length -gt 0) {
        $Content = "$Content`n"
    }
    if ($Content.Length -gt 0 -and -not $Content.EndsWith("`n`n")) {
        $Content = "$Content`n"
    }

    Write-Host "Added Codex TUI config $Key"
    return "$Content[$Table]`n$Key = $Value`n"
}

# Ensure ~/.gitconfig exists and contains repo-managed defaults without overwriting user values
$srcGitCfg = Join-Path $Dotfiles "config/git/gitconfig"
$dstGitCfg = Join-Path $UserHome ".gitconfig"
Merge-GitConfig -Src $srcGitCfg -Dst $dstGitCfg

$dstCodexCfg = Join-Path $UserHome ".codex/config.toml"
Ensure-CodexConfig -Dst $dstCodexCfg

Ensure-UvTools -Tools @("ty", "ruff")

Write-Host "Windows config links completed."
