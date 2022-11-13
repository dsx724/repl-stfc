unset -f XWindow_getId
XWindow_getId(){
	echo $X_WINDOW_ID	
}

unset -f XWindow_setId
XWindow_setId(){
	X_WINDOW_ID=$(xwininfo | grep -o "Window id: 0x[0-9a-f]\+" | cut -f 3 -d " ")
	XWindow_getId
}

unset -f XWindow_checkId
XWindow_checkId(){
	if [ -z "$X_WINDOW_ID" ]; then
		echo "$FUNCNAME XWindow_setId" >&2
		XWindow_setId
	fi
	xprop -id $X_WINDOW_ID > /dev/null
	if [ $? -ne 0 ]; then
		echo "$FUNCNAME XWindow does not exist.">&2
		X_WINDOW_ID=
		return 1
	fi
}

unset -f _XWindow_calibrate
_XWindow_calibrate(){
	XWindow_checkId || return 1
	xwd -id $X_WINDOW_ID | convert xwd:- -format "%w %h " -write info:- -trim -format "%w %h %@" info:-
}

unset -f XWindow_calibrate
XWindow_calibrate(){
	local X_WINDOW_DIM=($(_XWindow_calibrate))
	X_WINDOW_WIDTH=${X_WINDOW_DIM[0]}
	X_WINDOW_HEIGHT=${X_WINDOW_DIM[1]}
	X_WINDOW_FRAME_WIDTH=${X_WINDOW_DIM[2]}
	X_WINDOW_FRAME_HEIGHT=${X_WINDOW_DIM[3]}
	X_WINDOW_FRAME_OFFSET_X=$(((${X_WINDOW_DIM[0]} - ${X_WINDOW_DIM[2]})/2))
	X_WINDOW_FRAME_OFFSET_Y=$(((${X_WINDOW_DIM[1]} - ${X_WINDOW_DIM[3]})/2))
	X_WINDOW_GEOMETRY=${X_WINDOW_DIM[4]}
	echo "${X_WINDOW_WIDTH}x${X_WINDOW_HEIGHT} $(XWindow_getCropGeometry) ${X_WINDOW_GEOMETRY}"
	XWindow_display
}

unset -f XWindow_getInfo
XWindow_getInfo(){
	if [ -z "$X_WINDOW_ID" ]; then
		echo "$FUNCNAME XWindow_setId"
		XWindow_setId
	fi
	xprop -id $X_WINDOW_ID
}

unset -f XWindow_getCropGeometry
XWindow_getCropGeometry(){
	echo -n "${X_WINDOW_FRAME_WIDTH}x${X_WINDOW_FRAME_HEIGHT}+${X_WINDOW_FRAME_OFFSET_X}+${X_WINDOW_FRAME_OFFSET_Y}"
}

unset -f _XWindow_get
_XWindow_get(){
	XWindow_checkId || return 1
	if [ -z "${1-}" ]; then
		output_format=miff
	else
		output_format=${1}
	fi
	if [ "${X_WINDOW_LOCK:-0}" -eq 1 ]; then
		convert xwd:$X_WINDOW_TMP_FILE -crop $(XWindow_getCropGeometry) +repage ${@:2} $output_format:-
	else
		xwd -id $X_WINDOW_ID | tee $X_WINDOW_TMP_FILE | convert xwd:- -crop $(XWindow_getCropGeometry) +repage ${@:2} $output_format:-
	fi
}

unset -f _XWindow_lock
_XWindow_lock(){
	X_WINDOW_LOCK=1
}

unset -f _XWindow_unnlock
_XWindow_unlock(){
	X_WINDOW_LOCK=
}

unset -f XWindow_display
XWindow_display(){
	_XWindow_get miff $@ | DISPLAY=${X_WINDOW_DISPLAY_HOST:-$DISPLAY} convert miff:- x:- &
}

unset -f XWindow_displayLast
XWindow_displayLast(){
	if [ ! -z "$X_WINDOW_BACKGROUND_PID" ]; then
		kill $X_WINDOW_BACKGROUND_PID
		X_WINDOW_BACKGROUND_PID=
	fi
	DISPLAY=${X_WINDOW_DISPLAY_HOST:-$DISPLAY} display -update 1 -resize 1920x1080 xwd:$X_WINDOW_TMP_FILE -crop $(XWindow_getCropGeometry) &
	X_WINDOW_BACKGROUND_PI=$!
}

unset -f XWindow_getCroppedPixel
XWindow_getCroppedPixel(){
	if [ -z "${2:-}" -o -z "${3:-}" ]; then
		echo "$FUNCNAME FORMAT WIDTH HEIGHT [+-XOFFSET] [+-YOFFSET] [ADDITIONAL]" >&2
		return 1
	fi
	width=${2}
	if [ "$width" -eq 0 ]; then
		echo "$FUNCNAME below min width." >&2
		width=1
	fi
	height=${3}
	if [ "$height" -eq 0 ]; then
		echo "$FUNCNAME below min height." >&2
		height=1
	fi

	x_offset=${4:-+0}
	if [[ $x_offset =~ ^[0-9] ]]; then
		x_offset=+$x_offset
	fi
	y_offset=${5:-+0}
	if [[ $y_offset =~ ^[0-9] ]]; then
		y_offset=+$y_offset
	fi
	
	if [ "$x_offset" -ge $X_WINDOW_FRAME_WIDTH ]; then
		echo "$FUNCNAME exceeded max x offset." >&2
		x_offset=$((X_WINDOW_FRAME_WIDTH-1))
	fi
	if [ "$y_offset" -gt $X_WINDOW_FRAME_HEIGHT ]; then
		echo "$FUNCNAME exceeded max y offset." >&2
		y_offset=$((X_WINDOW_FRAME_HEIGHT-1))
	fi

	if [ "$((x_offset+width))" -gt "$X_WINDOW_FRAME_WIDTH" ]; then
		echo "$FUNCNAME over frame width boundary." >&2
		width=$((X_WINDOW_FRAME_WIDTH-$x_offset))
	fi
	if [ "$((y_offset+height))" -gt "$X_WINDOW_FRAME_HEIGHT" ]; then
		echo "$FUNCNAME over frame height boundary." >&2
		height=$((X_WINDOW_FRAME_HEIGHT-$y_offset))
	fi
	_XWindow_get "${1-}" -crop ${width}x${height}${x_offset}${y_offset} ${@:6}
}

unset -f XWindow_displayCroppedPixel
XWindow_displayCroppedPixel(){
	XWindow_getCroppedPixel miff $@ | DISPLAY=${X_WINDOW_DISPLAY_HOST:-$DISPLAY} convert miff:- x:- &
}

unset -f XWindow_getCropped
XWindow_getCropped(){
	if [ -z "${2:-}" -o -z "${3:-}" ]; then
		echo "$FUNCNAME FORMAT WIDTH HEIGHT [XOFFSET] [YOFFSET] [ADDITIONAL]"
		return 1
	fi
	width=$(echo "scale=0; $X_WINDOW_FRAME_WIDTH*${2}/1000" | bc -l)
	height=$(echo "scale=0; $X_WINDOW_FRAME_HEIGHT*${3}/1000" | bc -l)
	x_offset=+$(echo "scale=0; $X_WINDOW_FRAME_WIDTH*${4}/1000" | bc -l)
	y_offset=+$(echo "scale=0; $X_WINDOW_FRAME_HEIGHT*${5}/1000" | bc -l)
	XWindow_getCroppedPixel "${1-}" $width $height $x_offset $y_offset ${@:6}
}

unset -f XWindow_displayCropped
XWindow_displayCropped(){
	XWindow_getCropped miff $@ | DISPLAY=${X_WINDOW_DISPLAY_HOST:-$DISPLAY} convert miff:- x:- &
}

unset -f XWindow_save
XWindow_save(){
	if [ -z "${1-}" ]; then
		echo "$FUNCNAME FILE.miff"
		return 1
	fi
	if [ -f "$1.miff" ]; then
		echo "$1.miff already exist!"
		return 1
	fi
	_XWindow_get > $1.miff
}

unset -f _XWindow_hideBorder
_XWindow_hideBorder(){
	xprop -id $X_WINDOW_ID -f _MOTIF_WM_HINTS 32c -set _MOTIF_WM_HINTS "0x2, 0x0, 0x0, 0x0, 0x0"
}

unset -f _XWindow_moveMouse
_XWindow_moveMouse(){
	xdotool mousemove -w $X_WINDOW_ID --sync $@
}

unset -f XWindow_moveMousePixel
XWindow_moveMousePixel(){
	mouse_x=${1:-0}
	mouse_y=${2:-0}
	_XWindow_moveMouse $((X_WINDOW_FRAME_OFFSET_X+mouse_x)) $((X_WINDOW_FRAME_OFFSET_Y+mouse_y)) ${@:3}
}

unset -f XWindow_moveMouse
XWindow_moveMouse(){
	mouse_px=${1:-0}
	mouse_py=${2:-0}
	mouse_x=$(echo "scale=0; $X_WINDOW_FRAME_WIDTH*$mouse_px/1000" | bc -l)
	mouse_y=$(echo "scale=0; $X_WINDOW_FRAME_HEIGHT*$mouse_py/1000" | bc -l)
	XWindow_moveMousePixel $mouse_x $mouse_y ${@:3}
}

unset -f XWindow_clickPixel
XWindow_clickPixel(){
	XWindow_moveMousePixel $@ click 1
}

unset -f XWindow_click
XWindow_click(){
	XWindow_moveMouse $@ click 1
}

unset -f XWindow_getMousePixel
XWindow_getMousePixel(){
	eval $(xdotool getmouselocation --shell --prefix=mouse_)
	middle_x=$((X_WINDOW_FRAME_WIDTH/2))
	middle_y=$((X_WINDOW_FRAME_HEIGHT/2))
	eval $(xdotool mousemove --sync -w $X_WINDOW_ID $middle_x $middle_y getmouselocation --shell --prefix=zero_ mousemove --sync $mouse_X $mouse_Y)
	mouse_dx=$((mouse_X-zero_X+middle_x-X_WINDOW_FRAME_OFFSET_X))
	mouse_dy=$((mouse_Y-zero_Y+middle_y-X_WINDOW_FRAME_OFFSET_Y))
	echo $mouse_dx $mouse_dy
}

unset -f XWindow_getMouse
XWindow_getMouse(){
	eval $(xdotool getmouselocation --shell --prefix=mouse_)
	middle_x=$((X_WINDOW_FRAME_WIDTH/2))
	middle_y=$((X_WINDOW_FRAME_HEIGHT/2))
	eval $(xdotool mousemove --sync -w $X_WINDOW_ID $middle_x $middle_y getmouselocation --shell --prefix=zero_ mousemove --sync $mouse_X $mouse_Y)
	mouse_px=$(echo "scale=0; 1000*($mouse_X-$zero_X+$middle_x-$X_WINDOW_FRAME_OFFSET_X)/$X_WINDOW_FRAME_WIDTH" | bc -l)
	mouse_py=$(echo "scale=0; 1000*($mouse_Y-$zero_Y+$middle_y-$X_WINDOW_FRAME_OFFSET_Y)/$X_WINDOW_FRAME_HEIGHT" | bc -l)
	echo $mouse_px $mouse_py
}

unset -f XWindow_getMouseAuto
XWindow_getMouseAuto(){
	X_WINDOW_INTERRUPT=$FUNCNAME
	trap _XWindow_interrupt INT
	while [ "$X_WINDOW_INTERRUPT" = "$FUNCNAME" ]; do
		echo $(XWindow_getMousePixel) $(XWindow_getMouse)
		sleep 0.1
	done
}

unset -f _XWindow_interrupt
_XWindow_interrupt(){
	echo -e "\n$FUNCNAME" >&2
	X_WINDOW_INTERRUPT=
	trap - INT
}

unset -f _XWindow_setup
_XWindow_setup(){
	if [ -z "${X_WINDOW_TMP_FILE-}" ]; then
		X_WINDOW_TMP_FILE=$(mktemp -p /dev/shm)
	fi
	if [ "${X_WINDOW_LOCK-x}" = "x" ]; then #LOCK THE IMAGE TO PROCESSING
		X_WINDOW_LOCK=
	fi
	if [ "${X_WINDOW_AUTO:-0}" -eq 1 -a ! -z "${X_WINDOW_AUTO_NAME:-}" ]; then
		x_window_list="$(wmctrl -l | grep "$X_WINDOW_AUTO_NAME")"
		x_window_count=$(echo "$x_window_list" | wc -l)
		if [ $x_window_count -ne 1 ]; then
			echo "X_WINDOW AUTO: Failed with $x_window_count matches."
		else
			X_WINDOW_ID=$(echo "$x_window_list" | cut -f 1 -d " ")
			XWindow_checkId && echo -n "X_WINDOW AUTO: $X_WINDOW_ID " && XWindow_calibrate || echo -e "\nX_WINDOW AUTO: Failed to setup."
		fi
	fi
	REPL_EXIT_addFunction _XWindow_exit
}

unset -f _XWindow_exit
_XWindow_exit(){
	if [ ! -z "${X_WINDOW_TMP_FILE-}" -a -f "${X_WINDOW_TMP_FILE}" ]; then
		rm ${X_WINDOW_TMP_FILE}
	fi
	if [ ! -z "$X_WINDOW_BACKGROUND_PID" ]; then
		kill $X_WINDOW_BACKGROUND_PID
	fi
}

if [ ! -z "${X_WINDOW_DISPLAY-}" ]; then
	if [ "${X_WINDOW_DISPLAY_HOST-x}" = "x" ]; then
		if [ -z "${DISPLAY:-}" ]; then
			echo "DISPLAY variable is not set." >&2
			exit 1
		fi	
		X_WINDOW_DISPLAY_HOST=$DISPLAY
	fi
	export DISPLAY=$X_WINDOW_DISPLAY
fi

if [ "${X_WINDOW_INTERRUPT-x}" = "x" ]; then
	X_WINDOW_INTERRUPT=
	X_WINDOW_TMP_FILE=
	X_WINDOW_LOCK=
	X_WINDOW_BACKGROUND_PID=
	X_WINDOW_ID=
	X_WINDOW_WIDTH=
	X_WINDOW_HEIGHT=
	X_WINDOW_FRAME_WIDTH=
	X_WINDOW_FRAME_HEIGHT=
	X_WINDOW_FRAME_OFFSET_X=
	X_WINDOW_FRAME_OFFSET_Y=
	X_WINDOW_GEOMETRY=
	_XWindow_setup
fi

