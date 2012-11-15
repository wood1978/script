#!/bin/bash

USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:8.0a1) Gecko/2011071114 Firefox/8.0a1"

GLOBAL_OPS="\nGlobal options:\n\n \
-m : Mark downloaded links in (regular) FILE arguments.\n \
-o DIRECTORY : Directory where files will be saved.\n \
-s IP:PORT : socks4 ssh tunnel.\n \
"

ARG_IS_ERR=0
ARG_IS_FILE=1
ARG_IS_URL=2

uppercase()
{
	tr '[a-z]' '[A-Z]'
}

match()
{
	grep -q "$1" <<< "$2"
}

getModule()
{
	while read MODULE; do
		local M=$(uppercase <<< "$MODULE")
		local VAR="MODULE_${M}_REGEXP_URL"
		if match "${!VAR}" "$1"; then
			echo $MODULE
			break;
		fi
		done <<< "$2"
	return 0
}

getHost()
{
	sed -e 's#\(http://[^/]\+/\).*#\1#' <<< "$1"
}

getPicName()
{
	local INDEX="$1"
	local EXT="$2"
	if [ $INDEX -lt 10 ]; then
		echo "00${INDEX}.${EXT}"
	elif [ $INDEX -lt 100 ]; then
		echo "0${INDEX}.${EXT}"
	else
		echo "${INDEX}.${EXT}"
	fi
}

isFileorURL()
{
	local ARG="$1"
	test -e "$ARG" && return $ARG_IS_FILE
	grep -q "^http://" <<< "$ARG" && return $ARG_IS_URL
	return $ARG_IS_ERR
}

isMarked()
{
	grep -q "^#" <<< "$1"
	if [ $? -eq 1 ]; then
		echo 0
	else
		echo 1
	fi
}

markQueue()
{
	local PATTERN="$1"
	local NAME="$2"
	local FILE="$3"
	sed -i "s,${PATTERN},#${PATTERN}|${NAME}," "$FILE"
}


curl()
{
	local -a OPTIONS=(-L --retry 5 --retry-delay 5)
	local exist=0
	local idx=5

	if [ "x"$TUNNEL != "x" ]; then
		OPTIONS[$idx]='--socks4'
		idx=$((idx+1))
		OPTIONS[$idx]="$TUNNEL"
		idx=$((idx+1))
	fi

	for e; do
		if [ "$e" = '-A' -o "$e" = '--user-agent' ]; then
			exist=1
			break
		fi
	done

	if [ "$exist" -eq 0 ]; then
		OPTIONS[$idx]='--user-agent'
		idx=$((idx+1))
		OPTIONS[$idx]="$USER_AGENT"
		idx=$((idx+1))
	fi

	set $(type -P curl) "${OPTIONS[@]}" "$@"

	"$@"
}

