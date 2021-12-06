#!/bin/bash
THINGBOARD_HOST="demo.thingsboard.io"
DEVICE_ID="c306be10-5501-11ec-8109-0996a7665d7e"
ACCESS_TOKEN="SEC6xT6iL80Ez1DnbPm4"
MQTT_TOOL_PUB="mosquitto_pub"

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



#update

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

SENSOR_NAME="k10temp-pci-00c3"
SENSOR_VALUE=`sensors $SENSOR_NAME -u | grep temp1_input | cut -d' ' -f4`
echo "$SENSOR_NAME: $SENSOR_VALUE"
#$MQTT_TOOL_PUB -d -q 1 -h $THINGBOARD_HOST -t "v1/devices/me/telemetry" -u $ACCESS_TOKEN -m "{"$SENSOR_NAME":"$SENSOR_VALUE"}"

SENSOR_POWER_NAME="Core_sum_(W)"
SENSOR_POWER_VALUE=`/opt/rapl-read-ryzen/ryzen | grep -e "Core sum" | cut -d' ' -f3 | cut -d'W' -f1`
echo "$SENSOR_POWER_NAME: $SENSOR_POWER_VALUE"


SENSOR_AVERAGE_CPU_FREQ_NAME="average_cpu_freq"
SENSOR_AVERAGE_CPU_FREQ_VALUE=`get_average_cpu_freq`
echo "$SENSOR_AVERAGE_CPU_FREQ_NAME: $SENSOR_AVERAGE_CPU_FREQ_VALUE"

$MQTT_TOOL_PUB -d -q 1 -h $THINGBOARD_HOST -t "v1/devices/me/telemetry" -u $ACCESS_TOKEN \
-m "{\
      ${SENSOR_NAME}:${SENSOR_VALUE},\
      ${SENSOR_POWER_NAME}:${SENSOR_POWER_VALUE},\
      ${SENSOR_AVERAGE_CPU_FREQ_NAME}:${SENSOR_AVERAGE_CPU_FREQ_VALUE}\
    }"




#TODO
# Get power usage
# Get coin avaibale
# Get CPU clock