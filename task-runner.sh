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

  local TASK_AWK_DIR=$TASK_MASTER_HOME/awk
  local GLOBAL_TASKS_FILE=$TASK_MASTER_HOME/global.sh
  local GLOBAL_FUNCTION_DEFS=$TASK_MASTER_HOME/lib-functions.sh
  local TASKS_DIR=$RUNNING_DIR
  local TASKS_FILE=$TASKS_DIR/tasks.sh
  local LOCATIONS_FILE=$TASK_MASTER_HOME/state/locations.vars


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
    local RUNNING_GLOBAL=1
  fi


  local TASK_COMMAND=$1

  # Load Local Task UUID
  local $(awk '/^LOCAL_TASKS_UUID=[^$]*$/{print} 0' $TASKS_FILE) > /dev/null
  if [[ -z "$LOCAL_TASKS_UUID" ]] && [[ "$RUNNING_GLOBAL" != "1" ]]
  then
    echo "Warning: Could not find tasks UUID in $TASKS_FILE file"
  fi
  local STATE_DIR="$TASK_MASTER_HOME/state/$LOCAL_TASKS_UUID"
  local STATE_FILE=$STATE_DIR/$TASK_COMMAND.vars

  #Run requested task in subshell
  (
    # load global functions only in originating shell
    if [[ "$BASH_SUBSHELL" == "1" ]]
    then
      for f in  $TASK_MASTER_HOME/lib/*.sh ; do source $f ; done
      # Load global
      . $GLOBAL_TASKS_FILE
      global_check-defs
    fi

    load_state

    #Load local tasks
    if [[ "$RUNNING_GLOBAL" != "1" ]]
    then
      . $TASKS_FILE
    fi

    #Parse and validate arguments
    unset TASK_SUBCOMMAND
    parse_args_for_task "$@"
    if [[ "$?" == "1" ]]
    then
      return 
    fi
    validate_args_for_task
    if [[ "$?" == "1" ]]
    then
      return 
    fi

    local TASK_NAME=task_$TASK_COMMAND
    type $TASK_NAME &> /dev/null
    if [[ "$?" == "0" ]]
    then
      echo "Running $TASK_COMMAND:$TASK_SUBCOMMAND task..."
      $TASK_NAME
    else
      echo "Invalid task: $TASK_COMMAND"
      task_list
    fi
  )

  #This needs to be here because it interacts with the outside
  if [[ -f $STATE_FILE ]]
  then
    grep -e "TASK_RETURN_DIR" $STATE_FILE > /dev/null
    if [[ "$?" == "0" ]]
    then
      eval $(grep -e "TASK_RETURN_DIR" $STATE_FILE)
      local retdir=${TASK_RETURN_DIR//\'}
      cd ${retdir//\"}
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


