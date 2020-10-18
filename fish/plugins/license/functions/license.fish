function license -d "Generate License Text from Github API (requires jq)"
  set -l base_url https://api.github.com/licenses
  set -l headers 'Accept: application/vnd.github.v3+json'

  if test $argv[1]
    set -l license $argv[1]
    set -l res (curl --silent --header $headers $base_url/$license | jq .'body')
    echo -e $res | sed -e 's/^"//' -e 's/"$//'
  else
    set -l res (curl --silent --header $headers $base_url)
    echo "Choose from available Licenses: "
    echo
    echo "$res" | jq .[].'key' | sed -e 's/^"//' -e 's/"$//'
  end
end
