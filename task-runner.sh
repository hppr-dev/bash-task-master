#!/bin/bash
task(){
  # ALL OF THE FOLLOWING VARIABLES ARE AVAILABLE TO TASK SUBSHELLS
  local RUNNING_DIR
  local TASK_AWK_DIR
  local GLOBAL_TASKS_FILE
  local TASKS_DIR
  local TASKS_FILE
  local DRIVER_DIR
  local TASK_FILE_DRIVER
  local TASK_DRIVER
  local LOCATIONS_FILE
  local TASKS_FILE_NAME
  local TASKS_FILE_FOUND
  local TASK_COMMAND
  local TASK_SUBCOMMAND
  local STATE_DIR
  local STATE_FILE
  local GLOBAL_VERBOSE
  local GLOBAL_TASKS
  local LOCAL_TASKS
  local TASK_DRIVER_DICT
  local TASK_FILE_NAME_DICT

  # Check for special verbose argument
  unset GLOBAL_VERBOSE
  if [[ "$1" == "+v" || "$1" == "+verbose" ]]
  then
    echo "GLOBAL VERBOSE SET"
    GLOBAL_VERBOSE=1
    shift
  fi

  # Load config
  source "$TASK_MASTER_HOME"/config.sh

  # Load task drivers
  source "$TASK_MASTER_HOME"/lib/drivers/driver_defs.sh

  # Save directory that you are running it from
  RUNNING_DIR=$(pwd)
  TASK_AWK_DIR=$TASK_MASTER_HOME/awk
  LOCATIONS_FILE=$TASK_MASTER_HOME/state/locations.vars

  GLOBAL_TASKS_FILE=$TASK_MASTER_HOME/load-global.sh
  TASKS_DIR=$RUNNING_DIR
  TASKS_FILE=""

  DRIVER_DIR=$TASK_MASTER_HOME/lib/drivers
  TASK_DRIVER=bash
  TASK_FILE_DRIVER=$DEFAULT_TASK_DRIVER


  TASKS_FILE_NAME=""
  TASKS_FILE_FOUND=""

  # Find tasks file
  while [[ "$TASKS_DIR" != "$HOME" ]] && [[ -z "$TASKS_FILE_FOUND" ]]
  do
    TASKS_DIR=$(pwd)
    cd ..
    # shellcheck disable=SC2153
    for TASKS_FILE_NAME in "${!TASK_FILE_NAME_DICT[@]}"
    do
      if [[ -f "$TASKS_DIR/$TASKS_FILE_NAME" ]]
      then
        TASKS_FILE=$TASKS_DIR/$TASKS_FILE_NAME
	      TASK_FILE_DRIVER=${TASK_FILE_NAME_DICT[$TASKS_FILE_NAME]}
	      TASKS_FILE_FOUND="T"
	      break
      fi
    done
  done

  _tmverbose_echo "Tasks file: $TASKS_FILE in $TASKS_DIR"

  cd "$RUNNING_DIR" || return 1

  TASK_COMMAND=$1
  TASK_SUBCOMMAND=""

  # Load Local Task UUID
  if [[ -n "$TASKS_FILE_FOUND" ]]
  then
    local "$(awk '/^LOCAL_TASKS_UUID=[^$]*$/{print} 0' "$TASKS_FILE")" &> /dev/null
    if [[ -z "$LOCAL_TASKS_UUID" ]]
    then
      echo "Warning: Could not find tasks UUID in $TASKS_FILE file"
    fi
  fi

  STATE_DIR="$TASK_MASTER_HOME/state/$LOCAL_TASKS_UUID"
  STATE_FILE=$STATE_DIR/$TASK_COMMAND.vars
  
  _tmverbose_echo "State Dir: $STATE_DIR\nState file: $STATE_FILE"

  if [[ ! -d "$STATE_DIR" ]]
  then
    mkdir "$STATE_DIR"
  fi

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

      source "$TASK_MASTER_HOME"/lib/state.sh
      source "$GLOBAL_TASKS_FILE"

      GLOBAL_TASKS=$(declare -F  | grep -e 'declare -fr task_' | sed 's/declare -fr task_//' | tr '\n' '|')
      GLOBAL_TASKS=${GLOBAL_TASKS%?}
    fi

    load_state

    task_in() {
      [[ -n "$1" ]] && [[ "$TASK_COMMAND" =~ $1 ]]
    }

    # Check if task is already loaded
    if task_in "$GLOBAL_TASKS"
    then
      TASK_DRIVER=bash
    else
      TASK_DRIVER=$TASK_FILE_DRIVER
    fi

    _tmverbose_echo "Loading $TASK_DRIVER as task driver"
    # This should set commands for DRIVER_EXECUTE_TASK DRIVER_HELP_TASK and DRIVER_LIST_TASK
    source "$DRIVER_DIR/${TASK_DRIVER_DICT[$TASK_DRIVER]}"
    if [[ -z "$DRIVER_EXECUTE_TASK" ]] || [[ -z "$DRIVER_LIST_TASKS" ]] || [[ -z "$DRIVER_HELP_TASK" ]] || [[ -z "$DRIVER_VALIDATE_TASKS_FILE" ]]
    then
      echo Driver implementation error.
      echo "$TASK_DRIVER is missing required definitions"
      return 1
    fi

    LOCAL_TASKS=$( $DRIVER_LIST_TASKS "$TASKS_FILE" | tr '  \n' '|' )
    LOCAL_TASKS=${LOCAL_TASKS%?}
    if task_in "$GLOBAL_TASKS" || task_in "$LOCAL_TASKS"
    then
      $DRIVER_EXECUTE_TASK "$@"
    else
      echo "Invalid task: $TASK_COMMAND"
      task_list
      return 1
    fi
  )

  local subshell_ret=$?

  #This needs to be here because it interacts with the outside
  if [[ -f "$STATE_FILE" ]] && grep -q -e TASK_RETURN_DIR -e TASK_TERM_TRAP -e DESTROY_STATE_FILE "$STATE_FILE"
  then
    awk -F = -f "$TASK_MASTER_HOME"/awk/special_state_vars.awk "$STATE_FILE" >> "$STATE_FILE.export"

    awk '/^TASK_RETURN_DIR|^TASK_TERM_TRAP|^DESTROY_STATE_FILE/ { next } { print }' "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE"{.tmp,} 

    _tmverbose_echo "Added export commands for TASK_RETURN_DIR, TASK_TERM_TRAP or DESTROY_STAE_FILE"
  fi

  if [[ -f $STATE_FILE.export ]]
  then
    source "$STATE_FILE.export"
    rm "$STATE_FILE.export"
    _tmverbose_echo "Found $STATE_FILE.export as a state file export, loaded and removed it"
  fi

  return $subshell_ret
}

_tmverbose_echo(){
  if [[ -n "$GLOBAL_VERBOSE" ]]
  then
    echo -e "$1"
  fi
}

_TaskTabCompletion(){
  local tasks cur word aliases
  tasks=$(task list | grep -v Available | grep -v Running)
  cur=${COMP_WORDS[COMP_CWORD]}  
  word=${COMP_WORDS[$COMP_CWORD-1]}
  aliases="$(alias | grep task | sed "s/alias \(.*\)='task'/\1/")"
  if [[ "$word" == "task" ]] || [[ "$word" == "help" ]] || [[ "$aliases" == *"$word"* ]]
  then
    COMPREPLY=("$( compgen -W "$tasks" -- "$cur" )")
  fi
}

# Setup tab completion for task
complete -F _TaskTabCompletion -o bashdefault -o default task

# Setup tab completion for any aliases for task
for a in $(alias | grep task | sed "s/alias \(.*\)='task'/\1/")
do
  complete -F _TaskTabCompletion -o bashdefault -o default "$a"
done
