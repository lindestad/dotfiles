# Installing Starship

1. [Install Rust and Cargo](https://www.rust-lang.org/tools/install)
2. Install Starship
```
cargo install starship --locked
```
3. Configure Starship
```
mkdir -p ~/.config && touch ~/.config/starship.toml
code ~/.config/starship.toml
```
4. Copy over `starship.toml`
5. Optional: Install more tools
```
cargo install ripgrep bat fd-find zoxide hyperfine navi gping bottom onefetch
```