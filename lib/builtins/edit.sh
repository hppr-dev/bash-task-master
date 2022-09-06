arguments_edit() {
  EDIT_DESCRIPTION="Edit the current tasks file. Validates the file after closing"
}

task_edit() {
  if [[ -z "$TASKS_FILE" ]]
  then
    echo "No tasks file found."
    return 1
  fi
  local validated=1
  cp $TASKS_FILE $TASKS_FILE.tmp
  while [[ "$validated" != "0" ]]
  do
    $DEFAULT_EDITOR $TASKS_FILE
    $DRIVER_VALIDATE_TASKS_FILE $TASKS_FILE
    if [[ "$?" != "0" ]]
    then
      validated=1
      echo "Could not validate $TASKS_FILE."
      echo "Changes will be reverted if you choose not to edit again."
      read -p "Edit again (yes or no)?[yes]" ans
      if [[ "$ans" == "no" ]]
      then
        mv $TASKS_FILE.tmp $TASKS_FILE
        validated=0
      fi
    else
      echo "Changes validated."
      validated=0
      rm $TASKS_FILE.tmp
    fi
  done
}

readonly -f task_edit
readonly -f arguments_edit
