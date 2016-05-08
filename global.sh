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
  declare -F  | grep task_
}

task_init() {
  if [[ -z "$ARG_DIR" ]]
  then
    ARG_DIR=$RUNNING_DIR
  fi
  touch $ARG_DIR/tasks.sh
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

record_start(){
  echo "Starting record..."
  # setup recording file to save context
  globalize "RECORDING_FILE=$TASKS_DIR/.rec_$NAME"
  # save starting directory
  globalize "RECORD_START=$RUNNING_DIR"
  # save name
  globalize "RECORD_NAME=$NAME"
  # Save prompt command and change it to save commands
  globalize 'OLD_PROMPT_COMMAND=$PROMPT_COMMAND'
  globalize PROMPT_COMMAND="'echo \$(history 1 | tr -s \" \" | cut -f 3- -d \" \") >> \$RECORDING_FILE;'"
}

record_stop(){
  if [ ! -z "$RECORDING_FILE" ]
  then
    #Check to see if the user gave a name on record stop
    if [[ ! -z "$NAME" ]] && [[ "$RECORD_NAME" != "$NAME" ]]
    then
      mv $RECORDING_FILE $TASKS_DIR/.rec_$NAME
      RECORDING_FILE=$TASKS_DIR/.rec_$NAME
    elif [[ -z "$NAME" ]] 
    then
      $NAME=$RECORD_NAME
    fi

    # Change prompt back what it was before recording
    globalize 'PROMPT_COMMAND=$OLD_PROMPT_COMMAND'
    echo "Stopped Recording..."

    # Test to see if task is already defined
    type "task_$NAME" &> /dev/null
    if [[ "$?" == "1" ]]
    then
      # Write it to file
      echo "Writing record to $TASKS_FILE : "
      tee -a $TASKS_FILE << EOM
# Recorded Task
task_$NAME() {
    pushd \`pwd\` > /dev/null
    cd $RECORD_START
`tail -n +2 $RECORDING_FILE | sed 's/^/    /'`
    popd > /dev/null
}
EOM
      # cleanup
      rm $RECORDING_FILE
      remove_state
    else
      echo "Wont write to file: task_$NAME already exists"
      echo "Try supplying another name using 'task record stop --name something_else'"
    fi
  else
    echo "You are not recording..."
    echo "Run 'task record start' to start "
  fi
}

record_trash(){
    if [ ! -z "$RECORDING_FILE" ]
    then
      #remove_state first
      remove_state
      #then Change prompt back what it was before recording
      globalize "PROMPT_COMMAND=$OLD_PROMPT_COMMAND"
      # Write it to file
      echo "Trashing record file $RECORDING_FILE"
      # Remove recording file
      rm $RECORDING_FILE
    else
      if [ ! -z "$ARG_FORCE" ]
      then
        echo "Forcing removal of all .rec files in $TASKS_DIR"
        rm -i $TASKS_DIR/.rec_*
      else
        echo "You are not recording..."
        echo "Run 'task record trash --force' to remove all .rec_* files in $TASKS_DIR "
      fi
    fi
}

record_restart(){
    if [ ! -z "$RECORDING_FILE" ]
    then
      # Reset recording file
      echo "Resetting record file..."
      rm $RECORDING_FILE
      echo "Moving back to the start directory..."
      globalize 'cd $RECORD_START'
    else
      echo "You are not recording..."
      echo "Run 'task record start' to start "
    fi
}

globalize() {
  echo $1 >> $STATE_FILE
}

remove_state() {
  if [[ -f $STATE_FILE ]]
  then
    grep $STATE_FILE -e "=" > $STATE_FILE.tmp
    sed -e 's/^\(.*\)=.*$/unset \1/' $STATE_FILE.tmp > $STATE_FILE.tmp
    globalize 'DESTROY_STATE_FILE="1"'
    mv $STATE_FILE.tmp $STATE_FILE
  fi
}
