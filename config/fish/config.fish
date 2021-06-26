set fish_greeting ""

set -gx VAULT_ADDR https://vault.service.fazz.id
set -gx CODE ~/Code
set -gx GOPATH $CODE/go
set -gx JDK_HOME /usr/lib/jvm/java-11-openjdk
set -gx JAVA_HOME $JDK_HOME
set -gx EDITOR 'nvim'
set -gx VISUAL 'nvim'
set -gx PAGER 'bat'
set -gx BROWSER 'vivaldi-stable'

fish_add_path -p $GOPATH/bin $HOME/.local/bin $HOME/.krew/bin
