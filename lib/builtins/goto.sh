task_goto() {
  local location=UUID_$TASK_SUBCOMMAND
  local $(awk "/^$location=.*$/{print} 0" $LOCATIONS_FILE) > /dev/null
  if [[ -z "${!location}" ]]
  then
     echo "Unknown location: $TASK_SUBCOMMAND"
     echo "Available locations are:"
     echo $(sed 's/^UUID_\(.*\)=.*/\1/' $LOCATIONS_FILE)
     return 0
  fi
  set_return_directory ${!location}
  clean_up_state
}

readonly -f task_goto
