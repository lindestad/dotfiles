$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Definition
$UserHome = [Environment]::GetFolderPath('UserProfile')
$Roaming = [Environment]::GetFolderPath('ApplicationData')         # %AppData%
$Local = [Environment]::GetFolderPath('LocalApplicationData')      # %LocalAppData%

# Use array of objects to allow duplicate sources with different destinations
$Links = @(
    @{ Src = "$Dotfiles\config\helix\config.toml"; Dst = Join-Path $Roaming "helix\config.toml" },
    @{ Src = "$Dotfiles\config\helix\languages.toml"; Dst = Join-Path $Roaming "helix\languages.toml" },
    @{ Src = "$Dotfiles\shells\config.nu"; Dst = Join-Path $Roaming "nushell\config.nu" },
    @{ Src = "$Dotfiles\config\starship\nushell\starship.toml"; Dst = Join-Path $UserHome ".config\starship.toml" },   # For Starship in PowerShell
    @{ Src = "$Dotfiles\config\yazi"; Dst = Join-Path $Roaming "yazi\config" }
    @{ Src = "$Dotfiles\config\ncspot\config.toml"; Dst = Join-Path $Roaming "ncspot\config.toml" }
    # @{ Src = "$Dotfiles\shells\.zshrc";                 Dst = Join-Path $UserHome ".zshrc" },
    # @{ Src = "$Dotfiles\shells\.bashrc";                Dst = Join-Path $UserHome ".bashrc" }
)

foreach ($item in $Links) {
    $src = $item.Src
    $dst = $item.Dst
    $dstDir = Split-Path $dst

    # Check and create source directory if it's a directory symlink
    $srcIsDir = Test-Path $src -PathType Container
    if ($srcIsDir -eq $false) {
        # If it's supposed to be a directory symlink but target dir doesn't exist, create it
        $srcIsProbablyDir = ($dst -match '\\config$' -or $dst -match '/config$' -or $dst -match '\\config\\' -or $dst -match '/config/')
        if ($srcIsProbablyDir -and -not (Test-Path $src)) {
            Write-Host "Source directory $src does not exist, creating it."
            New-Item -ItemType Directory -Path $src -Force | Out-Null
        }
    }

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
            Remove-Item $dst -Force -Recurse
        }
    }

    if ($needsLink) {
        New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
        Write-Host "Linked $src --> $dst"
    }
}
