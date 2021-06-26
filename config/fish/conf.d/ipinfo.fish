function ipinfo --wraps='curl https://ipinfo.io/' --description 'alias ipinfo curl https://ipinfo.io/'
  curl https://ipinfo.io/$argv;
  echo
end
