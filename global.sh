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
  echo "AVailable tasks:"
  echo
  declare -F  | grep task_ | sed 's/declare -f task_/     /' | tr '\n' ' '
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

  NAME=${ARG_NAME,,}
  if [[ -z "$NAME" ]] || [[ $NAME == "1" ]]
  then
     NAME="unnamed"
  fi
  HELP_STRING="usage: task record (start|stop|restart|trash|help)

  This task is designed to create other tasks by recording your bash history

  To start a recording run:

        task record start [--name <task_name>]

  To stop a recording and write it as a task to the local tasks.sh file run:

        task record stop [--name <task_name>]

  To throw away the current recording or old recordings run:

         task record trash [--force]

  To start a new recording after you have started recording run:

         task record restart

  To view this help run

         task record (start|stop|restart|trash) --help
                    or
         task record help"

  #### record help or record (start|stop|restart|trash|help)
  if [[ ! -z "$ARG_HELP" ]] || [[ $TASK_SUBCOMMAND == "help" ]]
  then 
    echo "$HELP_STRING"

  #### record start
  elif [ $TASK_SUBCOMMAND == "start" ]
  then
    record_start
  #### record stop
  elif [ $TASK_SUBCOMMAND == "stop" ]
  then
    record_stop
  #### record restart
  elif [ $TASK_SUBCOMMAND == "restart" ]
  then
    record_restart
  ### record trash
  elif [ $TASK_SUBCOMMAND == "trash" ]
  then
    record_trash
  else
    echo "Unknown subcommand: $TASK_SUBCOMMAND"
    echo "$HELP_STRING"
  fi
  
}

