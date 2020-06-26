#Get battery level and state
battery_level=$(acpi -b | sed -n 's/.*\ \([[:digit:]]\{1,3\}\)\%.*/\1/;p')
battery_state=$(acpi -b | awk '{print $3}' | tr -d ",")
battery_remaining=$(acpi -b | sed -n '/Discharging/{s/^.*\ \([[:digit:]]\{2\}\)\:\([[:digit:]]\{2\}\).*/\1h \2min/;p}')

#command for emulate the brightness, in this case using light
backlight_cmd=$(which light)

#three different indicator of battery
_battery_threshold_level="20"
_battery_critical_level="12"
_battery_suspend_level="8"

#temporary setting to input battery level and previous battery level to make the notification display only once
if [ ! -f "/tmp/.battery" ]; then
    echo "${battery_level}" > /tmp/.battery
    echo "${battery_state}" >> /tmp/.battery
    exit
fi

previous_battery_level=$(cat /tmp/.battery | head -n 1)
previous_battery_state=$(cat /tmp/.battery | tail -n 1)
echo "${battery_level}" > /tmp/.battery
echo "${battery_state}" >> /tmp/.battery



checkBatteryLevel() {
#idk why this on is here, but yeah it makes the code work for me
    if [ ${battery_state} != "Discharging" ] || [ "${battery_level}" == "${previous_battery_level}" ]; then
        exit
    fi


#note that you need && of previous battert level to make the notification display only once
    if 
        [ ${battery_level} -le ${_battery_suspend_level} ] && [ ${previous_battery_level} -gt ${_battery_suspend_level} ] ; then
        systemctl suspend
    elif 
        [ ${battery_level} -le ${_battery_critical_level} ] && [ ${previous_battery_level} -gt ${_battery_critical_level} ]; then
        notify-send "Low Battery" "Your computer will suspend soon unless plugged into a power outlet." -u critical
        ${backlight_cmd} -S 25
    elif 
        [ ${battery_level} -le ${_battery_threshold_level} ] && [ ${previous_battery_level} -gt ${_battery_threshold_level} ]; then
        notify-send "Low Battery" "${battery_level}% (${battery_remaining}) of battery remaining." -u normal
        ${backlight_cmd} -S 30
    fi
}

checkBatteryStateChange() {
    if
        [ "${battery_state}" = "Charging" ] && [ "${previous_battery_state}" != "Charging" ]; then
        notify-send "Charging" "Battery is now plugged in." -u low
        ${backlight_cmd} -S 85

    elif
     [ "${battery_state}" = "Discharging" ] && [ "${previous_battery_state}" != "Discharging" ]; then
        notify-send "Power Unplugged" "Your computer has been disconnected from power." -u low
        ${backlight_cmd} -S 80

#most of newer laptop has functionality to stop charging when reach 99% more and the output of acpi is "Unknown", please check acpi for the ouput when battery fully charged  
    elif [ "${battery_state}" = "Unknown" ] && [ "${previous_battery_state}" != "Discharging" ]; then
        :

    fi
}

checkBatteryStateChange
checkBatteryLevel
                                                                                                                                                                                            1,1           Top

