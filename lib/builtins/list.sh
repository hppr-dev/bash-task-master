arguments_list() {
  LIST_DESCRIPTION="List available tasks"
  LIST_OPTIONS="global:g:bool local:l:bool all:a:bool"
}

task_list() {
  if [[ -z "$ARG_GLOBAL$ARG_LOCAL$ARG_ALL" ]]
  then
    ARG_ALL='T'
  fi
  if [[ -n "$ARG_GLOBAL$ARG_ALL" ]]
  then
    echo "Available global tasks:"
    echo
    echo "    $GLOBAL_TASKS" | sed 's/|/    /g'
    echo
  fi
  if [[ -n "$ARG_LOCAL$ARG_ALL" ]]
  then
    source "$DRIVER_DIR/${TASK_DRIVER_DICT[$TASK_FILE_DRIVER]}"
    echo "Available local tasks:"
    echo
    echo "     $($DRIVER_LIST_TASKS "$TASKS_FILE")"
    echo
  fi
}

readonly -f arguments_list
readonly -f task_list
