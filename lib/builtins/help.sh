task_help() {
  source "$DRIVER_DIR/${TASK_DRIVER_DICT[$TASK_FILE_DRIVER]}"
  $DRIVER_HELP_TASK "$TASK_SUBCOMMAND"
  if [[ "$?" == "1" ]]
  then
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
  fi
}

readonly -f task_help
