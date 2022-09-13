arguments_edit() {
  EDIT_DESCRIPTION="Edit the current tasks file. Validates the file after closing"
}

task_edit() {
  if [[ -z "$TASK_FILE" ]]
  then
    echo "No tasks file found."
    return 1
  fi
  source "$DRIVER_DIR/${TASK_DRIVER_DICT[$TASK_FILE_DRIVER]}"
  local validated=1
  cp "$TASK_FILE" "$TASK_FILE.tmp"
  while [[ "$validated" != "0" ]]
  do
    $DEFAULT_EDITOR "$TASK_FILE"
    if ! $DRIVER_VALIDATE_TASK_FILE "$TASK_FILE"
    then
      validated=1
      echo "Could not validate $TASK_FILE."
      echo "Changes will be reverted if you choose not to edit again."
      read -rp "Edit again (yes or no)?[yes]" ans
      if [[ "$ans" == "no" ]]
      then
        mv "$TASK_FILE.tmp" "$TASK_FILE"
        validated=0
      fi
    else
      echo "Changes validated."
      validated=0
      rm "$TASK_FILE.tmp"
    fi
  done
}

readonly -f task_edit
readonly -f arguments_edit
