global_help() {
  HELP_STRING="Usage: task global (debug|set|unset)
  Used to manipulate/display internal variables

  To see state variables run (specify --command to limit display state for a command):

      task global debug [--comand command]

  To set state variables for a command run (sets KEY=\"Hello\" for the spawn command): 

      task global set --key KEY --value \"Hello\" --command spawn

  To unset state variables for a command run (unsets KEY for the spawn command): 

      task global set --key KEY --command spawn

  To edit state variables for a command run:

      task global edit --command spawn
  "

  echo "$HELP_STRING"
}

arguments_global() {
  SUBCOMMANDS='debug|set|unset|edit|check-defs|clean|locations'
  SET_REQUIREMENTS='key:k:str value:v:str command:c:str'
  UNSET_REQUIREMENTS='key:k:str command:c:str'
  EDIT_REQUIREMENTS='command:c:str'
  DEBUG_OPTIONS='command:c:str'
  LOCATIONS_OPTIONS='list:l:bool del:d:str'
}

global_debug() {
  if [[ ! -z "$ARG_COMMAND" ]]
  then
    for f in $STATE_DIR/$ARG_COMMAND.vars*
    do
      echo ==================== $f ======================
      cat $f
    done
  else
    for f in $TASK_MASTER_HOME/state/***.vars*
    do
      echo ==================== $f ======================
      cat $f
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
    vim $TASK_MASTER_HOME/state/$ARG_COMMAND.vars
}

global_check-defs() {
  #Check to see if any global functions have been overwritten
  . $GLOBAL_FUNCTION_DEFS  
  if [[ $GLOBAL_TASKS_FILE != $TASKS_FILE ]]
  then
    . $TASKS_FILE
  else
    echo "Can't check defs without a local tasks file"
  fi
}

global_clean() {
  echo "Cleaning state files from tasks files not in $LOCATIONS_FILE"
  for file in $TASK_MASTER_HOME/state/*
  do
    if [[ -d "$file" ]]
    then
      if [[ -z "$(awk "/^UUID_${file##*/}=.*/{print} 0" $LOCATIONS_FILE)" ]]
      then
        echo "Removing $file..."
        rm -rf "$file"
      fi
    fi
  done
  echo "Removing empty files from state directory..."
  rm $(find $TASK_MASTER_HOME/state/* -type f -empty) 2> /dev/null
  echo "Removing nonexistant locations from locations file..."
  for file in $(sed 's/.*=\(.*\)/\1/' $LOCATIONS_FILE)
  do
    if [[ ! -d $file ]]
    then
      grep -v $file $LOCATIONS_FILE > $LOCATIONS_FILE.tmp
      mv $LOCATIONS_FILE.tmp $LOCATIONS_FILE
    fi
  done
}

global_locations() {
  if [[ ! -z "$ARG_LIST" ]]
  then
    cat $LOCATIONS_FILE
  elif [[ ! -z "$ARG_DEL" ]]
  then
    awk "/^$ARG_DEL=.*/{next} 1" -i inplace $LOCATIONS_FILE
  fi
}
