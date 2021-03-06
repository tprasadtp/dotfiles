# P0.Dependent: 00-fish-override.fish

if test -n "$FISH_SHELL_DEBUG_LOAD"
    printf "%s %s" "(date --rfc-3339=ns)" "(status --current-filename)"

end

# Golang Tools
# This is different from golang plugin as it overrides
# old go installed on NEMO
if test $NEMO_FISH_SHELL_SUPPORTED -eq 1
  if test -d $HOME/Tools/go/bin
    fish_add_path "$HOME/Tools/go/bin"
  end

  if type -q go
    set --export --global GOPATH $HOME/go
    fish_add_path $GOPATH/bin
    set --export --global GOVCS "private:git,public:off"
  end
end
