#!/bin/bash
#########################################################################################################
# Main Task Runner:
#   Supplies the following environment variables to tasks:
#      - TASKS_DIR = directory of the local tasks.sh file
#      - RUNNING_DIR = directory that the task is being run from
#      - TASK_COMMAND = command that the task is running i.e 'record' in 'task record start'
#      - TASK_SUBCOMMAND = sub command of the running task i.e 'start' in 'task record start'
#      - TASK_NAME = method name of the parent task i.e. 'task_record' for 'task record stop'
#    
#
#   Arguments to commands and subcommands are supplied as long arguments ONLY
#   Arguments are supplied as environment variables to child tasks
#   for instance, running 'task record start --name hello --force' will set ARG_FORCE=1 and ARG_NAME=hello
#
##########################################################################################################
task(){
  # Save directory that you are running it from
  local RUNNING_DIR=`pwd`

  local GLOBAL_TASKS_FILE=$TASK_MASTER_HOME/global.sh
  local GLOBAL_FUNCTION_DEFS=$TASK_MASTER_HOME/lib-functions.sh
  local TASKS_DIR=$RUNNING_DIR
  local TASKS_FILE=$TASKS_DIR/tasks.sh


  # Find tasks.sh file
  while [[ ! -f $TASKS_FILE ]] && [[ "$TASKS_DIR" != "$HOME" ]]
  do 
    cd ..
    TASKS_DIR=`pwd`
    TASKS_FILE=$TASKS_DIR/tasks.sh
  done
  cd $RUNNING_DIR

  if [[ "$TASKS_DIR" == "$HOME" ]]
  then
    TASKS_FILE=$GLOBAL_TASKS_FILE
  fi


  local TASK_COMMAND=$1
  

  local STATE_FILE=$TASK_MASTER_HOME/state/$TASK_COMMAND.vars

  #Run requested task in subshell
  (
    for f in  $TASK_MASTER_HOME/lib/*.sh ; do source $f ; done
    load_state
    #Parse and validate arguments
    parse_args_for_task $@
    validate_args_for_task
    if [[ "$?" == "1" ]]
    then
      return 
    fi

    if [[ "$TASKS_LOADED" != "1" ]]
    then
      export TASKS_LOADED=1
      echo Loading tasks
      # Load global
      . $GLOBAL_TASKS_FILE
      # Read function defs so that lib functions can't be overwritten
      # Assume that if export_var has already been loaded then don't load them again
      type export_var &> /dev/null
      if [[ "$?" == "1" ]]
      then
        . $GLOBAL_FUNCTION_DEFS 
      fi


      #Load local tasks
      if [[ "$TASKS_FILE" != "$GLOBAL_TASKS_FILE" ]]
      then
        . $TASKS_FILE
      fi
      if [[ $? == "1" ]]
      then
        echo "A problem occured when loading tasks"
        echo "It appears that a function or task in the local scope is trying to overwrite a protected function"
        echo "Please rename the above function to proceed"
        echo "If absolutely need to overwrite the function, comment the funciton out in $GLOBAL_FUNCTION_DEFS"
        return
      fi
    fi

    local TASK_NAME=task_$TASK_COMMAND
    type $TASK_NAME &> /dev/null
    if [[ "$?" == "0" ]]
    then
      echo "Running $TASK_COMMAND:$TASK_SUBCOMMAND task..."
      $TASK_NAME
    else
      echo "Can't find $TASK_COMMAND task in the global or local tasks file"
      echo "Available command are:"
      task_list
    fi
  )

  #This needs to be here because it interacts with the outside
  if [[ -f $STATE_FILE ]]
  then
    grep $STATE_FILE -e TASK_RETURN_DIR > /dev/null
    if [[ "$?" == "0" ]]
    then
      $(grep $STATE_FILE -e TASK_RETURN_DIR)
      cd $TASK_RETURN_DIR
    fi
    grep $STATE_FILE -e DESTROY_STATE_FILE > /dev/null
    if [[ "$?" == "0" ]]
    then
      rm $STATE_FILE
    fi
  fi
  if [[ -f $STATE_FILE.export ]]
  then
    source $STATE_FILE.export
    rm $STATE_FILE.export
  fi
}


