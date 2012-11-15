#!/bin/bash

MODULE_99MANGA_REGEXP_URL="http://dm.99manga.com/"

99manga_download()
{
	local URL="$1"
	local BASEHOST SERVER
	local DATA 
	local -a COMICS_LIST SERVER_LIST
	local SERVER_JS 
	local PAGES PIC_NAME
	local PREFIX=""
	local idx

	BASEHOST=$(getHost "$URL")
	SERVER=$(echo "$URL" | sed -e 's#[^?]\+?s=\([0-9]\+\)#\1#')

	DATA=$(curl \
		-e "$BASEHOST" \
		-s \
		"$URL" | \
		iconv -c -f gb2312 -t utf8 | \
		sed -e '/\(PicListUrl\|i.js\)/!d')

	if [ "x$DATA" == "x" ]; then
		echo "Downloading Failed."
		return 1
	fi

	COMICS_LIST=(`echo -e "$DATA" | \
			sed -e '/1/!d' \
				-e 's#var PicListUrl = "\([^"]\+\)";.*#\1#' \
				-e q | \
				tr '|' ' '`)
	SERVER_JS=$(echo -e "$DATA" | \
			sed -e '/1/d' \
				-e 's#<script src=\([^>]\+\)></script>.*#\1#')

	SERVER_LIST=($(curl \
			-e "$BASEHOST" \
			-s \
			"${BASEHOST}${SERVER_JS}" | \
			sed -e '/ServerList\[[0-9]\+\]/!d' \
				-e 's#ServerList\[[0-9]\+\]="\([^"]\+\)";.*#\1#'))

	if [ $AUTO_FOLDER -eq 1 ]; then
		PREFIX=$(echo "${COMICS_LIST[0]}" | sed -e "s#.*/\([^/]\+\)/[^/]\+\$#\1#")
		mkdir -p "${OUTDIR}/${PREFIX}"
	fi
	GET_FILE_NAME="${PREFIX}"
	PAGES=${#COMICS_LIST[@]}
	echo "Saving to '${OUTDIR}/${PREFIX}'"

	echo -ne "Total $PAGES : Downloading 0"
	for ((idx=0;idx<${#COMICS_LIST[@]}; idx++)); do
		URL="${SERVER_LIST[$((SERVER-1))]}${COMICS_LIST[idx]}"
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
