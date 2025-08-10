$KanataExe = try { (Get-Command kanata_gui.exe -ErrorAction Stop).Source } catch { $null }

if ($KanataExe -and (Test-Path $KanataExe)) {
    $WScriptShell = New-Object -ComObject WScript.Shell
    # Prefer a user-configured link in %AppData%\kanata\config.kbd, else fall back to repo config
    $Roaming = [Environment]::GetFolderPath('ApplicationData')
    $UserCfg = Join-Path $Roaming "kanata\config.kbd"
    if (Test-Path $UserCfg) {
        $ConfigPath = $UserCfg
    }
    else {
        $RepoIso = "$HOME\dev\dotfiles\config\kanata\config_iso_to_ansi.kbd"
        $RepoAnsi = "$HOME\dev\dotfiles\config\kanata\config.kbd"
        if (Test-Path $RepoIso) { $ConfigPath = $RepoIso } else { $ConfigPath = $RepoAnsi }
    }

    $ArgString = "-c `"$ConfigPath`""

    # --- Startup Shortcut ---
    $StartupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    $StartupShortcut = Join-Path $StartupDir "Kanata.lnk"

    $NeedsStartupUpdate = $true
    if (Test-Path $StartupShortcut) {
        $ExistingShortcut = $WScriptShell.CreateShortcut($StartupShortcut)
        if ($ExistingShortcut.TargetPath -eq $KanataExe -and $ExistingShortcut.Arguments -eq $ArgString) {
            $NeedsStartupUpdate = $false
        }
    }

    if ($NeedsStartupUpdate) {
        $Shortcut = $WScriptShell.CreateShortcut($StartupShortcut)
        $Shortcut.TargetPath = $KanataExe
        $Shortcut.WorkingDirectory = Split-Path $KanataExe
        $Shortcut.Arguments = $ArgString
        $Shortcut.Save()
        Write-Host "Kanata startup shortcut created/updated."
    }
    else {
        Write-Host "Kanata startup shortcut already up to date."
    }

    # --- Start Menu Shortcut ---
    $ProgramsDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    $StartMenuShortcut = Join-Path $ProgramsDir "Kanata (with config).lnk"

    $NeedsStartMenuUpdate = $true
    if (Test-Path $StartMenuShortcut) {
        $ExistingShortcut = $WScriptShell.CreateShortcut($StartMenuShortcut)
        if ($ExistingShortcut.TargetPath -eq $KanataExe -and $ExistingShortcut.Arguments -eq $ArgString) {
            $NeedsStartMenuUpdate = $false
        }
    }

    if ($NeedsStartMenuUpdate) {
        $Shortcut = $WScriptShell.CreateShortcut($StartMenuShortcut)
        $Shortcut.TargetPath = $KanataExe
        $Shortcut.WorkingDirectory = Split-Path $KanataExe
        $Shortcut.Arguments = $ArgString
        $Shortcut.Save()
        Write-Host "Kanata start menu shortcut created/updated."
    }
    else {
        Write-Host "Kanata start menu shortcut already up to date."
    }

    Start-Sleep -Seconds 2
}
else {
    Write-Host "Kanata not found in PATH. Make sure it's installed via winget and on your PATH."
    Start-Sleep -Seconds 10
}
