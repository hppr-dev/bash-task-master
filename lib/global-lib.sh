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
    vim $TASK_MASTER_HOME/state/$ARG_COMMAND.vars
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

export_generate_args() {
  arg_parse="while [[ \$# -ge 1 ]]
do
  case \$1 in"
  type arguments_$ARG_COMMAND &> /dev/null
  if [[ "$?" == "0" ]]
  then 
    arguments_$ARG_COMMAND
    reqname=${ARG_COMMAND^^}_REQUIREMENTS
    optname=${ARG_COMMAND^^}_OPTIONS
    if [[ "${SUBCOMMANDS/\|\|/}" != "$SUBCOMMANDS" ]] || [[ ! -z "${!reqname}" ]] || [[ ! -z "${!optname}" ]] 
    then
      if [[ ! -z "${!reqname}" ]]
      then
        for req in ${!reqname}
        do
          arg_spec=${req%:*}
          arg_name=${arg_spec%:*}
          long_arg="--${arg_name}"
          short_arg="-${arg_spec#*:}"
          arg_type=${req##*:}
          update_arg_parse
        done
      fi
      if [[ ! -z "${!optname}" ]]
      then
        for opt in ${!optname}
        do
          arg_spec=${opt%:*}
          arg_name=${arg_spec%:*}
          long_arg="--${arg_name}"
          short_arg="-${arg_spec#*:}"
          arg_type=${opt##*:}
          update_arg_parse
        done
      fi
      echo
    fi
    for sub in ${SUBCOMMANDS//\|/ }
    do 
      sub=${sub//-/_}
      reqname=${sub^^}_REQUIREMENTS
      optname=${sub^^}_OPTIONS
      if [[ ! -z "${!reqname}" ]]
      then
        for req in ${!reqname}
        do
          arg_spec=${req%:*}
          arg_name=${arg_spec%:*}
          long_arg="--${arg_name}"
          short_arg="-${arg_spec#*:}"
          arg_type=${req##*:}
          update_arg_parse
        done
      fi
      if [[ ! -z "${!optname}" ]]
      then
        for opt in ${!optname}
        do
          arg_spec=${opt%:*}
          arg_name=${arg_spec%:*}
          long_arg="--${arg_name}"
          short_arg="-${arg_spec#*:}"
          arg_type=${opt##*:}
          update_arg_parse
        done
      fi
    done
    arg_parse="$arg_parse
  *)
    TASK_SUBCOMMAND=\$1
    shift
    ;;
  esac
done
"
  else
    echo "No arguments are defined"
    arg_parse=""
  fi
}

export_main_func() {
  echo "NOTE: Export will only search for function definitions one deep"
  code="$(type task_$ARG_COMMAND | tail -n +2)" 
  main_code=""
  while read -r line
  do
    i=$(echo "$line" | awk '{print $1}')
    utility_code="$(type "${i//;/}" 2> /dev/null | tail -n +4 | head -n -1)" &> /dev/null
    if [[ ! -z "$utility_code" ]] && [[ ! "task_$ARG_COMMAND ()*" =~ "$line" ]]
    then
      main_code="$main_code
$utility_code"
    elif [[ "task_$ARG_COMMAND ()*" =~ "$line" ]]
    then
      main_code="$main_code
exported_task ()"
    else
      main_code="$main_code
$line"
    fi
  done <<< "$code"
  # Read in exported code
  eval "$main_code"
  code="$(type exported_task | tail -n +4 | head -n -1 | sed 's/^    //')"
}

update_arg_parse() {
  if [[ "$arg_type" == "bool" ]]
  then
    arg_parse="$arg_parse
  $short_arg|$long_arg)
    ARG_${arg_name^^}=T
    shift
    ;;"
  else
    arg_parse="$arg_parse
  $short_arg|$long_arg)
    ARG_${arg_name^^}=\$2
    shift
    shift
    ;;"
  fi
}
