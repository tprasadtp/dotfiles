# Appase starship to show hostname if in a job
if contains nemo (hostname -fqdn)
  if not set -q SSH_CONNECTION
    set --export --global SSH_CONNECTION
  end
end
