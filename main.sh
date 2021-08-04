: "${1?"Usage: $0 nick [directory=/var/log/irc] [server=irc.freenode.net] [port=6667]"}"

DIR="${2:-/var/log/irc}"
SERVER="${3:-irc.freenode.net}"
STDIN="${DIR}/${SERVER}.input"
mkdir -p "${DIR}/${SERVER}"
printf 'NICK %s\r\nUSER %s localhost * :%s\r\n' "${1}" "${1}" "${1}" > "$STDIN"
JOINCHAN() {
    truncate -s 0 "${DIR}/${SERVER}/${1}.input"
    touch "${DIR}/${SERVER}/${1}.log"
    (tail -f "${DIR}/${SERVER}/${1}.input" | while IFS= read -r message ; do
        printf 'PRIVMSG #%s :%s\r\n' "${1}" "$message"
    done) >> "${STDIN}"
}
(tail -f "$STDIN" | while IFS= read -r command ; do
    case "$command" in
        /join*) # Create files on join
            JOINCHAN "${command#* #}" &
            printf '%s\r\n' "${command#/}"
            ;;
        /*) # Support commands
            printf '%s\r\n' "${command#/}"
            ;;
        *) # Everything else pass along unfiltered to the connection
            printf '%s\r\n' "${command}"
            ;;
    esac
done) | nc "$SERVER" "${4:-6667}" | while IFS= read -r line; do
    LINE="${line#:* }" # Remove a prefix if one exists
    case ${LINE} in
        'PRIVMSG'*)
            CHANNEL="${LINE#PRIVMSG #}" # remove command and hashtag
            CHANNEL="${CHANNEL%% *}" # second word is channel name, cut off everything else
            FILE="${DIR}/${SERVER}/${CHANNEL}.log"
            ([ -f "${FILE}" ] && printf '%s\r\n' "$line" >> "${FILE}") || printf '%s\r\n' "$line" >> "${DIR}/${SERVER}.log"
            ;;
        'JOIN'*)
            CHANNEL="${LINE#JOIN #}" # only two words, second word is channel name
            FILE="${DIR}/${SERVER}/${CHANNEL}.log"
            ([ -f "${FILE}" ] && printf '%s\r\n' "$line" >> "${FILE}") || printf '%s\r\n' "$line" >> "${DIR}/${SERVER}.log"
            ;;
        'QUIT'*)
            CHANNEL="${LINE#QUIT #}" # only two words, second word is channel name
            FILE="${DIR}/${SERVER}/${CHANNEL}.log"
            ([ -f "${FILE}" ] && printf '%s\r\n' "$line" >> "${FILE}") || printf '%s\r\n' "$line" >> "${DIR}/${SERVER}.log"
            ;;
        'PING '*)
            printf 'PONG\r\n' >> "${STDIN}" # Ping/Pong to keep session alive
            ;;
        *)
            printf '%s\r\n' "$line" >> "${DIR}/${SERVER}.log" # All other messages go into server logs
            ;;
    esac
done
