arguments_init() {
  INIT_DESCRIPTION="Create a new local tasks location"
  INIT_OPTIONS="dir:d:str name:n:str driver:D:str template:t"
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

  if [[ -z "$ARG_DRIVER" ]]
  then
    ARG_DRIVER=bash
  fi

  if [[ -z "$ARG_TEMPLATE" ]]
  then
    ARG_TEMPLATE=${ARG_DRIVER}_template
  fi


  NEW_TASKS_FILE=$ARG_DIR/tasks.sh

  # Check for existing tasks file
  if [[ -f "$ARG_DIR/tasks.sh" ]]
  then
    echo "Tasks file already exists can't init $ARG_DIR"
    return 1
  fi

  # Copy template to ARG_DIR
  echo "Initializing tasks.sh file in $ARG_DIR..."

  echo "Creating state directory..."
  mkdir "$TASK_MASTER_HOME/state/$LOCAL_TASKS_UUID"

  echo "Bookmarking location..."
  task bookmark --dir $ARG_DIR --name $ARG_NAME
}

readonly -f arguments_init
readonly -f task_init
