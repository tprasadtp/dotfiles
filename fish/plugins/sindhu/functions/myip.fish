# Terminal Services
function myip -d "Display your Public IP address"
  set -l ipv4 (dig @1.1.1.1 whoami.cloudflare ch txt +short)
  set -l ipv6 (dig @2606:4700:4700::1111 whoami.cloudflare ch txt -6 +short)
  printf "IPv4: \033[92m $ipv4\e[0m\n";
  printf "IPv6: \033[92m $ipv6\e[0m\n"
end
