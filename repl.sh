#!/bin/bash

set -uf -o pipefail

if [ "${REPL_EXIT_FUNCTIONS-x}" = "x" ]; then
	REPL_EXIT_FUNCTIONS=()
fi

unset -f REPL_EXIT_interrupt
REPL_EXIT_interrupt(){

	for i in ${REPL_EXIT_FUNCTIONS[@]}; do
		$i
	done

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

unset -f REPL_EXIT_addFunction
REPL_EXIT_addFunction(){
	if [ ! -z "${1:-}" ]; then
		REPL_EXIT_FUNCTIONS+=($1)
		echo "$FUNCNAME added $1 to exit handler."
	else 
		echo "$FUNCNAME FUNCTION"
		return 1
	fi
}


if [ "${ENV_VAR_LIST_FILE-x}" = "x" ]; then
	if [ -f "config.ini" ]; then
		. config.ini
	fi

	ENV_VAR_LIST_FILE=$(mktemp)
	compgen -A variable > $ENV_VAR_LIST_FILE

	trap REPL_EXIT_interrupt EXIT
	
	ENV_LAST_FILE=last.env

	if [ -f $ENV_LAST_FILE ]; then
		while false; do #disable resume
			echo "Resume previous session?"
			read -n 1 -p "y/n:" line
			echo
			case ${line,,} in
				y|yes)
					. $ENV_LAST_FILE
					break
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

line_old=
while read -e -p "$REPL_PROMPT>" line; do
	if [ ! -z "$line" ]; then
		if [ "$line" != "$line_old" ]; then
			line_old="$line"
			history -s "$line"
		fi
	fi
	case "$line" in
		"" | "help")
			compgen -A function | grep -v ^REPL_ | grep -v ^_
			;;
		reload)
			. $0
			break
			;;
		*)
			$line || echo "return code: $?"
			;;
	esac
done
