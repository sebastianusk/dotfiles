function dns --description 'change the dns using 0.0.0.0'
  nmcli con mod $argv ipv4.ignore-auto-dns yes
  nmcli con mod $argv ipv4.dns "0.0.0.0"
  nmcli con down $argv
  nmcli con up $argv
end
