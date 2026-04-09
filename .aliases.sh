alias export_env='set -o allexport; source <(grep -v "^#" ${1:-.env} | xargs); set +o allexport'

## Docker aliases
alias dev-docker-compose='docker-compose --file docker-compose.dev.yml'

## K8s aliases
alias k='kubectl'
alias kgp='k get pods'
alias kgn='k get namespaces'
alias kgs='k get services'

## Git aliases
alias gpoc='git push origin $(git_current_branch)'
alias gl='git clone'

alias rmr='rm -r'
alias t="todo.sh -d ~/.todo.cfg"

alias cd='z'

