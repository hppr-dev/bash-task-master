arguments_list() {
  LIST_DESCRIPTION="List available tasks"
  LIST_OPTIONS="global:g:bool local:l:bool all:a:bool json:j:bool"
}

task_list() {
  # shellcheck disable=SC2153
  if [[ -z "$ARG_GLOBAL$ARG_LOCAL$ARG_ALL" ]]
  then
    ARG_LOCAL='T'
  fi
  if [[ -n "$ARG_GLOBAL$ARG_ALL" ]]
  then
    task_list="${GLOBAL_TASKS_REG//|/ }"
  fi
  if [[ -n "$ARG_LOCAL$ARG_ALL" ]] && [[ -n "$TASK_FILE" ]]
  then
    source "$DRIVER_DIR/${TASK_DRIVER_DICT[$TASK_FILE_DRIVER]}" &> /dev/null
    task_list="$($DRIVER_LIST_TASKS "$TASK_FILE") $task_list"
  fi
  task_list="${task_list//  / }"
  task_list="$(echo "$task_list" | xargs)"
  if [[ -n "$ARG_JSON" ]]
  then
    if [[ -z "$task_list" ]]
    then
      echo "[]"
    else
      first=1
      printf '%s' '['
      for t in $task_list
      do
        [[ $first -eq 1 ]] || printf '%s' ','
        printf '%s' "\"$t\""
        first=0
      done
      printf '%s\n' ']'
    fi
  else
    pr -5 -Tt <<<"${task_list// /$'\n'}"
  fi
}

readonly -f arguments_list
readonly -f task_list
