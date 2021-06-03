# Override default Paths
set --export --global CARGO_HOME $HOME/Tools/Rust/cargo
set --export --global RUSTUP_HOME $HOME/Tools/Rust/rustup

# If installed, add rustup proxies to PATH
if test -d $HOME/Tools/Rust/cargo/bin
  contains -- $HOME/Tools/Rust/cargo/bin $PATH; or set --append PATH $HOME/Tools/Rust/cargo/bin
end
