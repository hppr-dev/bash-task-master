source $TASK_MASTER_HOME/lib/global-lib.sh
source $TASK_MASTER_HOME/lib/process.sh
source $TASK_MASTER_HOME/lib/record.sh
source $TASK_MASTER_HOME/lib/lib-arguments.sh

task_help() {
  if [[ ! -z "$TASK_SUBCOMMAND" ]]
  then
    type arguments_$TASK_SUBCOMMAND &> /dev/null
    if [[ "$?" == "0" ]]
    then 
      echo
      arguments_$TASK_SUBCOMMAND
      reqname=${TASK_SUBCOMMAND^^}_REQUIREMENTS
      optname=${TASK_SUBCOMMAND^^}_OPTIONS
      descname=${TASK_SUBCOMMAND^^}_DESCRIPTION
      if [[ "${SUBCOMMANDS/\|\|/}" != "$SUBCOMMANDS" ]] || [[ ! -z "${!reqname}" ]] || [[ ! -z "${!optname}" ]] || [[ ! -z "${!descname}" ]]
      then
        echo "Command: task $TASK_SUBCOMMAND"
        TASK_SUBCOMMAND=${TASK_SUBCOMMAND//-/_}
        if [[ ! -z "${!descname}" ]]
        then
          echo "  ${!descname}"
        else
          echo "  No description available"
        fi
        if [[ ! -z "${!reqname}" ]]
        then
          echo "  Required:"
          for req in ${!reqname}
          do
            arg_spec=${req%:*}
            echo "    --${arg_spec%:*}, -${arg_spec#*:} ${req##*:}"
          done
        fi
        if [[ ! -z "${!optname}" ]]
        then
          echo "  Optional:"
          for opt in ${!optname}
          do
            arg_spec=${opt%:*}
            if [[ "${opt##*:}" == "bool" ]]
            then
              echo "    --${arg_spec%:*}, -${arg_spec#*:}"
            else
              echo "    --${arg_spec%:*}, -${arg_spec#*:} ${opt##*:}"
            fi
          done
        fi
        echo
      fi
      for sub in ${SUBCOMMANDS//\|/ }
      do 
        echo "Command: task $TASK_SUBCOMMAND $sub"
        sub=${sub//-/_}
        reqname=${sub^^}_REQUIREMENTS
        optname=${sub^^}_OPTIONS
        descname=${sub^^}_DESCRIPTION
        if [[ ! -z "${!descname}" ]]
        then
          echo "  ${!descname}"
        else
          echo "  No description available"
        fi
        if [[ ! -z "${!reqname}" ]]
        then
          echo "  Required:"
          for req in ${!reqname}
          do
            arg_spec=${req%:*}
            echo "    --${arg_spec%:*}, -${arg_spec#*:} ${req##*:}"
          done
        fi
        if [[ ! -z "${!optname}" ]]
        then
          echo "  Optional:"
          for opt in ${!optname}
          do
            arg_spec=${opt%:*}
            if [[ "${opt##*:}" == "bool" ]]
            then
              echo "    --${arg_spec%:*}, -${arg_spec#*:}"
            else
              echo "    --${arg_spec%:*}, -${arg_spec#*:} ${opt##*:}"
            fi
          done
        fi
        echo
      done
      
    else
      echo "No arguments are defined"
    fi
    return
  fi
  HELP_STRING="usage: task subcommand [arguments]

Task Master 0.1: Bash Task Management Utility

This script is used to run custom commands from a single source

Run 'task help' to see this message.

Run 'task list' to list defined tasks.

To write your own commands:

    1. create a tasks.sh file somewhere in your working path above your home i.e. /home/user/workingdir/tasks.sh
    2. write a task definition as a bash script into the tasks.sh file. it must start with 'task_'
    3. run it with 'task mytask' somewhere within your working path i.e. in /home/user/workingdir/myother_folder/ run task mytask

You may also run 'task init [--dir <dir_name>]' to create a local tasks.sh file in the current directory or the directory specified by the --dir option.

Tasks can take long arguments by using the \$ARG_LONG_NAME.
For instance, running 'task get --addr 1324 --local' will set \$ARG_ADDR='1324' and \$ARG_LOCAL='1' for the 'task_get' task

You may also record tasks on command by using 'task record'. run 'task record help' for more details
"

  echo "$HELP_STRING"
}


task_list() {
  if [[ -z "$ARG_GLOBAL$ARG_LOCAL$ARG_ALL" ]]
  then
    ARG_ALL='T'
  fi
  if [[ ! -z "$ARG_GLOBAL$ARG_ALL" ]]
  then
    echo "AVailable global tasks:"
    echo
    declare -F  | grep -e 'declare -fr task_' | sed 's/declare -fr task_/     /' | tr '\n' ' '
    echo
    echo
  fi
  if [[ ! -z "$ARG_LOCAL$ARG_ALL" ]]
  then
    echo "AVailable local tasks:"
    echo
    declare -F  | grep -e "declare -f task_" | sed 's/declare -f task_/     /' | tr '\n' ' '
    echo
    echo
  fi
}


task_init() {
  if [[ -z "$ARG_DIR" ]]
  then
    ARG_DIR=$RUNNING_DIR
  fi
  if [[ -f "$ARG_DIR/tasks.sh" ]]
  then
    echo "Tasks file already exists can't init $ARG_DIR"
    return 1
  fi
  echo "Initializing tasks.sh file in $ARG_DIR..."
  local LOCAL_TASKS_UUID="l$(cat $LOCATIONS_FILE | wc -l)"
  if [[ $ARG_NAME ]]
  then
    LOCAL_TASKS_UUID="$ARG_NAME"
  fi
  echo "LOCAL_TASKS_UUID=$LOCAL_TASKS_UUID" >> $ARG_DIR/tasks.sh
  echo "Creating state directory..."
  mkdir $TASK_MASTER_HOME/state/$LOCAL_TASKS_UUID
  echo "Saving tasks file location to $LOCATIONS_FILE"
  echo "UUID_$LOCAL_TASKS_UUID=$ARG_DIR" >> $LOCATIONS_FILE
}

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

task_record() {

  if [[ ! -z "$ARG_HELP" ]] || [[ $TASK_SUBCOMMAND == "help" ]]
  then 
    record_help
  elif [ $TASK_SUBCOMMAND == "start" ]
  then
    record_start
  elif [ $TASK_SUBCOMMAND == "stop" ]
  then
    record_stop
  elif [ $TASK_SUBCOMMAND == "restart" ]
  then
    record_restart
  elif [ $TASK_SUBCOMMAND == "trash" ]
  then
    record_trash
  else
    echo "Unknown subcommand: $TASK_SUBCOMMAND"
    record_help
  fi
  
}

task_spawn() {
  if [[ ! -z "$ARG_HELP" ]] || [[ $TASK_SUBCOMMAND == "help" ]]
  then 
    spawn_help
  elif [ $TASK_SUBCOMMAND == "start" ]
  then
    spawn_start
  elif [ $TASK_SUBCOMMAND == "stop" ] || [ $TASK_SUBCOMMAND == "kill" ]
  then
    spawn_stop
  elif [ $TASK_SUBCOMMAND == "list" ]
  then
    spawn_list
  elif [ $TASK_SUBCOMMAND == "output" ]
  then
    spawn_output
  elif [ $TASK_SUBCOMMAND == "clean" ]
  then
    spawn_clean
  else
    echo "Unknown subcommand: $TASK_SUBCOMMAND"
    spawn_help
  fi
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

task_export() {
  type task_$ARG_COMMAND &> /dev/null
  if [[ "$?" != "0" ]]
  then
    echo "No Command named $ARG_COMMAND"
    return
  fi
  echo "#!/bin/bash" > $ARG_OUT
  echo "# Autogenerated from Task Master" >> $ARG_OUT
  export_generate_args
  export_main_func
  echo "$arg_parse" >> $ARG_OUT
  echo "$code" >> $ARG_OUT
  chmod +x $ARG_OUT
}

task_edit() {
  local validated=1
  cp $TASKS_FILE $TASKS_FILE.tmp
  while [[ "$validated" != "0" ]]
  do
    vim $TASKS_FILE
    bash -n $TASKS_FILE
    if [[ "$?" != "0" ]]
    then
      validated=1
      echo "Could not validate $TASKS_FILE."
      echo "Changes will be reverted if you choose not to edit again."
      read -p "Edit again (yes or no)?[yes]" ans
      if [[ "$ans" == "no" ]]
      then
        mv $TASKS_FILE.tmp $TASKS_FILE
        validated=0
      fi
    else
      echo "Changes validated."
      validated=0
      rm $TASKS_FILE.tmp
    fi
  done
}
