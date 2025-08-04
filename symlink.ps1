$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Definition
$UserHome = [Environment]::GetFolderPath('UserProfile')
$Roaming = [Environment]::GetFolderPath('ApplicationData')         # %AppData%
$Local = [Environment]::GetFolderPath('LocalApplicationData')      # %LocalAppData%

# Use array of objects to allow duplicate sources with different destinations
$Links = @(
    @{ Src = "$Dotfiles\config\helix\config.toml"; Dst = Join-Path $Roaming "helix\config.toml" },
    @{ Src = "$Dotfiles\config\helix\languages.toml"; Dst = Join-Path $Roaming "helix\languages.toml" },
    @{ Src = "$Dotfiles\shells\config.nu"; Dst = Join-Path $Roaming "nushell\config.nu" },
    @{ Src = "$Dotfiles\config\starship\nushell\starship.toml"; Dst = Join-Path $Roaming "starship\config.toml" },   # For Starship in PowerShell
    @{ Src = "$Dotfiles\config\yazi"; Dst = Join-Path $Roaming "yazi\config" }
    @{ Src = "$Dotfiles\config\ncspot\config.toml"; Dst = Join-Path $Roaming "ncspot\config.toml" }
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

    $needsLink = $true
    if (Test-Path $dst) {
        try {
            $existing = Get-Item $dst -Force
            if ($existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $src) {
                Write-Host "Already linked: $dst -> $src"
                $needsLink = $false
            }
            else {
                Remove-Item $dst -Force -Recurse
            }
        }
        catch {
            # Just in case it's not a link and throws during Get-Item.Target
            Remove-Item $dst -Force -Recurse
        }
    }

    if ($needsLink) {
        New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
        Write-Host "Linked $src --> $dst"
    }
}
