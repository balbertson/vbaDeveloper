#!/bin/bash
# Source this file.
# It provides a set of functions that help the git processes here.

# The basis for messaging from the vbaDeveloper scripts.
# Takes any number of arguments and echoes them with formatting.
# The first arg can be a severity enumerator. If one isn't provided,
# the default severity is INFO.
# Enums: +0=INFO, +1=WARN, +2=ERROR
# Examples:
#   msg +2 "A problem occurred during operation."
#   msg "This is a friendly log entry."
function msg {
    #return if no args
    [ $# -eq 0 ] && return 1
    severity=""
    case "$1" in

        +1)
            severity="WARN"
            shift 1
            ;;
        +2)
            severity="ERROR"
            shift 1
            ;;
        +0)
            shift 1
            ;&
        *)
            severity="INFO"
    esac
            
    echo "${severity} | vbaDeveloper | ${*}"
}

function warn {
    msg "+1" "$*"
}

function error {
    msg "+2" "$*"
}

# This script creates a terminal prompt that will only accept y/n or yes/no (case insensitive).
# Until it gets one of those responses, it will repeat the prompt.
# Returns 0 for yes
# Returns 1 for no
# Returns 2 for error
function prompt-yn {
    response_code=2
    while [ $response_code -eq 2 ]; do
        confirm=$(prompt "$* (y/n):")
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            response_code=0
        elif [[ $confirm == [nN] || $confirm == [nN][oO] ]]; then
            response_code=1
        else
            echo "Please type 'y' or 'n'."
            response_code=2
        fi
    done
    return $response_code
}

# Create a read prompt that uses the msg formatting
function prompt {
    read -p "$(msg $*)" resp
    echo $resp
}