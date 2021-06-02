# Golang Tools
if test -d $HOME/Tools/go/bin
  contains -- $HOME/Tools/go/bin $PATH; or set --append PATH $HOME/Tools/go/bin
  set --export --global GOROOT $HOME/Tools/go
end

if type -q go
  set --export --global GOPATH $HOME/go
  contains -- $GOPATH/bin $PATH; or set --append PATH $GOPATH/bin

  set --export --global GOVCS "private:git,public:off"
end
