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
    echo Could not file local task file, only loading global
    TASKS_FILE=$GLOBAL_TASKS_FILE
  fi

  #Parse arguments
  local TASK_COMMAND=$1
  # All arguments after the command will be parsed into environment variables
  # Only long arguments can be used
  while [[ $# > 1 ]]
  do
    shift
    local ARGUMENT=$1
    if [[ $ARGUMENT =~ ^--[a-z]*$ ]]
    then
      local TRANSLATE_ARG=${ARGUMENT//-}
      TRANSLATE_ARG=${TRANSLATE_ARG^^}
      if [[ -z "$2" ]] || [[ "$2" =~ ^--[a-z]$ ]]
      then
        local ARG_$TRANSLATE_ARG='1'
      else
        shift
        local ARG_$TRANSLATE_ARG="$1"
      fi
    elif [[ $ARGUMENT =~ ^[a-z]*$ ]] && [[ -z "$TASK_SUBCOMMAND" ]]
    then
      local TASK_SUBCOMMAND=$ARGUMENT
    elif [[ $ARGUMENT =~ ^[a-z]*$ ]] && [[ ! -z "$TASK_SUBCOMMAND" ]]
    then
      echo "Only one subcommand is allowed"
      echo "Got $TASK_SUBCOMMAND as a subcommand, and also got $ARGUMENT"
      popd > /dev/null
      return
    else
      echo "Only long arguments are allowed"
      echo "Try using something like '--arg value' that will be translated to \$ARG=value in the task script."
      popd > /dev/null
      return
    fi
  done


  local STATE_FILE=$TASK_MASTER_HOME/state/$TASK_COMMAND.vars

  #Run requested task in subshell
  (
    for f in  $TASK_MASTER_HOME/lib/*.sh ; do source $f ; done
    load_state

    # Load global
    . $GLOBAL_TASKS_FILE
    # Read function defs so that lib functions can't be overwritten
    . $GLOBAL_FUNCTION_DEFS

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

    local TASK_NAME=task_$TASK_COMMAND
    type $TASK_NAME &> /dev/null
    if [ "$?" == "0" ]
    then
      echo "Running $TASK_COMMAND task..."
      $TASK_NAME
    else
      echo "Can't find $TASK_COMMAND task in the global or local tasks file"
      echo "Available command are:"
      task list
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


