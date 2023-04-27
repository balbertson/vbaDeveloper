#!/bin/bash
# This script creates a terminal prompt that will only accept y/n or yes/no (case insensitive).
# Until it gets one of those responses, it will repeat the prompt.
# Returns 0 for yes
# Returns 1 for no
# Returns 2 for error
response_code=2
while [ $response_code -eq 2 ]; do
    read -p "$* (y/n): " confirm
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
