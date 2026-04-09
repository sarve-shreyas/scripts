loadenv() {
    export $(grep -v '^#' "$1" | xargs)
}

ecr_docker_login(){
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    export AWS_SESSION_TOKEN=

    aws_username=$1
    otp=$2

    if [ "$#" -ne 2 ]; then
      echo "Usage: bash ecr_docker_login \"<aws_username>\" \"<otp>\""
      return 1
    fi

    output=$(aws sts get-session-token --serial-number arn:aws:iam::737963123736:mfa/$aws_username --token-code $otp)

    export AWS_ACCESS_KEY_ID=$(echo $output | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $output | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $output | jq -r '.Credentials.SessionToken')

    docker_password=$(aws ecr get-login-password --region us-east-1)
    docker login --username AWS --password "$docker_password" 737963123736.dkr.ecr.us-east-1.amazonaws.com
}

env_activate() {
    local dir="$PWD"

    while :; do
        if [ -f "$dir/.venv/bin/activate" ]; then
            # shellcheck disable=SC1090
            source "$dir/.venv/bin/activate"
            return 0
        elif [ -f "$dir/venv/bin/activate" ]; then
            # shellcheck disable=SC1090
            source "$dir/venv/bin/activate"
            return 0
        elif [ -f "$dir/pyproject.toml" ] && command -v poetry >/dev/null 2>&1; then
            eval "$(cd "$dir" && poetry env activate)"
            return 0
        fi

        [ "$dir" = "/" ] && break
        dir="$(cd "$dir/.." && pwd)"
    done

    return 1
}

deploy() {
    local CURRENT_BRANCH=$(git_current_branch)
    local STAGE=false
    local PROD=false

    for arg in "$@"; do
        case $arg in
            --stage)
                STAGE=true
                ;;
            --prod)
                PROD=true
                ;;
            *)
                echo "Unknown option: $arg"
                return 1
                ;;
        esac
    done

    if $STAGE; then
        echo "Deploying staging env $CURRENT_BRANCH"
        local DEPLOY_BRANCH="$CURRENT_BRANCH-deploy"
        if [[ $CURRENT_BRANCH == *deploy ]] then
            DEPLOY_BRANCH="$CURRENT_BRANCH"
        else
            DEPLOY_BRANCH="$CURRENT_BRANCH-deploy"
            if git show-ref --verify --quiet refs/heads/$DEPLOY_BRANCH; then
                git branch -D $DEPLOY_BRANCH
            fi
            git branch $DEPLOY_BRANCH
        fi
        ssh stage-support "cd ctoi-tools.git && git branch -D $DEPLOY_BRANCH"
        git push stage $DEPLOY_BRANCH
    fi

    if $PROD; then
        echo "Production environment selected"
    fi
}

kill_on_port() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: kill_on_port <port1> [port2] ..."
        return 1
    fi

    for port in "$@"; do
        local pids
        pids=$(lsof -ti :"$port")
        if [[ -n "$pids" ]]; then
            kill -9 $pids 2>/dev/null
            echo "Killed process(es) on port $port (PID(s): $pids)"
        else
            echo "No process found on port $port"
        fi
    done
}

keti(){
    kubectl exec -it $1 -- bash
}

