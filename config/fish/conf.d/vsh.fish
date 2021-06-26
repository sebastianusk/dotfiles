function vsh --description 'Vault SSH alias'
  vault ssh -role=sre -mode ca $argv;
end
