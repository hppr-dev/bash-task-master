arguments_global() {
  SUBCOMMANDS='debug|set|unset|edit|clean|driver'

  DEBUG_DESCRIPTION="Show variables for a command"
  DEBUG_OPTIONS='command:c:str'

  SET_DESCRIPTION="Set a variable for a command"
  SET_REQUIREMENTS='key:k:str value:v:str command:c:str'

  UNSET_DESCRIPTION="Unset a variable for a command"
  UNSET_REQUIREMENTS='key:k:str command:c:str'

  EDIT_DESCRIPTION="Edit a command's variables"
  EDIT_REQUIREMENTS='command:c:str'

  CLEAN_DESCRIPTION="Clean up stale location and state files."
}

task_global() {
  if [[ $TASK_SUBCOMMAND == "debug" ]]
  then
    global_debug
  elif [[ $TASK_SUBCOMMAND == "set" ]]
  then
    global_set
  elif [[ $TASK_SUBCOMMAND == "unset" ]]
  then
    global_unset
  elif [[ $TASK_SUBCOMMAND == "edit" ]]
  then
    global_edit
  elif [[ $TASK_SUBCOMMAND == "clean" ]]
  then
    global_clean
  fi
}

global_debug() {
  if [[ -n "$ARG_COMMAND" ]]
  then
    for f in "$STATE_DIR/$ARG_COMMAND.vars"*
    do
      echo "==================== $f ======================"
      cat "$f"
    done
  else
    for f in "$TASK_MASTER_HOME/state/"***.vars*
    do
      echo "==================== $f ======================"
      cat "$f"
    done
  fi
}

global_set() {
  local STATE_FILE=$TASK_MASTER_HOME/state/$ARG_COMMAND.vars
  persist_var "$ARG_KEY" "$ARG_VALUE"
  echo "Value saved, variables for $ARG_COMMAND :"
  global_debug
}

global_unset() {
  local STATE_FILE=$TASK_MASTER_HOME/state/$ARG_COMMAND.vars
  remove_var "$ARG_KEY" "$ARG_VALUE"
  echo "Value removed, variables for $ARG_COMMAND :"
  global_debug
}

global_edit() {
    $DEFAULT_EDITOR "$TASK_MASTER_HOME/state/$ARG_COMMAND.vars"
}

global_clean() {
  echo "Removing nonexistant locations from locations file..."
  sed 's/.*=\(.*\)/\1/' "$LOCATIONS_FILE" | while IFS= read -r file
  do
    if [[ ! -d "$file" ]]
    then
      grep -v "$file" "$LOCATIONS_FILE" > "$LOCATIONS_FILE.tmp"
      mv "$LOCATIONS_FILE.tmp" "$LOCATIONS_FILE"
    fi
  done

  echo "Cleaning state files from tasks files not in $LOCATIONS_FILE"
  for file in "$TASK_MASTER_HOME/state/"*
  do
    if [[ -d "$file" ]]
    then
      if ! grep -q "$file" "$LOCATIONS_FILE"
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

readonly -f task_global
readonly -f global_debug
readonly -f global_set
readonly -f global_unset
readonly -f global_edit
readonly -f global_clean
