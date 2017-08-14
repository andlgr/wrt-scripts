#!/bin/sh

VERSION="v1.2.1"

set_led_state() {
  return 0
  local led_state="$1"
  echo $led_state > /sys/class/leds/ath9k-phy0/brightness
  echo $led_state > /sys/class/leds/tp-link:green:lan1/brightness
  echo $led_state > /sys/class/leds/tp-link:green:lan2/brightness
  echo $led_state > /sys/class/leds/tp-link:green:lan3/brightness
  echo $led_state > /sys/class/leds/tp-link:green:lan4/brightness
  echo $led_state > /sys/class/leds/tp-link:green:qss/brightness
  echo $led_state > /sys/class/leds/tp-link:green:system/brightness
  echo $led_state > /sys/class/leds/tp-link:green:wan/brightness
  return 0
}

log_link_up() {
  local log_file=$1
  local last_link_down=$2

  if [[ "$last_link_down" = "" ]]; then
    return 0
  fi
  
  local last_link_up=$(date +%s)
  local curr_date=$(date)

  local diff_sec=$(expr $last_link_up - $last_link_down)
  local diff_min=$(expr $diff_sec / 60)
  local diff_hrs=$(expr $diff_sec / 3600)
  
  local sec=$(printf %02d $(expr $diff_sec % 60))
  local min=$(printf %02d $(expr $diff_min % 60))
  local hrs=$(printf %02d $diff_hrs)

  echo "$curr_date: Internet link was down for $hrs:$min:$sec" >> $log_file
  echo "------------------------------------------------------------------" >> $log_file

  return 0
}

log_link_down() {
  local log_file=$1  
  local curr_date=$(date)  
  echo "$curr_date: Internet link is down!" >> $log_file
  return 0
}

main() {
  local USAGE="Usage: ${0} <host to ping> <timeout sec> <sleep sec> <log file>"

  if [[ "${1}" = "" ]]; then
    echo $USAGE
    exit 1
  fi

  if [[ "${2}" = "" ]]; then
    echo $USAGE
    exit 1
  fi

  if [[ "${3}" = "" ]]; then
    echo $USAGE
    exit 1
  fi

  if [[ "${4}" = "" ]]; then
    echo $USAGE
    exit 1
  fi

  local host=$1
  local timeout=$2
  local sleep=$3
  local log_file=$4

  local prev_state=""
  local curr_state=""
  
  local last_link_down=""

  sleep 10 # Wait for router to boot up

  echo "Network Monitor Log (Author: André Reis) - $VERSION" > $log_file
  echo "Started at $(date)" >> $log_file
  echo "------------------------------------------------------------------" >> $log_file

  ln -s $log_file /home/root/log

  while true
  do
    # Check network status
    ping -c 1 -s 1 -w $timeout $host > /dev/null 2>&1
    curr_state=$?
    if [[ "$curr_state" != "0" ]]; then
      # Try again
      ping -c 1 -s 1 -w $timeout $host > /dev/null 2>&1
      curr_state=$?
    fi

    # Update state
    if [[ "$curr_state" = "0" ]]; then
      if [[ "$prev_state" != "$curr_state" ]]; then
        # Online = LED OFF
        set_led_state "0"
        log_link_up $log_file $last_link_down
        prev_state=$curr_state
      fi
    else
      if [[ "$prev_state" != "$curr_state" ]]; then
        # Offline = LED ON
        set_led_state "255"
        last_link_down=$(date +%s)
        log_link_down $log_file
        prev_state=$curr_state
      fi
    fi

    # Sleep a little bit (we don't want to use all CPU resources!)
    sleep $sleep
  done

}

main "$@"
