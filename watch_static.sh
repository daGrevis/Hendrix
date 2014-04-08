coffee --watch --compile static/scripts/ &
sass --watch static/styles/ &
read
trap 'kill $(jobs -p)' EXIT
