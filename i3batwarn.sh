#!/bin/bash -x

#############################################
# This is a simple battery warning script.  #
# It uses i3's nagbar to display warnings.  #
#                                           #
# @author agribu                            #
#############################################

# lock file location
export BATT_LOCK_FILE=/tmp/battery_state.lock

# check if another copy is running
if [[ -a $BATT_LOCK_FILE ]]; then

    pid=$(cat $BATT_LOCK_FILE | awk '{print $1}')
	ppid=$(cat $BATT_LOCK_FILE | awk '{print $2}')
	# validate contents of previous lock file
	vpid=${pid:-"0"}
	vppid=${ppid:-"0"}

    if (( $vpid < 2 || $vppid < 2 )); then
		# corrupt lock file $BATT_LOCK_FILE ... Exiting
		cp -f $BATT_LOCK_FILE ${BATT_LOCK_FILE}.`date +%Y%m%d%H%M%S`
		exit
	fi

    # check if ppid matches pid
	ps -f -p $pid --no-headers | grep $ppid >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
		# another copy of script running with process id $pid
		exit
	else
		# bogus lock file found, removing
		rm -f $BATT_LOCK_FILE >/dev/null
	fi

fi

pid=$$
ps -f -p $pid --no-headers | awk '{print $2,$3}' > $BATT_LOCK_FILE
# starting with process id $pid

# set Battery
BATTERY=$(ls /sys/class/power_supply/ | grep '^BAT')

# set full path
ACPI_PATH="/sys/class/power_supply/$BATTERY"

# get battery status
STAT=$(cat $ACPI_PATH/status)

# get remaining energy value
REM=`grep "POWER_SUPPLY_ENERGY_NOW" $ACPI_PATH/uevent | cut -d= -f2`

# get full energy value
FULL=`grep "POWER_SUPPLY_ENERGY_FULL_DESIGN" $ACPI_PATH/uevent | cut -d= -f2`

# get current energy value in percent
PERCENT=`echo $(( $REM * 100 / $FULL ))`

# set error message
MESSAGE="DANGER, WILL ROBINSON! LOW BATTERY!"

# set energy limit in percent, where warning should be displayed
#LIMIT="10"
LIMIT="7"

# show warning if energy limit in percent is less then user set limit and
# if battery is discharging
if [ $PERCENT -le "$(echo $LIMIT)" ] && [ "$STAT" == "Discharging" ]; then
    DISPLAY=:0.0 /usr/bin/i3-nagbar -m "$(echo $MESSAGE)"
fi
