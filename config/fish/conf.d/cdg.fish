function cdg
  set -lx TOPLEVEL (git rev-parse --show-toplevel)
    if test $status -eq 0
      cd $TOPLEVEL
  end
end
