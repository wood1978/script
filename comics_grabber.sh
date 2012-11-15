#!/bin/bash

absolute_path()
{
	TARGET=`readlink -f "$1"`
	RTARGET=$(dirname "$TARGET")
	echo $RTARGET
}

doDownload()
{
	local -a LINKS 
	local MODULE FUNCTION
	local ARG
	local RETVAL=$ARG_IS_ERR
	local -a OPTIONS=($@)
	local idx=0
	local marked=0

	OPTERR=0
	while getopts ":o:s:m" opt; do
		case $opt in
			o) # output dir
				OUTDIR="$OPTARG"
				if [ ! -d $OUTDIR ]; then
					echo "Directory '$OUTDIR' not exist. create."
					mkdir -p $OUTDIR
				fi
			;;

			m) # mark links when downloaded, valid for files.
				MARK=1
			;;
			
			s) # ssh tunnel
				TUNNEL="$OPTARG"
			;;

			:)
				echo "Option -$OPTARG requires an argument." >&2
				exit 1
			;;

			\?)
				echo "Invalid option: -$OPTARG" >&2
				exit 1
			;;
		esac
	done

	ARG="${OPTIONS[$((OPTIND-1))]}"

	$(isFileorURL "$ARG") || RETVAL=$?

	if [ $RETVAL -eq $ARG_IS_ERR ]; then
		echo "Argument error, must be file or url." >&2
		exit 1
	fi

	if [ $RETVAL -eq $ARG_IS_URL ]; then
		LINKS=("$ARG")
	else
		LINKS=(`cat "$ARG"`)
		AUTO_FOLDER=1
	fi

	for ((idx=0;idx<${#LINKS[@]};idx++)); do
		marked=$(isMarked "${LINKS[idx]}")
		if [ $marked -eq 0 ]; then
			MODULE=$(getModule "${LINKS[idx]}" "$MODULES")
			FUNCTION=${MODULE}_download
			echo "Downloading ... ${LINKS[idx]}"
			$FUNCTION "${LINKS[idx]}"
			if [ $MARK -eq 1 ]; then
				if [ $AUTO_FOLDER -eq 1 ]; then
					markQueue "${LINKS[idx]}" "${GET_FILE_NAME}" "$ARG"
				fi
			fi
		fi
	done
	
}

# MAIN
mscript="$0"

LIBDIR=$(absolute_path "$mscript")
MODULES=`ls "$LIBDIR/comics_grabber/modules"`
OUTDIR="."
MARK=0
AUTO_FOLDER=0
GET_FILE_NAME=""

source "$LIBDIR/comics_grabber/core.sh"

for i in $MODULES; do
	source "$LIBDIR/comics_grabber/modules/$i"
done

if [ $# -lt 1 ]; then
	echo ""
	echo "Usage: ${mscript##*/} [OPTIONS] [MODULE_OPTIONS] URL|FILE"
	echo ""
	echo "Download comics from online comics websites."
	echo `ls "$LIBDIR/modules" | sed -e 's/\.sh//g'`
	echo -e "$GLOBAL_OPS"
	exit 1
fi

MODULES=`ls "$LIBDIR/comics_grabber/modules" | sed -e 's/\.sh//g'`

doDownload "$@"

zip -r "$OUTDIR.zip" $OUTDIR
rm -rf "$OUTDIR"

