$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Definition
$UserHome = [Environment]::GetFolderPath('UserProfile')
$Roaming = [Environment]::GetFolderPath('ApplicationData')         # %AppData%
$Local = [Environment]::GetFolderPath('LocalApplicationData')      # %LocalAppData%

# Use array of objects to allow duplicate sources with different destinations
$Links = @(
    @{ Src = "$Dotfiles\config\helix\config.toml"; Dst = Join-Path $Roaming "helix\config.toml" },
    @{ Src = "$Dotfiles\config\helix\themes"; Dst = Join-Path $Roaming "helix\themes" },
    @{ Src = "$Dotfiles\shells\config.nu"; Dst = Join-Path $Roaming "nushell\config.nu" },
    @{ Src = "$Dotfiles\config\starship\starship.toml"; Dst = Join-Path $Local "clink\starship.lua" },       # For CMD/Clink
    @{ Src = "$Dotfiles\config\starship\starship.toml"; Dst = Join-Path $Roaming "starship\config.toml" },   # For Starship in PowerShell
    @{ Src = "$Dotfiles\config\yazi"; Dst = Join-Path $Roaming "yazi" }
    # @{ Src = "$Dotfiles\shells\.zshrc";                 Dst = Join-Path $UserHome ".zshrc" },
    # @{ Src = "$Dotfiles\shells\.bashrc";                Dst = Join-Path $UserHome ".bashrc" }
)

foreach ($item in $Links) {
    $src = $item.Src
    $dst = $item.Dst
    $dstDir = Split-Path $dst

    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    if (Test-Path $dst) {
        Remove-Item $dst -Force
    }

    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Host "Linked $dst ← $src"
}
