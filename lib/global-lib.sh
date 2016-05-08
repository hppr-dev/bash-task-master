
global_help() {
  HELP_STRING="Usage: task global (debug|set|unset)
  Used to manipulate/display internal variables

  To see state variables run (specify --command to limit display state for a command):

      task global debug [--comand command]

  To set state variables for a command run (sets KEY=\"Hello\" for the spawn command): 

      task global set --key KEY --value \"Hello\" --command spawn

  To unset state variables for a command run (unsets KEY for the spawn command): 

      task global set --key KEY --command spawn

  To edit state variables for a command run:

      task global edit --command spawn
  "

  echo "$HELP_STRING"
}

global_debug() {
  if [[ ! -z "$ARG_COMMAND" ]]
  then
    for f in $TASK_MASTER_HOME/state/$ARG_COMMAND.vars*
    do
      echo ==================== $f ======================
      cat $f
    done
  else
    for f in $TASK_MASTER_HOME/state/*.vars*
    do
      echo ==================== $f ======================
      cat $f
    done
  fi
}

global_set() {
  if [[ ! -z "$ARG_VALUE" ]] && [[ ! -z $ARG_KEY ]] && [[ ! -z $ARG_COMMAND ]]
  then
    local STATE_FILE=$TASK_MASTER_HOME/state/$ARG_COMMAND.vars
    persist_var "$ARG_KEY" "$ARG_VALUE"
    echo "Value saved, variables for $ARG_COMMAND :"
    global_debug
  else
    echo "Could not set value, must specify --value 'value' --key 'key' and --command 'command'"
  fi
}

global_unset() {
  if [[ ! -z $ARG_KEY ]] && [[ ! -z $ARG_COMMAND ]]
  then
    local STATE_FILE=$TASK_MASTER_HOME/state/$ARG_COMMAND.vars
    remove_var "$ARG_KEY" "$ARG_VALUE"
    echo "Value removed, variables for $ARG_COMMAND :"
    global_debug
  else
    echo "Could not remove value, must specify --key 'key' and --command 'command'"
  fi
}

global_edit() {
  if [[ ! -z "$ARG_COMMAND" ]]
  then
    vim $TASK_MASTER_HOME/state/$ARG_COMMAND.vars
  else
    echo "Need to specify --command"
  fi
}
