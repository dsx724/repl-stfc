unset -f ImageUtility_showColor
ImageUtility_showColor(){
	local mouse_xy=($(XWindow_getMousePixel))
	local mouse_pxpy=($(XWindow_getMouse))
	local color_line=$(XWindow_getCroppedPixel txt 1 1 ${mouse_xy[0]} ${mouse_xy[1]} 2> /dev/null | tail -n 1 )
	local color_rgb=$(echo "$color_line" | grep -oE "srgba?\([0-9,]*\)" | grep -oE "[0-9]+,[0-9]+,[0-9]+")
	local color_hex=$(echo "$color_line" | grep -oE "#[0-9A-F]{6}")
	printf '\e[38;2;%sm\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\e[0;00m' ${color_rgb//,/;}
	echo -ne " ${color_hex} ${mouse_xy[@]} ${mouse_pxpy[@]}        \t"
}

ImageUtility_showColorLoop(){
	IMAGE_UTILITY_INTERRUPT=$FUNCNAME
	trap _ImageUtility_interrupt INT
	while [ "$IMAGE_UTILITY_INTERRUPT" = "$FUNCNAME" ]; do
		echo -ne "\r$(ImageUtility_showColor)"
	done
}

unset -f ImageUtility_findBox
ImageUtility_findBox(){
	local mouse_pxpy=($(XWindow_getMouse))
	local mouse_px=${mouse_pxpy[0]}
	local mouse_py=${mouse_pxpy[1]}

	echo ${mouse_pxpy[@]}
	
	ImageUtility_showColor
		
	if [ $mouse_px -lt 0 -o $mouse_px -ge 1000 -o $mouse_py -lt 0 -o $mouse_py -ge 1000 ]; then
		echo "$FUNCNAME mouse not in window." >&2
		return 1
	fi

	local colors=1
	
	local search_start=0
	local search_end=$mouse_px
	local search_test=$(((search_start + $search_end)/2))
	while true; do
		echo $search_start $search_test $search_end
		colors=$(XWindow_getCropped "-format %c histogram:info" $((mouse_px - $search_test + 1)) 1 $search_test $mouse_py $@ | wc -l)
		if [ "$colors" -gt 1 ]; then
			if [ "$search_start" -eq "$search_test" ]; then
				search_test=$search_end
				break;
			fi
			search_start=$search_test
		else
			search_end=$search_test
			if [ $search_start -eq $search_end ]; then
				break;
			fi
		fi
		local search_test=$(((search_start + $search_end)/2))
	done
	echo $(XWindow_getCropped "-format %c histogram:info" $((mouse_px - $search_test + 1)) 1 $search_test $mouse_py $@)
	local box_x_start=$search_test

	search_start=$mouse_px
	search_end=1000
	search_test=$(((search_start + $search_end + 1)/2))
	while true; do
		echo $search_start $search_test $search_end
		colors=$(XWindow_getCropped "-format %c histogram:info" $((search_test - mouse_px + 1)) 1 $mouse_px $mouse_py $@ | wc -l)
		if [ "$colors" -gt 1 ]; then
			if [ "$search_end" -eq "$search_test" ]; then
				search_test=$search_start
				break;
			fi
			search_end=$search_test
		else
			search_start=$search_test
			if [ $search_start -eq $search_end ]; then
				break;
			fi
		fi
		local search_test=$(((search_start + $search_end + 1)/2))
	done
	echo $(XWindow_getCropped "-format %c histogram:info" $((search_test - mouse_px + 1)) 1 $mouse_px $mouse_py $@)
	local box_x_end=$search_test
	
	local box_x_width=$((box_x_end-box_x_start))

	search_start=0
	search_end=$mouse_py
	search_test=$(((search_start + $search_end)/2))
	while true; do
		echo $search_start $search_test $search_end
		colors=$(XWindow_getCropped "-format %c histogram:info" $box_x_width $((mouse_py - search_test + 1)) $box_x_start $search_test $@ | wc -l)
		if [ "$colors" -gt 1 ]; then
			if [ "$search_start" -eq "$search_test" ]; then
				search_test=$search_end
				break;
			fi
			search_start=$search_test
		else
			search_end=$search_test
			if [ $search_start -eq $search_end ]; then
				break;
			fi
		fi
		local search_test=$(((search_start + $search_end)/2))
	done
	echo $(XWindow_getCropped "-format %c histogram:info" $box_x_width $((mouse_py - search_test + 1)) $box_x_start $search_test $@)
	local box_y_start=$search_test
	
	search_start=$mouse_py
	search_end=1000
	search_test=$(((search_start + $search_end + 1)/2))
	while true; do
		echo $search_start $search_test $search_end
		colors=$(XWindow_getCropped "-format %c histogram:info" $box_x_width $((search_test - mouse_py + 1)) $box_x_start $mouse_py $@ | wc -l)
		if [ "$colors" -gt 1 ]; then
			if [ "$search_end" -eq "$search_test" ]; then
				search_test=$search_start
				break;
			fi
			search_end=$search_test
		else
			search_start=$search_test
			if [ $search_start -eq $search_end ]; then
				break;
			fi
		fi
		local search_test=$(((search_start + $search_end + 1)/2))
	done
	echo $(XWindow_getCropped "-format %c histogram:info" $box_x_width $((search_test - mouse_py + 1)) $box_x_start $mouse_py $@ | wc -l)
	local box_y_end=$search_test

	local box_y_height=$((box_y_end-$box_y_start))

	echo $box_x_start $box_x_end $box_x_width $box_y_start $box_y_end $box_y_height $(XWindow_getCropped "-format %c histogram:info" $box_x_width $box_y_height $box_x_start $box_y_start $@)
	echo ${box_x_width}x${box_y_height}+$box_x_start+$box_y_start
}



unset -f _ImageUtility_interrupt
_ImageUtility_interrupt(){
	echo -e "\n$FUNCNAME" >&2
	IMAGE_UTILITY_INTERRUPT=
	trap - INT
}

if [ "${IMAGE_UTILITY_INTERRUPT-x}" = "x" ]; then
	IMAGE_UTILITY_INTERRUPT=
fi

