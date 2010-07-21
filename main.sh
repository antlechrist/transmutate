# transmutate: main.sh
if [ $# -eq 0 ]; then
	zenity --error --title="$warning" --text="$noselec"
	exit 1
fi
if !(is_mp3 "$1") && !(is_ogg "$1") && !(is_flac "$1") && !(is_wav "$1"); then
	zenity --error --title="$warning" --text="$not_supported"
	exit 1
fi
depformat=""
if which lame 2>/dev/null; then
	if !(is_mp3 "$1"); then
		depformat="mp3"
	fi
else
	if (is_mp3 "$1"); then
		zenity --error --title="$warning" --text="$no_codec lame"
		exit 1
	fi
fi
if which oggenc 2>/dev/null; then
	if !(is_ogg "$1"); then 
		depformat="$depformat ogg"
	fi
else
	if (is_ogg "$1"); then
		zenity --error --title="$warning" --text="$no_codec vorbis-tools"
		exit 1
	fi
fi
if which flac 2>/dev/null; then
	if !(is_flac "$1"); then
		depformat="$depformat flac"
	fi
else
	if (is_flac "$1"); then
		zenity --error --title="$warning" --text="$no_codec flac"
		exit 1
	fi
fi
if !(is_wav "$1"); then
	depformat="$depformat wav"
fi

while [ ! "$formatout" ]; do
	formatout=`zenity --title "$title" --list --column="Format" $depformat --text "$choice"`
	if  [ $? != 0 ]; then
		exit 1
	fi
	[ $? -ne 0 ] && exit 2
done

# No more talkin', just bring it on!
question_list "$1" "$#"
ask_questions
parse_questions
if [ "$formatout" != "wav" ]; then
	get_quality "$formatout"
fi
file_number=$#
# This while loop was originally executed in a subshell... Reasoning?
# Phew! This is spaghetti! --A
while [ $# -gt 0 ]; do
	for i in $formatout; do
		in_file=$1
		out_file=`echo "$in_file" | sed 's/\.\w*$/'.$formatout'/'`
		i=`echo $i | sed 's/"//g'`
		while `true`; do
			if ls "$out_file" | grep -v "^ls"; then
				if !(`gdialog --title "$warning" --yesno "$out_file $proceed" 200 100`); then
					break
				fi
			fi
			if [ "$file_number" -gt 1 ] && [ "$confirmation_question" -eq 0 ]; then
				zenity --question --text="$confirmation $in_file in $out_file?"
				if [ $? -eq 1 ]; then
					break
				fi
			fi
			caf "$in_file" "$out_file" "$formatout"
			break
			shift
		done
	done
	shift
done
completed_message
