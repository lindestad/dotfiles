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
    "jtroo.kanata_gui"
)

foreach ($app in $apps) {
    winget install --id $app --accept-source-agreements --accept-package-agreements -e
}

# Symlink config files
.\symlink.ps1
