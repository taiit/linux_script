#!/bin/bash
THINGBOARD_HOST="demo.thingsboard.io"
DEVICE_ID="c306be10-5501-11ec-8109-0996a7665d7e"
ACCESS_TOKEN="SEC6xT6iL80Ez1DnbPm4"
MQTT_TOOL_PUB="mosquitto_pub"
SLEEP_TIME_IN_MINUTES=60  # 60 seconds = 1 minute

TEMPERATURE_SENSOR_NAME="k10temp-pci-00c3"
SENSOR_CPU_POWER_NAME="Core_sum_(W)"
SENSOR_AVERAGE_CPU_FREQ_NAME="average_cpu_freq"

declare -a mArrayTemperatureValue
declare -a mArrayCPUPowerValue
declare -a mArrayCPUFREQValue

getTemp () {
  for zone in `ls /sys/class/thermal/ | grep thermal_zone`
  do
    echo -n "`cat /sys/class/thermal/$zone/type`: "
    echo `cat /sys/class/thermal/$zone/temp | sed 's/\(.\)..$/.\1°C/'`
    #temp=echo `cat /sys/class/thermal/$zone/temp | sed 's/\(.\)..$/.\1°C/'`
    #mosquitto_pub -d -q 1 -h "mqtt.thingsboard.cloud"-t "v1/devices/me/telemetry" -u "$ACCESS_TOKEN" -m "{"temperature":42}"
  done
}

getProcesses() {
  top -b -n 1 | head -n 12  | tail -n 6
}

update () {
  while :
  do
    clear
    getTemp
    echo -e "\nTop 5 CPU hogs:"
    getProcesses
    sleep 5
  done
}


# OLD CODE, DUMMY
#update
#==============================================================================
get_average_value_from_array() {
  local array=("$@")
  local array_size=${#array[@]}
  local sum=0
  #echo "array_size: $array_size"
  if [[ $array_size > 0 ]]; then
    for value in "${array[@]}"; do
      #sum=$(echo $sum + $value | bc -l);
      #or
      sum=`bc <<< "scale=3; $sum + $value"`  
    done
    #echo "Sum = ${sum}"
    average=`bc <<< "scale=3; $sum / $array_size"`
    #echo "Average = ${average}"
    echo $average
    fi
  echo $ret
}

get_average_cpu_freq() {
  cpu_freq=0
  idx=0
  for cpu in `ls /sys/devices/system/cpu/ | egrep -i "cpu[0-9]"`
  do
    cpu_freq_new=`cat  /sys/devices/system/cpu/$cpu/cpufreq/scaling_cur_freq`
    #echo "$cpu_freq_new"
    let "idx+=1" 
    let "cpu_freq+=$cpu_freq_new"
  done
  let "idx*=1000"
  cpu_freq=`bc <<< "scale=2; ${cpu_freq}/${idx}"`
  #echo "idx:$idx"
  echo "$cpu_freq"
}

collect_sensor_data() {
  local sensor_value=`sensors $TEMPERATURE_SENSOR_NAME -u | grep temp1_input | cut -d' ' -f4`
  mArrayTemperatureValue+=($sensor_value)
  
  sensor_value=`/opt/rapl-read-ryzen/ryzen | grep -e "Core sum" | cut -d' ' -f3 | cut -d'W' -f1`
  mArrayCPUPowerValue+=($sensor_value)

  sensor_value=`get_average_cpu_freq`
  mArrayCPUFREQValue+=($sensor_value)
  #echo ${mArrayTemperatureValue[@]}
  #echo ${mArrayCPUPowerValue[@]}
  #echo ${mArrayCPUFREQValue[@]}
}

mqtt_public_all_sensor_value() {

  local temperature_sensor_value=`get_average_value_from_array ${mArrayTemperatureValue[@]}`
  local cpu_power_sensor_value=`get_average_value_from_array ${mArrayCPUPowerValue[@]}`
  local cpu_freq_sensor_value=`get_average_value_from_array ${mArrayCPUFREQValue[@]}`
  
  echo "$TEMPERATURE_SENSOR_NAME: $temperature_sensor_value"
  echo "$SENSOR_CPU_POWER_NAME: $cpu_power_sensor_value"
  echo "$SENSOR_AVERAGE_CPU_FREQ_NAME: $cpu_freq_sensor_value"
 

  $MQTT_TOOL_PUB -d -q 1 -h $THINGBOARD_HOST -t "v1/devices/me/telemetry" -u $ACCESS_TOKEN \
  -m "{\
        ${TEMPERATURE_SENSOR_NAME}:${temperature_sensor_value},\
        ${SENSOR_CPU_POWER_NAME}:${cpu_power_sensor_value},\
        ${SENSOR_AVERAGE_CPU_FREQ_NAME}:${cpu_freq_sensor_value}\
      }"
}


main() {
  cnt_a_minute=1
  cnt_5_minutes=0
  #sleep 30s, after reboot
  while true
  do
    let "cnt_5_minutes=${cnt_a_minute} % 5"
    
    # Collect sensor data ever minute
    collect_sensor_data
    # Public all sensors value after 5 minutes
    if [[ $cnt_5_minutes == 0 ]]; then
      #echo "BOOM!!"
      mqtt_public_all_sensor_value
      mArrayTemperatureValue=()
      mArrayCPUPowerValue=()
    fi

    # Sleep, do nothing...
    sleep $SLEEP_TIME_IN_MINUTES
    let "cnt_a_minute += 1"
  done
}
# call main
main $@

#TODO
# Get power usage
# Get coin avaibale
# Get CPU clock