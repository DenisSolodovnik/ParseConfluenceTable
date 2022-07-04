RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

if [ "$#" = 0 ] || [ "$#" = 1 ]
then
    echo "${RED}No parameters!${NC}"
    echo "${ORANGE}Usage: ${0##*/} <name> <password>${NC}"
    exit 1
fi

spinner()
{
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "%c" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
}

tput civis

(wiki_result=$(ruby Scripts_colors_from_wiki.rb $1 $2 285120258 ../Nomerogram/Sources/Constants/Colors.json)) & spinner
(json_result=$(ruby Scripts_colors_from_json.rb ../Nomerogram/Sources/Constants/Colors.json ../Nomerogram/Sources/Constants/ Colors NomerogramColors)) & spinner

tput cnorm

if [ "$wiki_result" = "" ] && [ "$json_result" = "" ]
then
	echo "${GREEN}Color data updated successfuly!${NC}"
else
	echo "${RED}Fatal! Something went wrong!${NC}"
    echo "${ORANGE}Parse wiki error: ${wiki_result}${NC}"
    echo "${ORANGE}Parse json error: ${json_result}${NC}"
fi
