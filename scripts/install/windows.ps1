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

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$Dotfiles = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

function Write-Status {
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Message
    )

    Write-Information -MessageData $Message -InformationAction Continue
}

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
    "direnv.direnv",
    "Casey.Just",
    "mvdan.shfmt",
    "tamasfe.taplo",
    "MikeFarah.yq",
    "sharkdp.hyperfine",
    "Atuinsh.Atuin",
    "chmln.sd",
    "ducaale.xh",
    "dalance.procs",
    "Dystroy.broot",
    "JesseDuffield.lazygit",
    "StephanDilly.gitui",
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

    Write-Status ""
    Write-Status "==> Installing or upgrading $($uniquePackages.Count) winget packages"
    Write-Status "    Import manifest: $importPath"

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

function Enable-AtuinPowerShellProfile {
    Add-PowerShellProfileLine -Line "if (Get-Command atuin -ErrorAction SilentlyContinue) { atuin init powershell | Out-String | Invoke-Expression }" -Pattern 'atuin init powershell'
}

function Enable-UserLocalBinPowerShellProfile {
    Add-PowerShellProfileLine -Line '$userLocalBin = Join-Path $HOME ".local\bin"; if (Test-Path $userLocalBin) { $env:Path = "$userLocalBin;$env:Path" }' -Pattern '\.local\\bin'
}

function Install-NodeLtsVersion {
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

function Install-Pipx {
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

function Install-UvTool {
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
        Write-Status ""
        Write-Status "==> Installing/upgrading uv tool: $tool"
        & $uv tool install --upgrade $tool
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "uv tool install --upgrade $tool exited with code $LASTEXITCODE"
        }
    }

    $uvToolBin = Join-Path $env:USERPROFILE ".local\bin"
    $env:Path = "$uvToolBin;$env:Path"
}

function Install-PSScriptAnalyzer {
    $pwsh = Get-WinGetLinkedCommand -Name "pwsh"
    if (-not $pwsh) {
        Write-Warning "PowerShell 7 was installed but pwsh is not available yet. Start a new shell and run: Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"
        return
    }

    & $pwsh -NoProfile -NonInteractive -Command 'if (Get-Module -ListAvailable -Name PSScriptAnalyzer) { exit 0 }; exit 1'
    if ($LASTEXITCODE -eq 0) { return }

    Write-Status ""
    Write-Status "==> Installing PSScriptAnalyzer for the current user"
    & $pwsh -NoProfile -NonInteractive -Command 'Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -ErrorAction Stop'
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "PSScriptAnalyzer installation exited with code $LASTEXITCODE"
    }
}

function Install-Watchexec {
    param(
        [Parameter(Mandatory)] [string]$UserHome
    )

    if (Get-Command "watchexec" -ErrorAction SilentlyContinue) { return }

    $binDir = Join-Path $UserHome ".local\bin"
    $watchexecExe = Join-Path $binDir "watchexec.exe"
    if (Test-Path $watchexecExe) {
        $env:Path = "$binDir;$env:Path"
        return
    }

    try {
        Write-Status ""
        Write-Status "==> Installing watchexec from upstream release"
        New-Item -ItemType Directory -Force -Path $binDir | Out-Null

        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/watchexec/watchexec/releases/latest"
        $asset = $release.assets |
            Where-Object { $_.browser_download_url -match 'x86_64-pc-windows-msvc\.zip$' } |
            Select-Object -First 1
        if (-not $asset) {
            Write-Warning "Could not find a Windows watchexec release asset."
            return
        }

        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-watchexec-$([guid]::NewGuid().ToString('N'))"
        $zipPath = Join-Path $tmpDir "watchexec.zip"
        New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

        $exe = Get-ChildItem -Path $tmpDir -Recurse -Filter "watchexec.exe" | Select-Object -First 1
        if (-not $exe) {
            Write-Warning "watchexec.exe was not found in the release archive."
            return
        }

        Copy-Item $exe.FullName $watchexecExe -Force
        $env:Path = "$binDir;$env:Path"
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Could not install watchexec. $($_.Exception.Message)"
    }
}

function Install-BrootShellIntegration {
    param(
        [Parameter(Mandatory)] [string]$UserHome
    )

    $broot = Get-WinGetLinkedCommand -Name "broot"
    if (-not $broot) { return }

    $launcherDir = Join-Path $UserHome ".config/broot/launcher/bash"
    $launcher = Join-Path $launcherDir "br"
    New-Item -ItemType Directory -Force -Path $launcherDir | Out-Null

    $launcherContent = & $broot --print-shell-function bash 2>$null
    if ($LASTEXITCODE -eq 0 -and $launcherContent) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($launcher, (($launcherContent -join "`n") + "`n"), $utf8NoBom)
    }

    & $broot --set-install-state installed 2>$null | Out-Null
}

Install-NodeLtsVersion
Install-Pipx
Install-PSScriptAnalyzer
Enable-UserLocalBinPowerShellProfile
Enable-StarshipPowerShellProfile
Enable-AtuinPowerShellProfile

function Set-WindowsTerminalGitBashDefault {
    [CmdletBinding(SupportsShouldProcess)]
    param()

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

        if (-not $PSCmdlet.ShouldProcess($settingsPath, "Set Windows Terminal default profile to Git Bash")) {
            continue
        }

        $profileList = @($settings.profiles.list)
        $gitBashProfile = $profileList | Where-Object { $_.guid -eq $profileGuid -or $_.name -eq "Git Bash" } | Select-Object -First 1
        if (-not $gitBashProfile) {
            $gitBashProfile = [pscustomobject]@{
                guid = $profileGuid
                name = "Git Bash"
                commandline = "`"$gitBash`" -i -l"
                startingDirectory = "%USERPROFILE%"
                icon = "%PROGRAMFILES%\Git\mingw64\share\git\git-for-windows.ico"
                font = [pscustomobject]@{ face = "MonaspiceNe Nerd Font" }
            }
            $settings.profiles.list = @($profileList + $gitBashProfile)
        }
        else {
            $gitBashProfile | Add-Member -NotePropertyName guid -NotePropertyValue $profileGuid -Force
            $gitBashProfile | Add-Member -NotePropertyName name -NotePropertyValue "Git Bash" -Force
            $gitBashProfile | Add-Member -NotePropertyName commandline -NotePropertyValue "`"$gitBash`" -i -l" -Force
            $gitBashProfile | Add-Member -NotePropertyName startingDirectory -NotePropertyValue "%USERPROFILE%" -Force
            $gitBashProfile | Add-Member -NotePropertyName icon -NotePropertyValue "%PROGRAMFILES%\Git\mingw64\share\git\git-for-windows.ico" -Force
            if ($null -eq $gitBashProfile.font) {
                $gitBashProfile | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = "MonaspiceNe Nerd Font" }) -Force
            }
            else {
                $gitBashProfile.font | Add-Member -NotePropertyName face -NotePropertyValue "MonaspiceNe Nerd Font" -Force
            }
        }

        $settings | Add-Member -NotePropertyName defaultProfile -NotePropertyValue $profileGuid -Force
        $settings | ConvertTo-Json -Depth 100 | Set-Content -Path $settingsPath -Encoding utf8
        Write-Status "Set Windows Terminal default profile to Git Bash in $settingsPath"
    }
}

function Install-UserFont {
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
                Write-Status "Font already present: $($font.Name)"
            }
            else {
                Copy-Item $font.FullName $destination -Force -ErrorAction Stop
                Write-Status "Installed font $($font.Name)"
            }

            New-ItemProperty -Path $registryPath -Name $registryName -Value $destination -PropertyType String -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "Could not install font $($font.Name): $($_.Exception.Message)"
        }
    }
}

function Read-YesNo([string]$Question) {
    while ($true) {
        $ans = Read-Host "$Question y/N"
        if ([string]::IsNullOrWhiteSpace($ans)) { return $false }
        switch -Regex ($ans) {
            '^[Yy]$' { return $true }
            '^[Nn]$' { return $false }
            default { Write-Status "Please answer y or n." }
        }
    }
}

function Get-WindowsKeyboardLayoutEntry {
    param(
        [Parameter(Mandatory)] [string]$LayoutText,
        [Parameter(Mandatory)] [string]$LayoutFile
    )

    $layoutRoot = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts"
    try {
        foreach ($key in Get-ChildItem -Path $layoutRoot -ErrorAction Stop) {
            try {
                $props = Get-ItemProperty -Path $key.PSPath -ErrorAction Stop
            }
            catch {
                continue
            }

            if ($props."Layout Text" -eq $LayoutText -or $props."Layout File" -ieq $LayoutFile) {
                return [pscustomobject]@{
                    Key = $key.PSChildName
                    Text = $props."Layout Text"
                    File = $props."Layout File"
                }
            }
        }
    }
    catch {
        Write-Warning "Could not inspect installed keyboard layouts. $($_.Exception.Message)"
    }

    return $null
}

function Enable-WindowsKeyboardLayoutForUser {
    param(
        [Parameter(Mandatory)] [string]$LayoutKey
    )

    $getLanguageList = Get-Command Get-WinUserLanguageList -ErrorAction SilentlyContinue
    $setLanguageList = Get-Command Set-WinUserLanguageList -ErrorAction SilentlyContinue
    if (-not $getLanguageList -or -not $setLanguageList) {
        Write-Warning "Windows language-list cmdlets not found; install succeeded, but enable the US+NO keyboard layout manually."
        return
    }

    $tip = "0409:$($LayoutKey.ToUpperInvariant())"
    $languageList = Get-WinUserLanguageList
    $enUs = $languageList | Where-Object { $_.LanguageTag -eq "en-US" } | Select-Object -First 1
    if (-not $enUs) {
        Write-Warning "No en-US language entry found; install succeeded, but enable the US+NO keyboard layout manually."
        return
    }

    $existingTips = @($enUs.InputMethodTips)
    if ($existingTips | Where-Object { $_ -ieq $tip }) {
        Write-Status "US+NO keyboard layout is already enabled for en-US."
        return
    }

    try {
        $enUs.InputMethodTips.Add($tip)
    }
    catch {
        $enUs.InputMethodTips = @($existingTips + $tip)
    }

    Set-WinUserLanguageList -LanguageList $languageList -Force
    Write-Status "Enabled US+NO keyboard layout for en-US."
}

function Install-WindowsUsNoKeyboardLayout {
    param(
        [Parameter(Mandatory)] [string]$DotfilesDir
    )

    $layoutText = "US with Norwegian on alt gr layer"
    $layoutFile = "US+NO.dll"
    $entry = Get-WindowsKeyboardLayoutEntry -LayoutText $layoutText -LayoutFile $layoutFile
    if ($entry) {
        Write-Status "US+NO keyboard layout is already installed."
        Enable-WindowsKeyboardLayoutForUser -LayoutKey $entry.Key
        return
    }

    $layoutDir = Join-Path $DotfilesDir "keyboard_layouts/us+no"
    if (-not (Test-Path $layoutDir)) {
        Write-Warning "US+NO keyboard layout directory not found: $layoutDir"
        return
    }

    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        Write-Warning "US+NO layout artifacts do not include an ARM64 keyboard DLL; skipping layout install."
        return
    }

    $msiName = if ([Environment]::Is64BitOperatingSystem) { "US+NO_amd64.msi" } else { "US+NO_i386.msi" }
    $msi = Join-Path $layoutDir $msiName
    if (-not (Test-Path $msi)) {
        Write-Warning "US+NO keyboard layout installer not found: $msi"
        return
    }

    Write-Status ""
    Write-Status "==> Installing US+NO Windows keyboard layout"
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList @("/i", "`"$msi`"", "/qn", "/norestart") -Wait -PassThru
    if ($process.ExitCode -notin @(0, 3010)) {
        Write-Warning "US+NO keyboard layout install failed with msiexec exit code $($process.ExitCode)."
        return
    }

    $entry = Get-WindowsKeyboardLayoutEntry -LayoutText $layoutText -LayoutFile $layoutFile
    if (-not $entry) {
        Write-Warning "US+NO keyboard layout installer completed, but the layout was not found in the registry. You may need to restart Windows."
        return
    }

    Enable-WindowsKeyboardLayoutForUser -LayoutKey $entry.Key
    if ($process.ExitCode -eq 3010) {
        Write-Status "US+NO keyboard layout install requested a restart."
    }
}

if (Read-YesNo "Install US+NO Windows keyboard layout (AltGr Norwegian)?") {
    Install-WindowsUsNoKeyboardLayout -DotfilesDir $Dotfiles
}
else {
    Write-Status "Skipping US+NO keyboard layout install."
}

# Optional: Kanata
$installKanata = Read-YesNo "Install Kanata (Keyboard remapping)?"
$chosenKanataCfg = $null
if ($installKanata) {
    winget install --id "jtroo.kanata_gui" --accept-source-agreements --accept-package-agreements -e

    $isoToAnsi = Read-YesNo "Remap ISO to ANSI like? Warning, remaps Enter key."
    if ($isoToAnsi) {
        $chosenKanataCfg = Join-Path $Dotfiles "config/kanata/config_iso_to_ansi.kbd"
    }
    else {
        $chosenKanataCfg = Join-Path $Dotfiles "config/kanata/config.kbd"
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
    & (Join-Path $Dotfiles "scripts\install\kanata-windows-startup.ps1")
}
else {
    Write-Status "Skipping Kanata install."
}

# --- Windows symlinks (inline, no external symlink.ps1) ---
function New-SafeLink {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$Src,
        [Parameter(Mandatory)] [string]$Dst
    )

    if (-not (Test-Path $Src)) {
        Write-Warning "Missing source: $Src; skipping $Dst"
        return
    }

    if (-not $PSCmdlet.ShouldProcess($Dst, "Create link from $Src")) {
        return
    }

    $dstDir = Split-Path $Dst
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }

    $needsLink = $true
    if (Test-Path $Dst) {
        $existing = Get-Item $Dst -Force
        $linkTarget = @($existing.Target) -join ""
        $isManagedLink = $existing.LinkType -in @("SymbolicLink", "Junction")

        if ($isManagedLink -and $linkTarget -eq $Src) {
            $needsLink = $false
        }
        elseif ($isManagedLink) {
            Remove-Item $Dst -Force -Recurse
        }
        else {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $backup = "$Dst.bak.$timestamp"
            $suffix = 1
            while (Test-Path $backup) {
                $backup = "$Dst.bak.$timestamp.$suffix"
                $suffix++
            }

            Move-Item $Dst $backup -Force
            Write-Status "Backed up $Dst --> $backup"
        }
    }

    if ($needsLink) {
        try {
            New-Item -ItemType SymbolicLink -Path $Dst -Target $Src -ErrorAction Stop | Out-Null
            Write-Status "Linked $Src --> $Dst"
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
                Write-Status "Copied $Src --> $Dst"
            }
            catch {
                Write-Warning "Could not copy $Src to $Dst. $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Status "Already linked: $Dst"
    }
}

function Set-GitBashProfile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$UserHome
    )

    $bashProfile = Join-Path $UserHome ".bash_profile"
    $bashLogin = Join-Path $UserHome ".bash_login"
    $posixProfile = Join-Path $UserHome ".profile"
    $bashrc = Join-Path $UserHome ".bashrc"

    if ((Test-Path $bashProfile) -or (Test-Path $bashLogin) -or (Test-Path $posixProfile)) {
        Write-Status "Existing Bash login profile detected; leaving as-is."
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
    if ($PSCmdlet.ShouldProcess($bashProfile, "Create Bash login profile")) {
        [System.IO.File]::WriteAllText($bashProfile, $content, $utf8NoBom)
        Write-Status "Created $bashProfile"
    }
}

$UserHome = [Environment]::GetFolderPath('UserProfile')
$Roaming = [Environment]::GetFolderPath('ApplicationData')

Install-UserFont -FontDir (Join-Path $Dotfiles "fonts")
Install-Watchexec -UserHome $UserHome

# Links specific to Windows setup
New-SafeLink -Src (Join-Path $Dotfiles "config/atuin/config.toml") -Dst (Join-Path $UserHome ".config/atuin/config.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/atuin/themes") -Dst (Join-Path $UserHome ".config/atuin/themes")
$brootConfigDir = Join-Path $Roaming "dystroy/broot/config"
New-SafeLink -Src (Join-Path $Dotfiles "config/broot/conf.toml") -Dst (Join-Path $brootConfigDir "conf.toml")
New-SafeLink -Src (Join-Path $Dotfiles "config/broot/skins") -Dst (Join-Path $brootConfigDir "skins")
Install-BrootShellIntegration -UserHome $UserHome
New-SafeLink -Src (Join-Path $Dotfiles "config/codex/AGENTS.md") -Dst (Join-Path $UserHome ".codex/AGENTS.md")
New-SafeLink -Src (Join-Path $Dotfiles "config/codex/skills/gh-publish") -Dst (Join-Path $UserHome ".codex/skills/gh-publish")
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
Set-GitBashProfile -UserHome $UserHome
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
        Write-Status "Copied gitconfig to $Dst"
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
            Write-Status "Added git config $key"
        }
    }
}

function Set-CodexConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$Dst
    )

    if (-not $PSCmdlet.ShouldProcess($Dst, "Update Codex config")) {
        return
    }

    $dir = Split-Path $Dst
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    if (-not (Test-Path $Dst)) {
        [System.IO.File]::WriteAllText($Dst, "", $utf8NoBom)
    }

    $content = Get-Content $Dst -Raw
    if ($null -eq $content) { $content = "" }
    $content = Get-TomlRootValueContent -Content $content -Key "sandbox_mode" -Value '"danger-full-access"'
    $content = Get-TomlRootValueContent -Content $content -Key "approval_policy" -Value '"never"'
    $content = Get-TomlTableValueContent -Content $content -Table "tui" -Key "vim_mode_default" -Value "true"
    $content = Get-TomlTableValueContent -Content $content -Table "tui" -Key "status_line" -Value '["model-with-reasoning", "current-dir", "context-used", "five-hour-limit", "weekly-limit"]'
    $content = Get-TomlTableValueContent -Content $content -Table "tui" -Key "status_line_use_colors" -Value "true"
    $content = Get-TomlTableValueContent -Content $content -Table "tui" -Key "theme" -Value '"monokai-extended"'

    [System.IO.File]::WriteAllText($Dst, $content, $utf8NoBom)
}

function Get-TomlRootValueContent {
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Content,
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value
    )

    $line = "$Key = $Value"
    $match = [regex]::Match($Content, "(?m)^\s*$([regex]::Escape($Key))\s*=\s*(.+)$")
    if ($match.Success) {
        $existing = $match.Groups[1].Value.Trim()
        if ($existing -ne $Value) {
            Write-Status "Updated Codex config $Key"
            return $Content.Remove($match.Index, $match.Length).Insert($match.Index, $line)
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

    Write-Status "Added Codex config $Key"
    return $Content
}

function Get-TomlTableValueContent {
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Content,
        [Parameter(Mandatory)] [string]$Table,
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value
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
                Write-Status "Updated Codex TUI config $Key"
                $updatedBody = $body.Remove($keyMatch.Index, $keyMatch.Length).Insert($keyMatch.Index, "$Key = $Value")
                return $Content.Remove($match.Groups[1].Index, $match.Groups[1].Length).Insert($match.Groups[1].Index, $updatedBody)
            }
            return $Content
        }

        $headerEnd = $Content.IndexOf("`n", $match.Index)
        Write-Status "Added Codex TUI config $Key"
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

    Write-Status "Added Codex TUI config $Key"
    return "$Content[$Table]`n$Key = $Value`n"
}

# Ensure ~/.gitconfig exists and contains repo-managed defaults without overwriting user values
$srcGitCfg = Join-Path $Dotfiles "config/git/gitconfig"
$dstGitCfg = Join-Path $UserHome ".gitconfig"
Merge-GitConfig -Src $srcGitCfg -Dst $dstGitCfg

$dstCodexCfg = Join-Path $UserHome ".codex/config.toml"
Set-CodexConfig -Dst $dstCodexCfg

Install-UvTool -Tools @("ty", "ruff")

Write-Status "Windows config links completed."
