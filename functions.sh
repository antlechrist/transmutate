# transmutate: functions.sh
get_field_names() {
	artist_name=`zenity --entry --title="$title" --text="$ask_artist" --entry-text="$artist_name"`
	album_name=`zenity --entry --title="$title" --text="$ask_album" --entry-text="$album_name"`
	album_date=`zenity --entry --title="$title" --text="$ask_date" --entry-text="$album_date"`
	song_name=`zenity --entry --title="$title" --text="$ask_song"`
	track_number=`zenity --entry --title="$title" --text="$ask_track"`
}

get_flac_quality() {
	zenity --title="$title" --list --radiolist --column="" --column="$ask_compression" FALSE "0" FALSE "1" FALSE "2" FALSE "3" FALSE "4" FALSE "5" FALSE "6" FALSE "7" TRUE "8"
}

get_mp3_quality() {
	zenity --title="$title" --list --radiolist --column="" --column="$ask_quality" FALSE "medium" FALSE "standard" TRUE "extreme" FALSE "insane"
}

get_ogg_quality() {
	zenity --title="$title" --list --radiolist --column="" --column="$ask_quality" -- "-1" FALSE "0" FALSE "1" FALSE "2" FALSE "3" FALSE "4" FALSE "5" FALSE "6" TRUE "7" FALSE "8" FALSE "9" FALSE "10"
}

get_quality() {
	if [ "$1" == "flac" ]; then
		quality="$(get_flac_quality)"
	fi
	if [ "$1" == "mp3" ]; then
		quality="$(get_mp3_quality)"
	fi
	if [ "$1" == "ogg" ]; then
		quality="$(get_ogg_quality)"
	fi
}

get_metatags() {
	if (is_flac "$1"); then
		artist_name=`metaflac --show-tag=artist "$1" | cut -d \= -f 2`
		album_name=`metaflac --show-tag=album "$1" | cut -d \= -f 2`
		album_date=`metaflac --show-tag=date "$1" | cut -d \= -f 2`
		song_name=`metaflac --show-tag=title "$1" | cut -d \= -f 2`
		track_number=`metaflac --show-tag=tracknumber "$1" | cut -d \= -f 2`
	fi
	if (is_mp3 "$1"); then
		artist_name=`id3info "$1" | awk '/TPE1/ { print substr($0, match($0, /:/) + 2 ) }'`
		album_name=`id3info "$1" | awk '/TALB/ { print substr($0, match($0, /:/) + 2 ) }'`
		album_date=`id3info "$1" | awk '/TDRC/ { print substr($0, match($0, /:/) + 2 ) }'`
		song_name=`id3info "$1" | awk '/TIT2/ { print substr($0, match($0, /:/) + 2 ) }'`
		track_number=`id3info "$1" | awk '/TRCK/ { print substr($0, match($0, /:/) + 2 ) }'`
	fi
	if (is_ogg "$1"); then
		artist_name=`ogginfo "$1" | grep artist | cut -d \= -f 2`
		album_name=`ogginfo "$1" | grep album | cut -d \= -f 2`
		album_date=`ogginfo "$1" | grep date | cut -d \= -f 2`
		song_name=`ogginfo "$1" | grep title | cut -d \= -f 2`
		track_number=`ogginfo "$1" | grep tracknumber | cut -d \= -f 2`
	fi
}

flac_set_tags() {
	if [ $pass_metatags -eq 0 ] || [ $fields -eq 0 ]; then
		if [ "$artist_name" ]; then
			metaflac --set-tag=ARTIST="$artist_name" "$1"
		fi
		if [ "$album_name" ]; then
			metaflac --set-tag=ALBUM="$album_name" "$1"
		fi
		if [ "$album_date" ]; then
			metaflac --set-tag=DATE="$album_date" "$1"
		fi
		if [ "$song_name" ]; then
			metaflac --set-tag=TITLE="$song_name" "$1"
		fi
		if [ "$track_number" ]; then
			metaflac --set-tag=TRACKNUMBER="$track_number" "$1"
		fi
	fi
}

mp3_parse_fields() {
	if [ "$artist_name" ]; then
		mp3_fields=(-a"$artist_name")
	fi
	if [ "$album_name" ]; then
		mp3_fields=("${mp3_fields[@]}" -A"$album_name")
	fi
	if [ "$album_date" ]; then
		mp3_fields=("${mp3_fields[@]}" -y"$album_date")
	fi
	if [ "$song_name" ]; then
		mp3_fields=("${mp3_fields[@]}" -s"$song_name")
	fi
	if [ "$track_number" ]; then
		mp3_fields=("${mp3_fields[@]}" -t"$track_number")
	fi
}

ogg_parse_fields() {
	if [ "$artist_name" ]; then
		ogg_fields=(-a "$artist_name")
	fi
	if [ "$album_name" ]; then
		ogg_fields=("${ogg_fields[@]}" -l "$album_name")
	fi
	if [ "$album_date" ]; then
		ogg_fields=("${ogg_fields[@]}" -d "$album_date")
	fi
	if [ "$song_name" ]; then
		ogg_fields=("${ogg_fields[@]}" -t "$song_name")
	fi
	if [ "$track_number" ]; then
		ogg_fields=("${ogg_fields[@]}" -N "$track_number")
	fi
}

is_mp3() {
	file -b "$1" | grep 'MP3' || echo $1 | grep -i '\.mp3$'
}

is_ogg() {
	file -b "$1" | grep 'Vorbis' || echo $1 | grep -i '\.ogg$'
}

is_flac() {
	file -b "$1" | grep 'FLAC' || echo $1 | grep -i '\.flac$'
}

is_wav() {
	file -b "$1" | grep 'WAVE' || echo $1 | grep -i '\.wav$'
}

flac_encode() {
	flac --compression-level-$quality "$2" -o "$3" 2>&1 \
		| awk -vRS='\r' -F':' '!/wrote/{gsub(/ /,"");if(NR>1)print $2; fflush();}' \
		| awk -F'%' '{print $1; fflush();}' \
		| zenity --progress --title="$title" --text="$conversion $1" --auto-close
}

mp3_encode() {
	lame -m auto --preset $quality "$2" "$3" 2>&1 \
		| awk -vRS='\r' '(NR>3){gsub(/[()%|]/," ");print $2; fflush();}' \
		| zenity --progress --title="$title" --text="$conversion $1" --auto-close
}

ogg_encode() {
	if [ $fields -eq 0 ] || [ $pass_metatags -eq 0 ]; then
		ogg_parse_fields
		oggenc "$2" "${ogg_fields[@]}" -q $quality -o "$3" 2>&1 \
			| awk -vRS='\r' '(NR>1){gsub(/%/," ");print $2; fflush();}' \
			| zenity --progress --title="$title" --text="$conversion $1" --auto-close
	else
		oggenc "$2" -q $quality -o "$3" 2>&1 \
			| awk -vRS='\r' '(NR>1){gsub(/%/," ");print $2; fflush();}' \
			| zenity --progress --title="$title" --text="$conversion $1" --auto-close
	fi
}

flac_decode() {
	temp_file=`echo "$1" | sed 's/\.\w*$/'.wav'/'`
	flac -d "$1" -o "$temp_file" 2>&1 \
		| awk -vRS='\r' -F':' '!/done/{gsub(/ /,"");gsub(/% complete/,"");if(NR>1)print $2; fflush();}' \
		| zenity --progress --title="$title" --text="$2 $1" --auto-close
}

mp3_decode() {
	temp_file=`echo "$1" | sed 's/\.\w*$/'.wav'/'`
	lame --decode "$1" "$temp_file" 2>&1 \
		| awk -vRS='\r' -F'[ /]+' '(NR>2){if((100*$2/$3)<=100)print 100*$2/$3; fflush();}' \
		| zenity --progress --title="$title" --text="$2 $1" --auto-close
}

ogg_decode() {
	temp_file=`echo "$1" | sed 's/\.\w*$/'.wav'/'`
	oggdec "$1" -o "$temp_file" 2>&1 \
		| awk -vRS='\r' '(NR>1){gsub(/%/," ");print $2; fflush();}' \
		| zenity --progress --title="$title" --text="$2 $1" --auto-close
}

ask_for_fields() {
	questions=("${questions[@]}" FALSE "$ask_fields")
}

ask_for_confirmation() {
	questions=("${questions[@]}" FALSE "$ask_confirmation_question")
}

ask_to_pass_metatags() {
	questions=(FALSE "$ask_to_pass")
}

question_list() {
	if [ "$formatout" == "mp3" ] || [ "$formatout" == "ogg" ] || [ "$formatout" == "flac" ]; then
		if (is_mp3 "$1") || (is_ogg "$1") || (is_flac "$1"); then
			ask_to_pass_metatags
		fi
		ask_for_fields
	fi
	if [ "$2" -gt 1 ]; then
		ask_for_confirmation
	fi
}

ask_questions() {
	repeat=1
	while [ $repeat -eq 1 ]; do
		answers=`zenity --list --checklist --column "" --column "$options" "${questions[@]}"`
		if (echo "$answers" | grep -i "$ask_to_pass") && (echo "$answers" | grep -i "$ask_fields"); then
			zenity --error --title="$warning" --text="$options_conflict"
			repeat=1
			continue
		fi
		repeat=0
	done
}

parse_questions() {
	if (echo "$answers" | grep -i "$ask_to_pass"); then
		pass_metatags=0
	else
		pass_metatags=1
	fi
	if (echo "$answers" | grep -i "$ask_fields"); then
		fields=0
	else
		fields=1
	fi
	if (echo "$answers" | grep -i "$ask_confirmation_question"); then
		confirmation_question=0
	else
		confirmation_question=1
	fi
}

completed_message() {
	zenity --info --title "$title" --text="$completed"
}

# convert audio file
caf() {
	if (is_flac "$1"); then
		if [ "$3" = "mp3" ]; then
			flac_decode "$1" "$decoding"
			mp3_encode "$1" "$temp_file" "$2"
			if [ $pass_metatags -eq 0 ]; then
				get_metatags "$1"
			elif [ $fields -eq 0 ]; then
				get_field_names "$1"
			fi
			if [ $pass_metatags -eq 0 ] || [ $fields -eq 0 ]; then
				mp3_parse_fields
				id3tag "${mp3_fields[@]}" "$2"
			fi
			rm -f "$temp_file"
			break
		fi
		if [ "$3" = "ogg" ]; then
			if [ $pass_metatags -eq 0 ]; then
				get_metatags "$1"
			elif [ $fields -eq 0 ]; then
				get_field_names "$1"
			fi
			flac_decode "$1" "$decoding"
			ogg_encode "$1" "$temp_file" "$2"
			rm -f "$temp_file"
			break
		fi
		if [ "$3" = "wav" ]; then
			flac_decode "$1" "$conversion"
		fi
		break
	fi
	if (is_mp3 "$1"); then
		if [ "$3" = "flac" ]; then
			mp3_decode "$1" "$decoding"
			flac_encode "$1" "$temp_file" "$2"
			if [ $pass_metatags -eq 0 ]; then
				get_metatags "$1"
			elif [ $fields -eq 0 ]; then
				get_field_names "$1"
			fi
			flac_set_tags "$2"
			rm -f "$temp_file"
			break
		fi
		if [ "$3" = "ogg" ]; then
			if [ $pass_metatags -eq 0 ]; then
				get_metatags "$1"
			elif [ $fields -eq 0 ]; then
				get_field_names "$1"
			fi
			mp3_decode "$1" "$decoding"
			ogg_encode "$1" "$temp_file" "$2"
			rm -f "$temp_file"
			break
		fi
		if [ "$3" = "wav" ]; then
			mp3_decode "$1" "$conversion"
		fi
		break
	fi
	if (is_ogg "$1"); then
		if [ "$3" = "flac" ]; then
			ogg_decode "$1" "$decoding"
			flac_encode "$1" "$temp_file" "$2"
			if [ $pass_metatags -eq 0 ]; then
				get_metatags "$1"
			elif [ $fields -eq 0 ]; then
				get_field_names "$1"
			fi
			flac_set_tags "$2"
			rm -f "$temp_file"
			break
		fi
		if [ "$3" = "mp3" ]; then
			ogg_decode "$1" "$decoding"
			mp3_encode "$1" "$temp_file" "$2"
			if [ $pass_metatags -eq 0 ]; then
				get_metatags "$1"
			elif [ $fields -eq 0 ]; then
				get_field_names "$1"
			fi
			if [ $pass_metatags -eq 0 ] || [ $fields -eq 0 ]; then
				mp3_parse_fields
				id3tag "${mp3_fields[@]}" "$2"
			fi
			rm -f "$temp_file"
			break
		fi
		if [ "$3" = "wav" ]; then
			ogg_decode "$1" "$conversion"
		fi
		break
	fi
	if (is_wav "$1"); then
		if [ "$3" = "flac" ]; then
			flac_encode "$1" "$1" "$2"
			if [ $fields -eq 0 ]; then
				get_field_names "$1"
			fi
			flac_set_tags "$2"
			break
		fi
		if [ "$3" = "mp3" ]; then
			mp3_encode "$1" "$1" "$2"
			if [ $fields -eq 0 ]; then
				get_field_names "$1"
				mp3_parse_fields
				id3tag "${mp3_fields[@]}" "$2"
				break
			fi
			break
		fi
		if [ "$3" = "ogg" ]; then
			if [ $fields -eq 0 ]; then
				get_field_names "$1"
			fi
			ogg_encode "$1" "$1" "$2"
			break
		fi
	fi
}
