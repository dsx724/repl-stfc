#!/bin/bash

unset exit_routine
exit_routine(){
	for i in $(compgen -A variable | grep -Fxvf $ENV_VAR_LIST_FILE | grep -v "[[:lower:]]"); do
		case $i in
			ENV_LAST_FILE | ENV_VAR_LIST_FILE | FUNCNAME | COLUMNS | LINES)
				continue;
				;;
		esac
		echo "$i=${!i}" >> last.env
	done
	rm $ENV_VAR_LIST_FILE
}

if [ -z "$ENV_VAR_LIST_FILE" ]; then
	if [ -f "config.ini" ]; then
		. config.ini
	fi

	ENV_VAR_LIST_FILE=$(mktemp)
	compgen -A variable > $ENV_VAR_LIST_FILE
	trap exit_routine EXIT
	
	ENV_LAST_FILE=last.env
	if [ -f $ENV_LAST_FILE ]; then
		while true; do
			echo "Resume previous session?"
			read -n 1 -p "y/n:" line
			echo
			case ${line,,} in
				y|yes)
					. $ENV_LAST_FILE
					;;
				n|no)
					break
					;;
			esac
		done
		rm $ENV_LAST_FILE
	fi
fi

. include.sh

while read -e -p "$REPL_PROMPT>" line; do
	history -s "$line"
	case "$line" in
		"" | "help")
			compgen -A function | grep -v exit_routine | grep -v ^_
			;;
		reload)
			. $0
			break
			;;
		*)
			$line
			;;
	esac
done
