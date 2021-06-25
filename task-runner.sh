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
#   Arguments are supplied as environment variables to child tasks
#   for instance, running 'task record start --name hello --force' will set ARG_FORCE=1 and ARG_NAME=hello
#
##########################################################################################################
task(){

  # Check for special verbose argument
  unset GLOBAL_VERBOSE
  if [[ "$1" == "+v" || "$1" == "+verbose" ]]
  then
    echo "GLOBAL VERBOSE SET"
    GLOBAL_VERBOSE=1
    shift
  fi

  # Save directory that you are running it from
  local RUNNING_DIR=$(pwd)

  local TASK_AWK_DIR=$TASK_MASTER_HOME/awk
  local GLOBAL_TASKS_FILE=$TASK_MASTER_HOME/global.sh
  local GLOBAL_FUNCTION_DEFS=$TASK_MASTER_HOME/lib/global-function-defs.sh
  local TASKS_DIR=$RUNNING_DIR
  local TASKS_FILE=$TASKS_DIR/tasks.sh
  local HIDDEN_TASKS_FILE=$TASKS_DIR/.tasks.sh
  local LOCATIONS_FILE=$TASK_MASTER_HOME/state/locations.vars
  local ARG_FORMAT=bash

  # Find tasks.sh file
  while [[ ! -f "$TASKS_FILE" ]] && [[ ! -a "$HIDDEN_TASKS_FILE" ]] && [[ "$TASKS_DIR" != "$HOME" ]]
  do 
    cd ..
    TASKS_DIR=$(pwd)
    TASKS_FILE=$TASKS_DIR/tasks.sh
    HIDDEN_TASKS_FILE=$TASKS_DIR/.tasks.sh
  done

  _tmverbose_echo "Tasks file: $TASKS_FILE in $TASKS_DIR"

  if [[ ! -f "$TASKS_FILE" ]]
  then
    TASKS_FILE=$HIDDEN_TASKS_FILE
  fi
  cd $RUNNING_DIR

  if [[ "$TASKS_DIR" == "$HOME" ]] || [[ "$TASKS_DIR" == "/" ]]
  then
    TASKS_FILE=$GLOBAL_TASKS_FILE
    local RUNNING_GLOBAL="1"
    _tmverbose_echo "Switching to global: $TASKS_FILE"
  fi

  local TASK_COMMAND=$1
  local TASK_SUBCOMMAND=""

  # Load Local Task UUID
  local $(awk '/^LOCAL_TASKS_UUID=[^$]*$/{print} 0' $TASKS_FILE) > /dev/null
  if [[ -z "$LOCAL_TASKS_UUID" ]] && [[ "$RUNNING_GLOBAL" != "1" ]]
  then
    echo "Warning: Could not find tasks UUID in $TASKS_FILE file"
  fi
  local STATE_DIR="$TASK_MASTER_HOME/state/$LOCAL_TASKS_UUID"
  local STATE_FILE=$STATE_DIR/$TASK_COMMAND.vars
  
  _tmverbose_echo "State Dir: $STATE_DIR\nState file: $STATE_FILE"

  #Run requested task in subshell
  (
    _tmverbose_echo "Task master has called itself ${RUN_NUMBER:-0} times"

    if [[ -z "$RUN_NUMBER" ]]
    then
      RUN_NUMBER=1
    else
      RUN_NUMBER=2
    fi

    # load global tasks file only in originating shell
    if [[ "$RUN_NUMBER" == "1" ]]
    then
      _tmverbose_echo "Loading internal functions"

      . $TASK_MASTER_HOME/lib/state.sh
      . $TASK_MASTER_HOME/lib/validate-args.sh
      . $GLOBAL_TASKS_FILE
    fi

    load_state

    #Load local tasks if the desired task isn't loaded
    if ([[ "$TASK_COMMAND" == "list" ]] || [["$TASK_COMMAND" == "export" ]] || [[ "$(type -t task_$TASK_COMMAND)" != "function" ]]) && [[ "$RUNNING_GLOBAL" != "1" ]] 
    then
      _tmverbose_echo "Sourcing tasks file"
      . $TASKS_FILE
    fi

    if [[ "$TASK_COMMAND" == "list" ]]
    then
      ARG_FORMAT=bash
    fi

    #Parse and validate arguments
    unset TASK_SUBCOMMAND
    parse_args_for_task "$@"
    if [[ "$?" == "1" ]]
    then
      _tmverbose_echo "Parsing of task args returned 1, exiting..."
      return 
    fi

    validate_args_for_task
    if [[ "$?" == "1" ]]
    then
      _tmverbose_echo "Validation of task args returned 1, exiting..."
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
    # Deal with persisted return directory
    grep -e "TASK_RETURN_DIR" $STATE_FILE > /dev/null
    if [[ "$?" == "0" ]]
    then
      eval $(grep -e "TASK_RETURN_DIR" $STATE_FILE)
      local retdir=${TASK_RETURN_DIR//\'}
      cd ${retdir//\"}
      _tmverbose_echo "Returning to the directory $retdir which was specified in the state file: $STATE_FILE"
    fi

    # Deal with setting an exit trap to clean up after leaving the terminal
    grep -e "TASK_TERM_TRAP" $STATE_FILE > /dev/null
    if [[ "$?" == "0" ]]
    then
      eval $(grep -e "TASK_TERM_TRAP" $STATE_FILE)
      trap "$TASK_TERM_TRAP" EXIT
      _tmverbose_echo "Setting trap $TASK_TERM_TRAP for terminal exit. Specified by $STATE_FILE"
    fi

    # Destroy state file if it is marked as such
    grep $STATE_FILE -e DESTROY_STATE_FILE > /dev/null
    if [[ "$?" == "0" ]]
    then
      rm $STATE_FILE
      _tmverbose_echo "Removing $STATE_FILE because it was marked with DESTROY_STATE_FILE"
    fi
  fi

  if [[ -f $STATE_FILE.export ]]
  then
    source $STATE_FILE.export
    rm $STATE_FILE.export
    _tmverbose_echo "Found $STATE_FILE.export as a state file export, loaded and removed it"
  fi
}

_tmverbose_echo(){
  if [[ ! -z "$GLOBAL_VERBOSE" ]]
  then
    echo -e $1
  fi
}

_TaskTabCompletion(){
    local tasks=$(task list | grep -v Available | grep -v Running)
    local cur=${COMP_WORDS[COMP_CWORD]}  
    local word=${COMP_WORDS[$COMP_CWORD-1]}
    local aliases="$(alias | grep task | sed "s/alias \(.*\)='task'/\1/")"
    if [[ "$word" == "task" ]] || [[ "$word" == "help" ]] || [[ "$aliases" == *"$word"* ]]
    then
      COMPREPLY=($( compgen -W "$tasks" -- "$cur" ))
    fi
}

complete -F _TaskTabCompletion -o bashdefault -o default task
