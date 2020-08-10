unset -f STFC_sleep
STFC_sleep(){
	if [ -z "${1-}" ]; then
		echo "$FUNCNAME SECONDS"
		return 1
	fi
	seconds=${1%%.*}
	while [ "$seconds" -gt 0 ]; do
		echo -ne "\r$FUNCNAME $seconds"
		sleep 1
		seconds=$((seconds-1))
	done &
	sleep ${1:-0}
	echo -ne "\r"
}

unset -f _STFC_lock
_STFC_lock(){
	STFC_LOCK=1
}

unset -f _STFC_unnlock
_STFC_unlock(){
	STFC_LOCK=
}

unset -f STFC_displayLast
STFC_displayLast(){
	if [ ! -z "$STFC_BACKGROUND_PID" ]; then
		kill $STFC_BACKGROUND_PID
		STFC_BACKGROUND_PID=
	fi
	DISPLAY=${X_WINDOW_DISPLAY_HOST:-$DISPLAY} display -update 1 tiff:$STFC_TMP_FILE &
	STFC_BACKGROUND_PID=$!
}

unset -f STFC_getText
STFC_getText(){
	if [ -z "${1:-}" -o -z "${2:-}" -o -z "${3:-}" -o -z "${4:-}" ]; then
		echo "$FUNCNAME XOFFSET YOFFSET WIDTH HEIGHT [INVERT] [LEVEL] [ADDITIONAL]" >&2
		return 1
	fi
	invert_color=
	if [ ! -z "${5:-}" ] && [ "${5,,}" = "invert" ]; then
		invert_color="-negate"
	fi
	level_psm=6
	if [ ! -z "${6:-}" ] && [ "${6:-}" -ge 0 -a "${6:-}" -le 13 ]; then
		level_psm=$6
	fi
	text=$(XWindow_getCropped tiff $3 $4 $1 $2 -grayscale Rec709Luma $invert_color ${@:7} | tee $STFC_TMP_FILE | tesseract -l eng --psm $level_psm stdin stdout 2> /dev/null | sed "s/^\\s*//" | sed "s/\\s*$//")
	echo "$FUNCNAME ${text}" >&2
	echo ${text//[[:space:]][[:space::]]/}
}

unset -f STFC_getHistogram
STFC_getHistogram(){
	if [ -z "${1:-}" -o -z "${2:-}" -o -z "${3:-}" -o -z "${4:-}" ]; then
		echo "$FUNCNAME XOFFSET YOFFSET WIDTH HEIGHT [ADDITIONAL]" >&2
		return 1
	fi
	XWindow_getCropped "-format %c histogram:info" $3 $4 $1 $2 ${@:5}
}

unset -f STFC_display
STFC_display(){
	if [ -z "${1:-}" -o -z "${2:-}" -o -z "${3:-}" -o -z "${4:-}" ]; then
		echo "$FUNCNAME XOFFSET YOFFSET WIDTH HEIGHT [ADDITIONAL]" >&2
		return 1
	fi
	XWindow_displayCropped $3 $4 $1 $2 ${@:5}
}

unset -f STFC_getInteriorExteriorButtonText
STFC_getInteriorExteriorButtonText(){
	text=$(STFC_getText 830 960 60 30 invert)
	case "${text,,}" in
		interior)
			echo "INTERIOR"
			;;
		exterior)
			echo "EXTERIOR"
			;;
		*)
			echo "$FUNCNAME unknown state: $text" >&2
			;;
	esac
}

unset -f STFC_getSystemGalaxyButtonText
STFC_getSystemGalaxyButtonText(){
	text=$(STFC_getText 920 960 60 30 invert)
	case "${text,,}" in
		galaxy)
			echo "GALAXY"
			;;
		sustem | system)
			echo "SYSTEM"
			;;
		*)
			echo "$FUNCNAME unknown state: $text" >&2
			;;
	esac
}

unset -f _STFC_formatNumber
_STFC_formatNumber(){
	number=$1
	number=${number//O/0}
	number=${number//S/5}
	number=${number//,/}
	echo $number
}

unset -f _STFC_formatNumberSI
_STFC_formatNumberSI(){
	number=$1
	number=${number//O/0}
	number=${number//S/5}
	echo $number | numfmt --from=si
}

unset -f STFC_getParsteelAmount
STFC_getParsteelAmount(){
	_STFC_formatNumberSI $(STFC_getText 705 20 70 35 invert)
}

unset -f STFC_getTritaniumAmount
STFC_getTritaniumAmount(){
	_STFC_formatNumberSI $(STFC_getText 815 20 70 35 invert)
}

unset -f STFC_getDilithiumAmount
STFC_getDilithiumAmount(){
	_STFC_formatNumberSI $(STFC_getText 920 20 70 35 invert)
}

unset -f STFC_getPowerAmount
STFC_getPowerAmount(){
	_STFC_formatNumber $(STFC_getText 115 20 155 42 invert)
}

unset -f STFC_getLatinumAmount
STFC_getLatinumAmount(){
	_STFC_formatNumberSI $(STFC_getText 110 90 85 40 invert)
}

unset -f STFC_getTargetBoxAction1Text
STFC_getTargetBoxAction1Text(){
	text=$(STFC_getText 520 650 160 60 invert)
	case "${text,,}" in
		scan)
			echo "SCAN"
			;;
		*)
			echo "$FUNCNAME unknown state: $text" >&2
			;;
	esac
}

unset -f _STFC_parseDuration
_STFC_parseDuration(){
	string=$1
	string=${string//O/0}
	string=${string//l/1}
	string=${string//i/1}
	#string=${string//d/2s}
	string=${string//S/5}
	string=${string//T/1}
	string=${string//I/1}
	string=${string//é/6}
	string=${string//e/2}
	if [ ${#string} -ne 3 ]; then
		echo "$FUNCNAME time parse failed: $string" >&2
		return 1
	fi
	if [ ! -z "${string//[0-9]*[hms]/}" ]; then
		echo "$FUNCNAME invalid character found: $string" >&2
		return 1
	fi
	seconds=0
	case "${string: -1}" in
		h)
			seconds=$((3600*$((10#${string:0:2}))))
			;;
		m)
			seconds=$((60*$((10#${string:0:2}))))
			;;
		s)
			seconds=$((10#${string:0:2}))
			;;
		*)
			echo "$FUNCNAME time multiple failed: $string" >&2
			return 1
			;;
	esac
	echo ${seconds:-0}
}

unset -f STFC_getTargetBoxAction2Text
STFC_getTargetBoxAction2Text(){
	text=$(STFC_getText 722 650 215 60 invert 2> /dev/null)
	#text=$(STFC_getText 730 760 215 80 invert)
	action=${text%% *}
	duration=${text#* }
	case "${action,,}" in
		armada)
			echo -n "ARMADA"
			;;
		attack)
			if [ "${duration%% *}" = "A..." ]; then
				echo -n "ATTACKALL "
				duration=${duration#* }
			else
				echo -n "ATTACK "
			fi
			;;
		mine)
			echo -n "MINE "
			;;
		*)
			echo "$FUNCNAME unknown state: $text" >&2
			return 1
			;;
	esac
	seconds=0
	for string in $duration; do
		seconds=$((seconds+$(_STFC_parseDuration $string)))
		if [ $? -ne 0 ]; then
			return 1
		fi
	done
	echo $seconds
}

unset -f STFC_getTargetBoxStationStrengthText
STFC_getTargetBoxStationStrengthText(){
	_STFC_formatNumberSI $(STFC_getText 535 560 160 50 invert)
}

unset -f STFC_getTargetBoxShipStrengthText
STFC_getTargetBoxShipStrengthText(){
	_STFC_formatNumber $(STFC_getText 565 545 160 45 invert)
}

unset -f STFC_getTargetBoxActionable
STFC_getTargetBoxActionable(){
	text=$(STFC_getText 480 625 470 115 invert)
	text=${text// /}
	if [ "${text/Targetlevelistoolow//}" != "$text" ]; then
		echo "TARGET_LEVEL_TOO_LOW"
	elif [ "${text/Targetnotinsamesystem//}" != "$text" ]; then
		echo "TARGET_NOT_IN_SAME_SYSTEM"
	elif [ "${text/Targetlevelistoohigh//}" != "$text" ]; then
		echo "TARGET_LEVEL_TOO_HIGH"
	elif [ "${text/OCCUPIED//}" != "$text" ]; then
		echo "TARGET_OCCUPIED"
	fi
}

unset -f STFC_getShipMenuStatus
STFC_getShipMenuStatus(){
	text=$(STFC_getText 10 635 200 40 invert 6 -brightness-contrast 30x50)
	text=${text// /}
	case "${text,,}" in
		mining)
			echo "MINING"
			;;
		awaitingorders)
			echo "AWAITING_ORDERS"
			;;
		enroute)
			echo "EN_ROUTE"
			;;
		targeting)
			echo "TARGETING"
			;;
		inbattle)
			echo "IN_BATTLE"
			;;
		charging)
			echo "CHARGING"
			;;
		warping)
			echo "WARPING"
			;;
		damaged)
			echo "DAMAGED"
			;;
		destroyed)
			echo "DESTROYED"
			;;
		repairing)
			echo "REPAIRING"
			;;
		home)
			echo "HOME"
			;;
		*)
			echo "$FUNCNAME unknown state: $text." >&2
			return 1
			;;
	esac
}

unset -f STFC_isShipSelected
STFC_isShipSelected(){
	color=4.F.F
	color_negative=
	color_limit=1
	filter="-colorspace ycbcr +dither -posterize 2"
	case $1 in
		1)
			_STFC_analyzeBar $color $color_limit 321 981 87 19 $filter > /dev/null 2>&1
			;;
		2)
			_STFC_analyzeBar $color $color_limit 411 981 88 19 $filter > /dev/null 2>&1
			;;
		3)
			_STFC_analyzeBar $color $color_limit 503 981 87 19 $filter > /dev/null 2>&1
			;;
		*)
			return 1
			;;
	esac
	return $?
}

unset -f STFC_getShipSelected
STFC_getShipSelected(){
	for i in 1 2 3; do
		if STFC_isShipSelected $i; then
			echo $i
			return
		fi
	done
	echo "$FUNCNAME selected ship not found." >&2
	return 1
}

unset -f STFC_selectShip
STFC_selectShip(){
	if [ -z "${1:-}" ]; then
		echo "$FUNCNAME SHIP#" >&2
		return 1
	fi
	#if STFC_isShipSelected $1; then
	#	return 0
	#fi
	ship=$1
	case $ship in
		1)
			XWindow_moveMouse 365 870 click 1
			;;
		2)
			XWindow_moveMouse 455 870 click 1
			;;
		3)
			XWindow_moveMouse 545 870 click 1
			;;
	esac
	STFC_sleep 1
	if ! STFC_isShipSelected $ship; then
		echo "$FUNCNAME $ship unexpected error." >&2
		return 1
	fi
}

unset -f STFC_isShipIdle
STFC_isShipIdle(){
	if [ -z "${1:-}" ]; then
		echo "$FUNCNAME SHIP#" >&2
		return 1
	fi
	ship=$1
	offset_y=824
	if STFC_isShipSelected $ship; then
		offset_y=810
	fi
	text=
	case $ship in
		1)
			text=$(STFC_getText 378 $offset_y 28 40 invert 6 -colorspace ycbcr)
			;;
		2)
			text=$(STFC_getText 468 $offset_y 28 40 invert 6 -colorspace ycbcr)
			;;
		3)
			text=$(STFC_getText 559 $offset_y 28 40 invert 6 -colorspace ycbcr)
			;;
	esac
	case "${text,,}" in
		a)
			return 0 #upgrade
			;;
		co)
			return 0 #home
			;;
		o)
			return 0 #home
			;;
		on)
			return 1 #mining?
			;;
		vf)
			return 1 #warping
			;;
		vv)
			return 1 #warping
			;;
		@)
			return 0 #home
			;;
		">")
			return 1 #impulse
			;;
		"\\")
			return 1 #mining?
			;;
		
	esac
}


unset -f STFC_openShipMenu
STFC_openShipMenu(){
	if [ -z "${1:-}" ]; then
		echo "$FUNCNAME SHIP#" >&2
		return 1
	fi
	ship=$1
	ship_selected=$(STFC_getShipSelected)
	if [ "$ship_selected" != "$ship" ]; then
		STFC_selectShip $ship
		if [ $? -ne 0 ]; then
			echo "$FUNCNAME unable to select ship $ship." >&2
			return 1
		fi
		STFC_sleep 1
	fi
	if STFC_getShipMenuStatus > /dev/null 2>&1; then
		return
	fi
	STFC_selectShip $ship
	if [ $? -ne 0 ]; then
		echo "$FUNCNAME unable to select ship $ship." >&2
		return 1
	fi
	STFC_sleep 1
	if ! STFC_getShipMenuStatus > /dev/null 2>&1; then
		echo "$FUNCNAME unable to open ship $ship menu!" >&2
		return 1
	fi
}

unset -f STFC_getShipMenuButtonText
STFC_getShipMenuButtonText(){
	if [ -z "${1:-}" -o -z "${2:-}" ]; then
		echo "$FUNCNAME SHIP# MENUBUTTON#" >&2
		return 1
	fi
	ship=$1
	button=$2
	STFC_openShipMenu $1
	case $button in
		1)
			text=$(STFC_getText 16 705 190 65 invert 6 -brightness-contrast 30x50)
			case ${text,,} in
				manage)
					echo "MANAGE"
					;;
				*)
					return 1
					;;
			esac
			;;
		2)
			text=$(STFC_getText 16 805 190 65 invert 6 -brightness-contrast 40x50)
			text1=${text%% *}
			case ${text1,,} in
				locate)
					echo "LOCATE"
					;;
				repair)
					text2=${text#* }
					text2=${text2// /}
					seconds=0
					while [ ! -z "$text2" ]; do
						string=${text2:0:3}
						seconds=$((seconds+$(_STFC_parseDuration $string)))
						if [ $? -ne 0 ]; then
							return 1
						fi
						text2=${text2:3}
					done
					echo "REPAIR $seconds"
					;;
				*)
					return 1
					;;
			esac
			;;
		3)
			text=$(STFC_getText 16 905 190 65 invert 6 -brightness-contrast 30x50)
			text1=${text%% *}
			case ${text1,,} in
				recall)
					echo "RECALL"
					;;
				instant)
					text2=${text##* }
					echo "INSTANT $text2"
					;;
				askforhelp)
					echo "ASK_FOR_HELP"
					;;
				speedup)
					echo "SPEED_UP"
					;;
				free)
					echo "FREE"
					;;
				*)
					return 1
					;;
			esac
			;;
		*)
			echo "$FUNCNAME what?" >&2
			return 1
			;;
	esac
}

unset -f STFC_clickShipMenuButton
STFC_clickShipMenuButton(){
	if [ -z "${1:-}" ]; then
		echo "$FUNCNAME MENUBUTTON#" >&2
		return 1
	fi
	case $1 in
		1)
			XWindow_moveMouse 200 740 click 1
			;;
		2)
			XWindow_moveMouse 200 840 click 1
			;;
		3)
			XWindow_moveMouse 200 940 click 1
			;;
	esac
	STFC_sleep 1
	XWindow_moveMouse $((500+RANDOM%100)) $((500+RANDOM%100))
}


unset -f STFC_closeShipMenu
STFC_closeShipMenu(){
	: #TODO FINISH THIS
	STFC_getSelectedShip
}

unset -f STFC_getShipMaterialStatus
STFC_getShipMaterialStatus(){
	: #TODO FINISH THIS
}

unset -f _STFC_analyzeBar
_STFC_analyzeBar(){
	composition=$(STFC_getHistogram ${@:3})
	composition_colors=$(echo "$composition" | wc -l)
	if [ "$composition_colors" -gt $2 ]; then
		echo "$FUNCNAME too many colors: $composition_colors" >&2
		return 1
	fi
	level=$(echo "$composition" | grep -e \#$1 | grep -o [0-9]*: | grep -o [0-9]* || true)
	level=${level:-0}
	total=$(echo "$composition" | sed "s/^ *//g" | cut -f 1 -d ":" | paste -sd+ | bc)
	level=$((level*100/total))
	echo $level
}

unset -f STFC_getShipShield
STFC_getShipShield(){
	if [ -z "${1:-}" ]; then
		echo "$FUNCNAME SHIP#" >&2
		return 1
	fi
	color=5.B.F.
	color_negative=4.4.5.
	color_limit=8
	filter="+dither -posterize 16"
	case $1 in
		1)
			_STFC_analyzeBar $color $color_limit 336 958 58 4 $filter
			;;
		2)
			_STFC_analyzeBar $color $color_limit 427 957 58 4 $filter
			;;
		3)
			_STFC_analyzeBar $color $color_limit 517 957 59 4 $filter
	esac
}

unset -f STFC_getShipHealth
STFC_getShipHealth(){
	if [ -z "${1:-}" ]; then
		echo "$FUNCNAME SHIP#" >&2
		return 1
	fi
	color=E.E.E.
	color_negative=
	color_limit=8
	filter="+dither -posterize 16"
	case $1 in
		1)
			_STFC_analyzeBar $color $color_limit 336 973 58 5 $filter
			;;
		2)
			_STFC_analyzeBar $color $color_limit 427 973 58 5 $filter
			;;
		3)
			_STFC_analyzeBar $color $color_limit 517 973 59 4 $filter
			;;
	esac
}

unset -f STFC_getShipStatus
STFC_getShipStatus(){
	if [ -z "${1:-}" ]; then
		echo "$FUNCNAME SHIP#" >&2
		return 1
	fi
	invert=
	offset_y=955
	if ! STFC_isShipSelected $1; then
		invert=invert
		offset=967
	fi
	text=
	case $1 in
		1)
			text=$(STFC_getText 321 $offset_y 85 30 $invert)
			;;
		2)
			text=$(STFC_getText 415 $offset_y 85 30 $invert)
			;;
		3)
			text=$(STFC_getText 503 $offset_y 85 30 $invert)
			;;
	esac
	text=${text// /}
	case "${text,,}" in
		destroyed)
			echo "DESTROYED"
			;;
		home)
			echo "HOME"
			;;
		charging)
			echo "CHARGING"
			;;
		warping)
			echo "WARPING"
			;;
		repairing)
			echo "REPAIRING"
			;;
		inbattle)
			echo "IN_BATTLE"
			;;
		awaitingo...)
			echo "AWAITING_ORDERS"
			;;
		*)
			echo "$FUNCNAME unknown state: $text" >&2
			return 1
			;;
	esac
}

unset -f STFC_getShipTimer
STFC_getShipTimer(){
	if [ -z "${1:-}" ]; then
		echo "$FUNCNAME SHIP#" >&2
		return 1
	fi
	ship=$1
	offset_y=774
	if ! STFC_isShipSelected $ship; then
		offset_y=787
	fi
	text=
	case "$ship" in
		1)
			text=$(STFC_getText 330 $offset_y 70 30 invert)
			;;
		2)
			text=$(STFC_getText 421 $offset_y 70 30 invert)
			;;
		3)
			text=$(STFC_getText 511 $offset_y 70 30 invert)
			;;
	esac
	text=${text// /}
	text=${text//./}
	#if [ ! -z "${text//[0-9hms]/}" ]; then
	#	echo "$FUNCNAME ship $ship returned invalid timer: $text" >&2
	#	return 1
	#fi
	seconds=0
	while [ ! -z "$text" ]; do
		number=$(_STFC_parseDuration ${text:0:3})
		if [ $? -ne 0 ]; then
			echo "$FUNCNAME error on: $text" >&2
			return 1
		fi
		seconds=$((seconds+$number))
		text=${text:3}
	done
	echo $seconds
}

unset -f STFC_getShipMinedCounter
STFC_getShipMinedCounter(){
	# 334 898 63 30
	:
}

unset -f STFC_isPeaceShieldWarning
STFC_isPeaceShieldWarning(){
	check=$(STFC_getText 200 200 600 100 invert 2> /dev/null)
	check=${check,,}
	check=${check// /}
	if [ "${check//peaceshieldactive/}" = "$check" ]; then
		return 1
	fi
}

unset -f STFC_cancelPeaceShieldWarning
STFC_cancelPeaceShieldWarning(){
	XWindow_moveMouse 360 750 click 1
	STFC_sleep 1
	XWindow_moveMouse $((500+RANDOM%100)) $((500+RANDOM%100))
}

unset -f STFC_isBattleLog
STFC_isBattleLog(){
	check=$(STFC_getText 750 925 230 50 invert 2> /dev/null)
	check=${check,,}
	check=${check// /}
	if [ "${check//battlelog/}" = "$check" ]; then
		return 1
	fi
}

unset -f STFC_cancelBattleLog
STFC_cancelBattleLog(){
	XWindow_moveMouse 40 50 click 1
	STFC_sleep 1
	XWindow_moveMouse $((500+RANDOM%100)) $((500+RANDOM%100))
}

unset -f STFC_displayTargetMap
STFC_displayTargetMap(){
	#_XWindow_get | convert miff:- -fuzz 2% -alpha set +transparent "#772c2c" -blur 0x4 -channel opacity -threshold 60% miff:- | display miff:-
	#_XWindow_get | convert miff:- -fuzz 1% -alpha set +transparent "#772c2c" -blur -morphology erode:8 disk:3 miff:- | display miff:-
	#_XWindow_get | convert miff:- -alpha set +transparent "#772c2c" -blur 20x20 -threshold 50% -morphology erode disk:4 miff:- | display miff:-
	#xwd -id $X_WINDOW_ID | convert xwd:- -fuzz 1% -alpha set +transparent "#772c2c" -morphology erode:5 octagon:1 x:-
	#xwd -id $X_WINDOW_ID | convert xwd:- -fuzz 1% -alpha set +transparent "#772c2c" -alpha extract -morphology erode octagon:2 -alpha set +transparent "#ffffff" x:-
	XWindow_display -fuzz 1% -alpha set +transparent "#772c2c" -alpha extract -morphology erode octagon:2 # -alpha set +transparent "#ffffff" 
}

unset -f STFC_listTargets
STFC_listTargets(){
	_XWindow_get sparse-color -fuzz 1% -alpha set +transparent "#772c2c" -alpha extract -morphology erode octagon:2 -alpha set +transparent "#ffffff" | tr " " "\n" | cut -f 1,2 -d "," | shuf
}

unset -f STFC_getTarget
STFC_getTarget(){
	targets=$(STFC_listTargets)
	if [ -z "$targets" ]; then
		echo "$FUNCNAME no targets." >&2
		return 1
	fi
	target_count=$(echo "$targets" | wc -l)
	echo "$FUNCNAME found $target_count targets." >&2
	
	target_x=
	target_y=
	target_last_x=0
	target_last_y=0
	for target in $targets; do
		target_x=${target%%,*}
		target_y=${target##*,}
		target_diff=$(((target_x-target_last_x)*(target_x-target_last_x)+(target_y-target_last_y)*(target_y-target_last_y)))
		target_last_x=$target_x
		target_last_y=$target_y
		if [ "$target_diff" -lt 4 ]; then
			continue
		elif [ "${target_y}" -lt 200 ]; then #top row
			continue
		elif [ "${target_x}" -lt 150 -a "${target_y}" -lt 540 ]; then #expandable menus
			continue
		elif [ "${target_x}" -gt 615 -a "${target_x}" -lt 1300 -a "${target_y}" -gt 880 ]; then #ships
			continue
		elif [ "${target_x}" -lt 160 -a "${target_y}" -gt 675 ]; then #missions
			continue
		elif [ "${target_x}" -lt 230 -a "${target_y}" -gt 850 ]; then #alliance
			continue
		elif [ "${target_x}" -lt 370 -a "${target_y}" -gt 900 ]; then #inbox
			continue
		elif [ "${target_x}" -gt 495 -a "${target_x}" -lt 650 -a "${target_y}" -gt 690 -a "${target_y}" -lt 845 ]; then #mission OK
			continue
		elif [ "${target_x}" -gt 270 -a "${target_x}" -lt 550 -a "${target_y}" -gt 130 -a "${target_y}" -lt 250 ]; then #lose notice
			continue
		elif [ "${target_x}" -gt 1540 -a "${target_y}" -lt 455 ]; then #top right boxes
			continue
		elif [ "${target_x}" -gt 1540 -a "${target_y}" -gt 640 ]; then #peace shield
			continue
		elif [ "${target_x}" -gt 1425 -a "${target_y}" -gt 765 -a "${target_y}" -lt 850 ]; then #bookmark
			continue
		elif [ "${target_x}" -gt 1700 ]; then #home button on right
			continue
		fi
		echo "$FUNCNAME got target at $target_x $target_y" >&2
		XWindow_moveMousePixel $target_x $target_y $@
		return
	done
	echo "$FUNCNAME unable to find a clickable target." >&2
	return 1
}

unset -f STFC_moveViewportRandomly
STFC_moveViewportRandomly(){
	echo "$FUNCNAME moving viewport." >&2
	move_distance=35
	move_starttime=0.4
	move_steptime=0.05
	move_direction_x=$(((1-2*(RANDOM%2))*move_distance))
	move_direction_y=$(((1-2*(RANDOM%2))*move_distance))
	XWindow_moveMouse 382 450 mousedown 1 sleep $move_starttime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y sleep $move_steptime \
		mousemove_relative --sync -- $move_direction_x $move_direction_y \
		mouseup 1
}

unset -f STFC_moveViewportRandomlyAutomate
STFC_moveViewportRandomlyAutomate(){
	STFC_INTERRUPT=$FUNCNAME
	trap _STFC_interrupt INT

	while [ "$STFC_INTERRUPT" = "$FUNCNAME" ]; do
		STFC_moveViewportRandomly
		STFC_sleep 2
	done
}

unset -f STFC_checkAccidentalScreen
STFC_checkAccidentalScreen(){
	if STFC_isBattleLog; then
		echo "$FUNCNAME somehow entered battlelog!" >&2
		STFC_cancelBattleLog
		return 0
	elif STFC_isPeaceShieldWarning; then
		echo "$FUNCNAME almost attacked player!" >&2
		STFC_cancelPeaceShieldWarning
		return 0
	fi
	return 1
}

unset -f STFC_attackAutomate
STFC_attackAutomate(){
	
	STFC_INTERRUPT=$FUNCNAME
	trap _STFC_interrupt INT

	ship=2

	accident=0
	accident_max=5
	error=0
	error_max=20 #number of errors before stopping
	shield_min=90 #minimum shield before attacking
	health_min=90 #minimum health before repair
	check_max=5 #post attack checks
	
	#stack variables
	action= #holder for box action strings
	ship_selected= #holder for the selected ship

	#counters
	check= #current post attack check cycle
	notarget= #counter for cycles with no target
	
	#ship
	health=
	shield=
	status=
	repair=
	go_home=

	while [ "${STFC_INTERRUPT:-}" = "$FUNCNAME" ]; do
		#check for selected ship, only fails in battle or not selected
		ship_selected=$(STFC_getShipSelected)
		if [ $? -ne 0 ]; then
			if STFC_checkAccidentalScreen; then
				if [ "$accident" -ge "$accident_max" ]; then
					echo "$FUNCNAME too many accidents." >&2
					break
				fi
				((accident++))
				continue
			fi
		fi
		accident=0
		if [ "$ship_selected" -ne "$ship" ]; then
			STFC_selectShip $ship
			if [ $? -ne 0 ]; then
				break
			fi
		fi

		#check ship status
		status=$(STFC_getShipStatus $ship 2> /dev/null)
		if [ $? -eq 0 ]; then
			if [ "$status" = "HOME" ]; then
				health=100
				shield=100
				repair=
				#go back to system or pick target
				: #TODO GO TO SYSTEM
					#STFC click random spot
					#STFC check for go and parse time
					#STFC click go
					#STFC sleep time
					#STFC find target
					#STFC check target in system
			elif [ "$status" = "DESTROYED" ]; then
				health=0
				shield=0
				menu_button=$(STFC_getShipMenuButtonText $ship 2)
				if [ $? -ne 0 ]; then
					echo "$FUNCNAME unable to get ship menu button text to start repair." >&2
					break;
				fi
				STFC_sleep 1
				if [ "${menu_button%% *}" = "REPAIR" ]; then
					STFC_clickShipMenuButton 2
					menu_status=$(STFC_getShipMenuStatus)
					if [ $? -ne 0 ]; then
						echo "$FUNCNAME unable to get ship menu status text." >&2
						break;
					fi
					if [ "$menu_status" != "REPAIRING" ]; then
						echo "$FUNCNAME repairing failed." >&2
						break;
					fi
				fi
				sleep_time=${menu_button##* }
				((sleep_time-=300))
				if [ $sleep_time -gt 0 ]; then
					STFC_sleep $sleep_time
				fi
				menu_button=$(STFC_getShipMenuButtonText $ship 3)
				if [ $? -ne 0 ]; then
					echo "$FUNCNAME unable to get ship menu button text to finish repair." >&2
					break;
				fi
				if [ "$menu_button" = "FREE" ]; then
					STFC_clickShipMenuButton 3
					status=$(STFC_getShipStatus $ship)
					continue
				else
					# TODO NEED TO FIGURE OUT WHY
					echo "$FUNCNAME unexpected repair status." >&2
					break
				fi
			else
				#TODO find more states
				echo "$FUNCNAME unexpected ship state: $status" >&2
			fi
		else
			if [ "${go_home:-0}" -eq 1 ]; then
				health=$(STFC_getShipHealth $ship)
				if [ $? -ne 0 ]; then
					echo "$FUNCNAME unexpected and unsupported health status." >&2
					return 1
				fi
				shield=$(STFC_getShipShield $ship)
				if [ $? -ne 0 ]; then
					echo "$FUNCNAME unexpected and unsupported shield status." >&2
					return 1
				fi
				STFC_openShipMenu $ship
				if [ $? -ne 0 ]; then
				echo "$FUNCNAME unable to get ship starting status." >&2
					return 1
				fi
				status=$(STFC_getShipMenuStatus)
				if [ $? -ne 0 ]; then
					echo "$FUNCNAME unable to get ship menu starting status." >&2
					return 1
				fi
				case "$status" in
					AWAITING_ORDERS)
						action=$(STFC_getShipMenuButtonText $ship 3)
						if [ $? -ne 0 ]; then
							echo "$FUNCNAME unable to determine ship menu action 3." >&2
							return 1
						fi
						case "$action" in
							RECALL)
								STFC_clickShipMenuButton 3
								status=$(STFC_getShipMenuStatus)
								echo "$FUNCNAME returning home status: $status" >&2
								go_home=
								repair=1
								STFC_sleep 1
								sleep_timer=$(STFC_getShipTimer $ship)
								if [ $? -eq 0 ]; then
									STFC_sleep $sleep_timer
								fi
								continue
								;;
							*)
								echo "$FUNCNAME unexpected and unsupported ship menu button 3 action." >&2
								return 1
								;;
						esac
						;;
					*)
						echo "$FUNCNAME unsupported go_home status." >&2
				esac
			elif [ "${repair:-0}" -eq 1 ]; then
				status=$(STFC_getShipMenuStatus)
				if [ $? -ne 0 ]; then
					echo "$FUNCNAME unable to get ship menu starting status." >&2
					return 1
				fi
				case "$status" in
					DAMAGED)
						action=$(STFC_getShipMenuButtonText $ship 2)
						if [ $? -ne 0 ]; then
							echo "$FUNCNAME unable to determine ship menu action 2." >&2
							return 1
						fi
						case "${action%% *}" in
							REPAIR)
								STFC_clickShipMenuButton 2
								repair=
								# TODO NEED TO FIGURE OUT WHY
								sleep_time=$(STFC_getShipTimer $ship)
								((sleep_time-=300))
								if [ $sleep_time -gt 0 ]; then
									STFC_sleep $sleep_time
								fi
								menu_button=$(STFC_getShipMenuButtonText $ship 3)
								if [ $? -ne 0 ]; then
									echo "$FUNCNAME unable to get ship menu button text to finish repair." >&2
									break;
								fi
								if [ "$menu_button" = "FREE" ]; then
									STFC_clickShipMenuButton 3
									continue
								fi
								;;
							*)
								echo "$FUNCNAME unexpected and unsupported ship menu button 2 action." >&2
								return 1
								;;
						esac
						;;
				esac
			else
				#TODO SEARCH FOR REPAIR ICON AND REMOVE REPAIR FLAG
				:
			fi
		fi

		#acquire target
		STFC_getTarget click 1
		if [ $? -ne 0 ]; then
			#no target was found
			if [ "${notarget:-0}" -gt 1 ]; then
				STFC_moveViewportRandomly
				notarget=1
			else
				((notarget++))
			fi
			continue
		fi
		STFC_sleep 1

		#check target action
		action=$(STFC_getTargetBoxAction2Text)
		if [ "$?" -ne 0 ]; then
			#check if we accidentally click into something
			((notarget++))
			STFC_checkAccidentalScreen && continue
			#possibly taken or dead target in which save image and increment no target
			echo "$FUNCNAME taken or dead target." >&2
			_XWindow_lock
			XWindow_save samples/parsefail/$(date '+%Y%m%d%H%M%S')
			_XWindow_unlock
			continue
		fi
		if [ "${action%% *}" = "ATTACK" ]; then
			notarget=0
			XWindow_moveMouse 735 680 click 1 #attack button
			STFC_sleep ${action##* }
			#TODO check in battle or target taken and retarget
			STFC_sleep 7
			check=0
			while true; do
				health=$(STFC_getShipHealth $ship 2> /dev/null)
				if [ $? -ne 0 -o -z "$health" ]; then
					if [ "$check" -eq "$check_max" ]; then
						echo "$FUNCNAME are we destroyed?" >&2
						repair=1
						break
					fi
					((check++))
				elif [ "$health" -lt "$health_min" ]; then
					go_home=1
					break
				fi
				shield=$(STFC_getShipShield $ship 2> /dev/null)
				if [ $? -ne 0 -o -z "$shield" ]; then
					if [ "$check" -eq "$check_max" ]; then
						echo "$FUNCNAME are we destroyed?" >&2
						break
					fi
					((check++))
				elif [ "$shield" -lt "$shield_min" ]; then
					STFC_sleep 1
				else
					#shield restored
					break
				fi
			done
		else
			echo "$FUNCNAME unknown action: $action" >&2
			_XWindow_lock
			XWindow_save samples/unknownaction/$(date '+%Y%m%d%H%M%S')
			_XWindow_unlock
			continue
		fi

	done
}

unset -f STFC_getCurrentScreen
STFC_getCurrentScreen(){
	#system, galaxy, exterior, interior, bookmarks, purchase, events, leaderboard, player, 
	#purchase: offers, gifts, recruit, resources, borg, alliances
	#purchase: offers, gifts, recruit, get resources, borg, alliances
	#leaderboard: players, alliances
	#leaderboard: players: power destroyed, power, resources raided
	#leaderboard: alliances: resources raided, power destroyed, power
	#player: avatar, settings
	#player: avatar: 
	#player: settings:
	local INTERIOREXTERIOR=$(STFC_getInteriorExteriorButtonText)
	local SYSTEMGALAXY=$(STFC_isScreenSystemGalaxy)
}

unset -f _STFC_interrupt
_STFC_interrupt(){
	echo -e "\n$FUNCNAME" >&2
	STFC_INTERRUPT=
	trap - INT
}

unset -f _STFC_setup
_STFC_setup(){
	if [ -z "${STFC_TMP_FILE-}" ]; then
		STFC_TMP_FILE=$(mktemp -p /dev/shm)
	fi
	if [ "${STFC_LOCK-x}" = "x" ]; then #LOCK THE IMAGE TO PROCESSING
		STFC_LOCK=
	fi
	REPL_EXIT_addFunction _STFC_exit
}

unset -f _STFC_exit
_STFC_exit(){
	if [ ! -z "${STFC_TMP_FILE-}" -a -f "${STFC_TMP_FILE}" ]; then
		rm ${STFC_TMP_FILE}
	fi
	if [ ! -z "$STFC_BACKGROUND_PID" ]; then
		kill $STFC_BACKGROUND_PID
	fi
}

if [ "${STFC_INTERRUPT-x}" = "x" ]; then
	STFC_INTERRUPT=
	STFC_TMP_FILE=
	STFC_LOCK=
	STFC_BACKGROUND_PID=
	_STFC_setup
fi
