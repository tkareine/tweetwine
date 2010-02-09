_tweetwine_completion ()
{
    local cur prev cmds gopts
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmds="followers friends home mentions search update user"
    gopts="--auth --colors --num --no-colors --no-url-shorten --page --version"

    case "${prev}" in
    followers | friends | home | mentions | search | update | user)
        COMPREPLY=()
        ;;
    help)
        COMPREPLY=( $(compgen -W "${cmds}" -- ${cur}) )
        ;;
    *)
        if [[ "${cur}" == -* ]]; then
            COMPREPLY=( $(compgen -W "${gopts}" -- ${cur}) )
        else
            COMPREPLY=( $(compgen -W "${cmds} help" -- ${cur}) )
        fi
        ;;
    esac

    return 0
}

complete -F _tweetwine_completion tweetwine
