source $TASK_MASTER_HOME/lib/builtin-tasks.sh
source $TASK_MASTER_HOME/modules/venv-module.sh

arguments_display() {
  SUBCOMMANDS="on|off"
  ON_DESCRIPTION="Turn external display on if it's connected"
  OFF_DESCRIPTION="Turn external display off"
}

#task_display() {
#  connected=$(cat /sys/class/drm/card0-DP-3/status)
#  
#  export DISPLAY=":0.0"
#  if [[ $connected == "connected" ]] && [[ $TASK_SUBCOMMAND == "on" ]]
#  then
#      xrandr --output DP2-1 --above eDP1 --auto
#  elif [[ $connected == "connected" ]] && [[ $TASK_SUBCOMMAND == "off" ]] 
#  then
#      xrandr --output DP2-1 --off
#  else [[ $connectd != "connected" ]]
#      xrandr --output DP2-1 --off
#  fi
#}

