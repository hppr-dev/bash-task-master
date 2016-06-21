arguments_venv() {
  SUBCOMMANDS='init|enable|disable|list|destroy'

  INIT_DESCRIPTION='Create a new python virtual environment'
  INIT_OPTIONS='uuid:u:str name:n:str'

  ENABLE_DESCRIPTION='Enable a python virtual environment'
  ENABLE_OPTIONS='uuid:u:str name:n:str'

  DISABLE_DESCRIPTION='Disable the current python virtual environment'

  LIST_DESCRIPTION='List available python virtual environments'
  LIST_OPTIONS='uuid:u:str'

  DESTROY_DESCRIPTION='Destroy a python virtual environment'
  DESTROY_OPTIONS='uuid:u:str name:n:str'

}

task_venv(){

  if [[ -z "$ARG_NAME" ]]
  then
    ARG_NAME=venv
  fi
  if [[ -z "$ARG_UUID" ]]
  then
    ARG_UUID=$LOCAL_TASKS_UUID
  else
    STATE_DIR="$TASK_MASTER_HOME/state/$ARG_UUID"
    if [[ ! -d "$STATE_DIR" ]]
    then
      echo "State file directory doesn't exist"
      return 1
    fi
  fi
  if [[ -z "$LOCAL_TASKS_UUID" ]]
  then
    echo "Can't find a local task uuid"
    return
  fi
  if [[ $TASK_SUBCOMMAND == "init" ]]
  then
    local env_name=VENV_${ARG_NAME//-/_}
    if [[ -z ${!env_name} ]]
    then
      virtualenv $STATE_DIR/$ARG_UUID-$ARG_NAME
      persist_var "$env_name" "$STATE_DIR/$ARG_UUID-$ARG_NAME"
    else
      echo "Can't initialize virtual environment, one already exists"
    fi

  elif [[ $TASK_SUBCOMMAND == "enable" ]]
  then
    if [[ -z "$VENV_ACTIVE" ]] && [[ -d "$STATE_DIR/$ARG_UUID-$ARG_NAME" ]]
    then
      hold_var "VIRTUAL_ENV"
      hold_var "PATH"
      hold_var "PS1"
      source $STATE_DIR/$ARG_UUID-$ARG_NAME/bin/activate
      export_var "VIRTUAL_ENV" "$VIRTUAL_ENV"
      export_var "PATH" "$PATH"
      export_var "PS1" "$PS1"
      persist_var "VENV_ACTIVE" "T"
      set_trap "cd $RUNNING_DIR; task venv disable ;"
    else
      echo "Virtual environment $ARG_NAME doesn't not exist or a virtual environment is already active"
    fi

  elif [[ $TASK_SUBCOMMAND == "disable" ]]
  then
    if [[ ! -z "$VENV_ACTIVE" ]]
    then
      release_var "VIRTUAL_ENV"
      release_var "PATH"
      release_var "PS1"
      remove_var "VENV_ACTIVE"
      unset_trap
    else
      echo "Virtual environment not active"
    fi

  elif [[ $TASK_SUBCOMMAND == "destroy" ]]
  then
    local env_name=VENV_${ARG_NAME//-/_}
    if [[ ! -z "${!env_name}" ]]
    then
      rm -r $STATE_DIR/$ARG_UUID-$ARG_NAME
      remove_var "$env_name"
    else
      echo "Can't destroy virtual environment: $ARG_NAME, does not exist"
    fi
  elif [[ $TASK_SUBCOMMAND == "list" ]]
  then
    sed 's/VENV_\(.*\)=.*/\1/' $STATE_FILE
  fi
}

readonly -f task_venv
readonly -f arguments_venv
