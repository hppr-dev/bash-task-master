arguments_bookmark() {
  SUBCOMMANDS='|rm|list'
  BOOKMARK_DESCRIPTION="Add a bookmark to the current location."
  BOOKMARK_OPTIONS="dir:d:str name:n:str"
  RM_DESCRIPTION="Remove a bookmark"
  LIST_DESCRIPTION="List available bookmarks"
}

task_bookmark() {
  if [[ -z "$ARG_DIR" ]]
  then
    ARG_DIR=$RUNNING_DIR
  fi
  if [[ -z "$ARG_NAME" ]]
  then
    ARG_NAME=$(basename "$(readlink -f "$ARG_DIR")")
  fi
  if [[ "$TASK_SUBCOMMAND" == "list" ]]
  then
    echo "Bookmarks:"
    sed 's/UUID_\(.*\)=.*/    \1/' "$LOCATION_FILE" | tr '\n' ' '
    echo
    echo
  elif [[ "$TASK_SUBCOMMAND" == "rm" ]]
  then
    if grep -q "UUID_$ARG_NAME=" "$LOCATION_FILE"
    then
      awk "/UUID_$ARG_NAME=/ { next } { print }" "$LOCATION_FILE" > "$LOCATION_FILE.upd"
      mv "$LOCATION_FILE"{.upd,}
      echo "Removed bookmark: $ARG_NAME"
    else
      echo "Bookmark $ARG_NAME not found"
    fi
  else
    echo "Saving location to $LOCATION_FILE as $ARG_NAME"
    echo "UUID_$ARG_NAME=$ARG_DIR" >> "$LOCATION_FILE"
  fi
}

readonly -f task_bookmark
readonly -f arguments_bookmark
