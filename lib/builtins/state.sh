arguments_state() {
  SUBCOMMANDS='show|set|unset|edit|clean'

  SHOW_DESCRIPTION="Show current variables"

  EDIT_DESCRIPTION="Edit a the current context variables"

  SET_DESCRIPTION="Set a variable in the current tasks context"
  SET_REQUIREMENTS='key:k:str value:v:str'

  UNSET_DESCRIPTION="Unset a variable in the current context"
  UNSET_REQUIREMENTS='key:k:str'

  CLEAN_DESCRIPTION="Clean up stale location and state files."
}

task_state() {
  if [[ $TASK_SUBCOMMAND == "show" ]]
  then
    state_show
  elif [[ $TASK_SUBCOMMAND == "set" ]]
  then
    state_set
  elif [[ $TASK_SUBCOMMAND == "unset" ]]
  then
    state_unset
  elif [[ $TASK_SUBCOMMAND == "edit" ]]
  then
    state_edit
  elif [[ $TASK_SUBCOMMAND == "clean" ]]
  then
    state_clean
  fi
}

state_show() {
  cat "$STATE_FILE"
}

state_edit() {
  $DEFAULT_EDITOR "$STATE_FILE"
}

state_set() {
  local STATE_FILE=$TASK_MASTER_HOME/state/$ARG_COMMAND.vars
  persist_var "$ARG_KEY" "$ARG_VALUE"
  echo "Saved $ARG_KEY in $STATE_FILE"
}

state_unset() {
  local STATE_FILE=$TASK_MASTER_HOME/state/$ARG_COMMAND.vars
  remove_var "$ARG_KEY" "$ARG_VALUE"
  echo "Removed $ARG_KEY from $STATE_FILE"
}


state_clean() {
  echo "Removing nonexistant locations from locations file..."
  sed 's/.*=\(.*\)/\1/' "$LOCATION_FILE" | while IFS= read -r file
  do
    if [[ ! -d "$file" ]]
    then
      grep -v "$file" "$LOCATION_FILE" > "$LOCATION_FILE.tmp"
      mv "$LOCATION_FILE.tmp" "$LOCATION_FILE"
    fi
  done

  echo "Cleaning state files from tasks files not in $LOCATION_FILE"
  for file in "$TASK_MASTER_HOME/state/"*
  do
    if [[ -d "$file" ]]
    then
      if ! grep -q "$file" "$LOCATION_FILE"
      then
        echo "Removing $file..."
        rm -r "$file"
      fi
    fi
  done

  echo "Removing empty files from state directory..."
  local empty_files
  empty_files=$(find "$TASK_MASTER_HOME/state/"* -type f -empty)
  if [[ -n "$empty_files" ]]
  then
    rm "$empty_files"
  fi
}

readonly -f arguments_state
readonly -f task_state
readonly -f state_show
readonly -f state_set
readonly -f state_unset
readonly -f state_edit
readonly -f state_clean
