arguments_init() {
  INIT_DESCRIPTION="Create a new local tasks location"
  INIT_OPTIONS="dir:d:str name:n:str hidden:h:bool"
}

task_init() {
  if [[ -z "$ARG_DIR" ]]
  then
    ARG_DIR=$RUNNING_DIR
  fi
  if [[ -z "$ARG_NAME" ]]
  then
    ARG_NAME=$(basename "$(readlink -f "$ARG_DIR")")
  fi
  local LOCAL_TASKS_UUID=$ARG_NAME
  if [[ -f "$ARG_DIR/tasks.sh" ]]
  then
    echo "Tasks file already exists can't init $ARG_DIR"
    return 1
  fi
  NEW_TASKS_FILE=$ARG_DIR/tasks.sh
  if [[ -n "$ARG_HIDDEN" ]]
  then
    NEW_TASKS_FILE=$ARG_DIR/.tasks.sh
  fi
  echo "Initializing tasks.sh file in $ARG_DIR..."
  echo "LOCAL_TASKS_UUID=$LOCAL_TASKS_UUID" >> $NEW_TASKS_FILE
  echo "Creating state directory..."
  mkdir $TASK_MASTER_HOME/state/$LOCAL_TASKS_UUID
  echo "Saving tasks file location to $LOCATIONS_FILE as $ARG_NAME"
  echo "UUID_$LOCAL_TASKS_UUID=$ARG_DIR" >> $LOCATIONS_FILE
}

readonly -f arguments_init
readonly -f task_init
