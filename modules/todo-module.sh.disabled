arguments_todo() {
  TODO_DESCRIPTION="Simple todo list"
  TODO_OPTIONS="add:a:str delete:d:int file:f:str start:s:int"
}

task_todo() {
  TODO_FILE="$STATE_DIR/todo_$LOCAL_TASKS_UUID"
  TODO_FILE_FILES="$STATE_DIR/todo_$LOCAL_TASKS_UUID.files"
  touch $TODO_FILE $TODO_FILE_FILES
  last_todo_num=$(tail -1 $TODO_FILE | awk '{print $2}')
  if [[ -n "$ARG_ADD" ]]
  then
    if [[ -z "$last_todo_num" ]]
    then
      last_todo_num=0
    fi
    if [[ -n "$ARG_FILE" ]] && [[ ! -e "$(pwd)/$ARG_FILE" ]]
    then
      echo "Can't find file $ARG_FILE"
      exit 1
    else
      echo TODO $((last_todo_num+1)) $(pwd)/$ARG_FILE >> $TODO_FILE_FILES
    fi
    echo TODO $((last_todo_num+1)) $ARG_ADD >> $TODO_FILE
  elif [[ -n "$ARG_DELETE" ]]
  then
    awk "!/TODO $ARG_DELETE/ {print}" $TODO_FILE > $TODO_FILE.tmp
    awk "!/TODO $ARG_DELETE/ {print}" $TODO_FILE_FILES > $TODO_FILE_FILES.tmp
    mv $TODO_FILE.tmp $TODO_FILE
    mv $TODO_FILE_FILES.tmp $TODO_FILE_FILES
  elif [[ -n "$ARG_START" ]]
  then
    openfile=$(grep "TODO $ARG_START" $TODO_FILE_FILES | awk '{print $3}')
    if [[ ! -e "$openfile" ]] 
    then
      echo "$openfile does not exist"
      exit 1
    fi
    $DEFAULT_EDITOR $openfile
  fi
  cat "$TODO_FILE"
}

readonly -f arguments_todo
readonly -f task_todo
