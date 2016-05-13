LOCAL_TASKS_UUID=l0
source record-tests.sh
source argument-tests.sh

task_edit() {
  vim /home/swalker/.task-master/tests/tasks.sh
}

arguments_time() {
  SUBCOMMANDS=""
  TIME_REQUIREMENTS="proc:p:str num:n:int"
}

task_time() {
  rm -f timed
  TIMEFORMAT="%R"
  for i in $(seq 1 $ARG_NUM)
  do 
    time (eval $ARG_PROC > /dev/null) 2>> timed
  done
  total_time=$(awk ' {m+=$1} END{ print m } ' timed)
  echo "Total time: $total_time"
  echo "Average time: $( echo $total_time/$ARG_NUM | bc -l |xargs printf "%1.5f" )"
}

arguments_test() {
  SUBCOMMANDS="record|args"
  ARGS_OPTIONS="all:a:bool sub:s:bool unknown:u:bool command:c:bool short:S:bool"
}

task_test() {
  if [[ $TASK_SUBCOMMAND == "record" ]] || [[ $TASK_SUBCOMMAND == "all" ]]
  then
    test_record
  elif [[ $TASK_SUBCOMMAND == "args" ]] || [[ $TASK_SUBCOMMAND == "all" ]]
  then
    test_arguments
  fi
}

