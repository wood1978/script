#!/bin/bash

MODULE_JMYMH_REGEXP_URL="http://www.jmymh.com/"
JMYMH_BASE_SERVER1="http://comic.jmymh.com:2012"
JMYMH_BASE_SERVER2="http://lt.jmydm.jmmh.net:2012"
JMYMH_BASE_SERVER3="http://mh.jmmh.net:2012"
JMYMH_BASE_SERVER4="http://zj.jmmh.net"


jmymh_download()
{
	local URL="$1"
	local BASEHOST SERVER
	local DATA 
	local -a COMICS_LIST
	local PAGES PIC_NAME
	local PREFIX=""
	local idx

	BASEHOST=$(getHost "$URL")

	DATA=$(curl \
		-e "$BASEHOST" \
		-s \
		"$URL" | \
		iconv -c -f gb2312 -t utf8 | \
		sed -e '/sFiles/!d')

	if [ "x$DATA" == "x" ]; then
		echo "Downloading Failed."
		return 1
	fi

	COMICS_LIST=(`echo -e "$DATA" | \
			sed -e 's#.*sFiles="\(.*\)";var sPath=.*</script>#\1#' \
				-e 's=\r==g' \
				-e q | \
				tr '|' ' '`)

	SERVER=(`echo -e "$DATA" | \
			sed -e '/sFiles/!d' \
				-e 's#.*sFiles=".*";var sPath="\(.*\)";</script>#\1#' \
				-e 's=\r==g' \
				-e q`)

	if [ $AUTO_FOLDER -eq 1 ]; then
		PREFIX=$(echo "${SERVER}" | sed -e "s#\([^/]*/\)\{2\}\(.*\)/#\2#")
		mkdir -p "${OUTDIR}/${PREFIX}"
	fi

	GET_FILE_NAME="${PREFIX}"
	PAGES=${#COMICS_LIST[@]}
	echo "Saving to '${OUTDIR}/${PREFIX}'"

	echo -ne "Total $PAGES : Downloading 0"
	for ((idx=0;idx<${#COMICS_LIST[@]}; idx++)); do
		URL="${JMYMH_BASE_SERVER1}/${SERVER}/${COMICS_LIST[idx]}"
		PIC_NAME=$(getPicName "$((idx+1))" "${COMICS_LIST[idx]##*.}")
		if [ $idx -lt 10 ]; then
			echo -ne "\b$((idx+1))"
		elif [ $idx -lt 100 ]; then
			echo -ne "\b\b$((idx+1))"
		else
			echo -ne "\b\b\b$((idx+1))"
		fi
		curl -o "${OUTDIR}/${PREFIX}/${PIC_NAME}" \
			-e "${BASEHOST}" \
			-s \
			"$URL"
	done
	
	echo ""
	return 0
}
