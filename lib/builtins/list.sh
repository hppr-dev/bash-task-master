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
    task_list="${GLOBAL_TASKS_REG//|/ }"
  fi
  if [[ -n "$ARG_LOCAL$ARG_ALL" ]] && [[ -n "$TASK_FILE" ]]
  then
    task_list="$task_list $($DRIVER_LIST_TASKS "$TASK_FILE")"
  fi
  pr -5 -Tt <<<"${task_list// /$'\n'}" 
}

readonly -f arguments_list
readonly -f task_list
