arguments_init() {
  INIT_DESCRIPTION="Create a new local tasks location"
  INIT_OPTIONS="dir:d:str name:n:str driver:D:str template:t:str"
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
    ARG_DRIVER=$DEFAULT_TASK_DRIVER
  fi

  if [[ -z "$ARG_TEMPLATE" ]]
  then
    ARG_TEMPLATE=$ARG_DRIVER
  fi

  # Determine task file name
  for filename in ${!TASK_FILE_NAME_DICT[@]}
  do
    if [[ "${TASK_FILE_NAME_DICT[$filename]}" == "$ARG_DRIVER" ]]
    then
      filename_found="T"
      break
    fi
  done

  if [[ -z "$filename_found" ]]
  then
    echo "Can not determine task file name for $ARG_DRIVER. Aborting..."
    return 1
  fi
  
  NEW_TASKS_FILE=$ARG_DIR/$filename

  # Check for existing tasks file
  if [[ -f "$NEW_TASKS_FILE" ]]
  then
    echo "Task file already exists can't init in $ARG_DIR"
    return 1
  fi

  # Copy template to ARG_DIR
  if [[ -f "$TASK_MASTER_HOME/templates/$ARG_TEMPLATE.template" ]]
  then
    echo "Initializing tasks.sh file in $ARG_DIR..."
    cp $TASK_MASTER_HOME/templates/$ARG_TEMPLATE.template $ARG_DIR/$filename
  else
    echo "Template $ARG_TEMPLATE not found."
    echo "Creating empty $filename..."
    touch $ARG_DIR/$filename
  fi

  echo "Creating state directory..."
  mkdir "$TASK_MASTER_HOME/state/$LOCAL_TASKS_UUID"

  echo "Bookmarking location..."
  # Uses ARG_NAME and ARG_DIR
  task_bookmark
}

readonly -f arguments_init
readonly -f task_init
