arguments_global() {
  SUBCOMMANDS='debug|set|unset|edit|clean|locations|uuid'

  SET_DESCRIPTION="Set a variable for a command"
  SET_REQUIREMENTS='key:k:str value:v:str command:c:str'

  UNSET_DESCRIPTION="Unset a variable for a command"
  UNSET_REQUIREMENTS='key:k:str command:c:str'

  EDIT_DESCRIPTION="Edit a command's variables"
  EDIT_REQUIREMENTS='command:c:str'

  DEBUG_DESCRIPTION="Show variables for a command"
  DEBUG_OPTIONS='command:c:str'

  LOCATIONS_DESCRIPTION="Manage locations"
  LOCATIONS_OPTIONS='list:l:bool del:d:str add:a:str'

  UUID_DESCRIPTION="Check UUIDs"
  UUID_OPTIONS='uuid:u:str update:U:bool check:c:bool'

  CLEAN_DESCRIPTION="Clean up stale location and state files."
}

task_global() {
  if [[ ! -z "$ARG_HELP" ]] || [[ $TASK_SUBCOMMAND == "help" ]]
  then 
    global_help
  elif [[ $TASK_SUBCOMMAND == "debug" ]]
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
  elif [[ $TASK_SUBCOMMAND == "locations" ]]
  then
    global_locations
  elif [[ $TASK_SUBCOMMAND == "uuid" ]]
  then
    global_uuid
  fi
}

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
    $DEFAULT_EDITOR $TASK_MASTER_HOME/state/$ARG_COMMAND.vars
}

global_check-defs() {
  #Check to see if any global functions have been overwritten
  . $GLOBAL_FUNCTION_DEFS  
  if [[ $GLOBAL_TASKS_FILE != $TASKS_FILE ]]
  then
    . $TASKS_FILE
  fi
}

global_clean() {
  echo "Removing nonexistant locations from locations file..."
  for file in $(sed 's/.*=\(.*\)/\1/' $LOCATIONS_FILE)
  do
    if [[ ! -d $file ]]
    then
      grep -v $file $LOCATIONS_FILE > $LOCATIONS_FILE.tmp
      mv $LOCATIONS_FILE.tmp $LOCATIONS_FILE
    fi
  done
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
}

global_locations() {
  if [[ ! -z "$ARG_LIST" ]] || ( [[ -z "$ARG_DEL" ]] && [[ -z "$ARG_ADD" ]] )
  then
    cat $LOCATIONS_FILE
  elif [[ ! -z "$ARG_DEL" ]]
  then
    awk -i inplace "/^UUID_$ARG_DEL=.*/{next} 1" $LOCATIONS_FILE
  elif [[ ! -z "$ARG_ADD" ]]
  then
    if [[ -z "$(grep -e "UUID_$ARG_ADD=" $LOCATIONS_FILE)" ]]
    then
      echo "UUID_$ARG_ADD=$RUNNING_DIR" >> $LOCATIONS_FILE
    else
      echo "Can't add $ARG_ADD to locations, it already exists"
    fi
  fi
}

global_uuid(){
  if [[ -z "$ARG_UUID" ]]
  then
    ARG_UUID=$LOCAL_TASKS_UUID
  fi

  local uuid_ok='OK.'
  local location_name=UUID_$ARG_UUID
  local location_statement=$(grep -e $location_name $LOCATIONS_FILE)
  # Verify the following:
  
  # UUID is defined
  if [[ -z "$location_statement" ]] 
  then
    echo "UUID $ARG_UUID not defined"
    uuid_ok="NOT OK. Run 'task global uuid -U 'to fix."
    if [[ ! -z "$ARG_UPDATE" ]] && [[ "$ARG_UUID" == "$LOCAL_TASKS_UUID" ]]
    then
      if [[ ! -z "$(grep -E "^UUID_.*=$TASKS_DIR$" $LOCATIONS_FILE)" ]]
      then
        echo "Found previous location in location.vars, Updating..."
        grep -vE "^UUID_.*=$TASKS_DIR$" $LOCATIONS_FILE > $LOCATIONS_FILE.tmp
        location_statement="$location_name=$TASKS_DIR"
        echo "$location_statement" >> $LOCATIONS_FILE.tmp
        mv $LOCATIONS_FILE.tmp $LOCATIONS_FILE
        uuid_ok="OK. You may need to run 'task global clean' to remove orphaned state directories"
      else
        echo "Adding location to in location.vars..."
        location_statement="$location_name=$TASKS_DIR"
        echo "$location_statement" >> $LOCATIONS_FILE
        uuid_ok="OK. You may need to run 'task global clean' to remove orphaned state directories"
      fi
    elif [[ ! -z "$ARG_UPDATE" ]]
    then
      echo "Can't update $ARG_UUID because the uuid is does not define the local scope."
      echo "Try running 'task global uuid -U' from where the tasks.sh defines LOCAL_TASKS_UUID."
    fi
  fi

  eval "$location_statement"
  # Verify state directory exists
  if [[ -f "${!location_name}/tasks.sh" ]] && [[ ! -d "$TASK_MASTER_HOME/state/$ARG_UUID" ]]
  then
    echo "State directory doesn't exist"
    uuid_ok="NOT OK. Run 'task global uuid -U 'to fix."
    if [[ ! -z "$ARG_UPDATE" ]]
    then
      echo "Creating $TASK_MASTER_HOME/state/$ARG_UUID/"
      mkdir $TASK_MASTER_HOME/state/$ARG_UUID
      uuid_ok='OK.'
    fi
  fi

  # UUID_$ARG_UUID in location.vars matches where it is defined in the task file
  if [[ -f "${!location_name}/tasks.sh" ]] && [[ -z "$(grep ${!location_name}/tasks.sh -e "LOCAL_TASKS_UUID=$ARG_UUID")" ]]
  then
    echo "$ARG_UUID does not match tasks file location"
    uuid_ok="NOT OK. Run 'task global uuid -U 'to fix."
    if [[ ! -z "$ARG_UPDATE" ]]
    then
      echo "Updating location in location.vars..."
      awk -i inplace "/^UUID_.*=${!location_name}$/{next} 1" $LOCATIONS_FILE
      echo "$location_name=${!location_name}" >> $LOCATIONS_FILE
      uuid_ok='OK.'
    fi
  fi

  if [[ ! -f "${!location_name}/tasks.sh" ]]
  then
    echo "Tasks file does not exist."
    echo "If ${!location_name} is a tasks directory then it is NOT OK. Use 'task global locations' task to fix"
    echo "If this is a bookmark location, it is OK"
    uuid_ok="POSSIBLY OK. See above"
  fi

  echo "UUID $ARG_UUID is $uuid_ok"
}

readonly -f task_global
readonly -f global_help
readonly -f global_debug
readonly -f global_set
readonly -f global_unset
readonly -f global_edit
readonly -f global_check-defs
readonly -f global_clean
readonly -f global_locations
readonly -f global_uuid
