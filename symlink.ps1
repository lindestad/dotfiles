$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Definition
# $Home = [Environment]::GetFolderPath('UserProfile')
$Roaming = [Environment]::GetFolderPath('ApplicationData')     # %AppData%
$Local = [Environment]::GetFolderPath('LocalApplicationData') # %LocalAppData%

$Links = @{
    "$Dotfiles\config\helix\config.toml"      = Join-Path $Roaming "helix\config.toml"
    "$Dotfiles\config\helix\themes"           = Join-Path $Roaming "helix\themes"
    "$Dotfiles\shells\config.nu"              = Join-Path $Roaming "nushell\config.nu"
    "$Dotfiles\config\starship\starship.toml" = Join-Path $Local "clink\starship.lua"  # For cmd
    "$Dotfiles\config\starship\starship.toml" = Join-Path $Roaming "starship\config.toml"
    "$Dotfiles\config\yazi"                   = Join-Path $Roaming "yazi"
    # "$Dotfiles\shells\.zshrc"                 = Join-Path $Home ".zshrc"
    # "$Dotfiles\shells\.bashrc"                = Join-Path $Home ".bashrc"
}

foreach ($src in $Links.Keys) {
    $dst = $Links[$src]
    $dir = Split-Path $dst
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $dst) { Remove-Item $dst -Force }
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Host "Linked $dst --> $src"
}
