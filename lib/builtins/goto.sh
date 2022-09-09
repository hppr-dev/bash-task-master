arguments_goto() {
  SUBCOMMANDS="$(sed 's/UUID_\(.*\)=.*/\1|/' "$LOCATIONS_FILE" | tr -d "\n")"
  GOTO_DESCRIPTION="Change directories to a bookmark"
}

task_goto() {
  var_name=UUID_$TASK_SUBCOMMAND
  loc_line=$(grep "^$var_name=.*" "$LOCATIONS_FILE" | head -n1 )
  if [[ -z "$loc_line" ]]
  then
     echo "Unknown location: $TASK_SUBCOMMAND"
     echo "Available locations are:"
     sed 's/^UUID_\(.*\)=.*/\1/' "$LOCATIONS_FILE" | tr -d '\n'
     return 0
  fi
  eval "$loc_line"
  set_return_directory "${!var_name}"
  clean_up_state
}

readonly -f task_goto
readonly -f arguments_goto
