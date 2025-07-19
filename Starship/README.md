# Installing Starship

1. [Install Rust and Cargo](https://www.rust-lang.org/tools/install)
2. Install Starship

```bash
cargo install starship --locked
```

1. Configure Starship

```bash
mkdir -p ~/.config && touch ~/.config/starship.toml
code ~/.config/starship.toml
```bash

1. Copy over `starship.toml`
2. Optional: Install more tools

```bash
cargo install ripgrep bat fd-find zoxide hyperfine navi gping bottom onefetch
```
