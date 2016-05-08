task_help() {
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
  echo "AVailable global tasks:"
  echo
  declare -F  | grep -e 'declare -fr task_' | sed 's/declare -fr task_/     /' | tr '\n' ' '
  echo
  echo
  echo "AVailable local tasks:"
  echo
  declare -F  | grep -e "declare -f task_" | sed 's/declare -f task_/     /' | tr '\n' ' '
  echo
  echo
}

task_init() {
  if [[ -z "$ARG_DIR" ]]
  then
    ARG_DIR=$RUNNING_DIR
  fi
  cat > $ARG_DIR/tasks.sh << EOF
task_edit() {
  vim $ARG_DIR/tasks.sh
}
EOF
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
  fi
}

task_export() {
  echo "TODO: add export to a script file"
}
