LOCAL_TASKS_UUID=l0
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
task_test() {

  #Recorded subcommand
  if [[ $TASK_SUBCOMMAND == "record" ]]
  then
    cd /home/swalker/.task-master/tests
    mkdir tester
    cd tester/
    task init -n tester
    echo "Testing no subcommands"
    task record start -n tester
    create_recording "hello world"
    task record stop
    task tester
    test_recording "hello world"
    echo
    echo

    echo "Testing subcommands"
    task record start -n tester -s dingus
    create_recording "dingus"
    task record stop
    task tester dingus
    test_recording "dingus"
    echo
    echo

    echo "Testing subcommands with requirements"
    clear_output
    task record start -n tester -s fingus -r 'num:n:int'
    create_recording "fingus"
    task record stop
    task tester fingus -n asdf
    test_recording ""
    task tester fingus -n 123
    test_recording "fingus"
    echo
    echo

    echo "Testing subcommands with requirements and options"
    clear_output
    task record start -n tester -s burger -r 'num:n:int' -o 'verbose:v:bool'
    create_recording "burger"
    task record stop
    task tester burger
    test_recording ""
    task tester burger -n asdf
    test_recording ""
    task tester burger -n 1234 -v nope
    test_recording ""
    task tester burger -n -v 123
    test_recording ""
    task tester burger -n 123 -v
    test_recording "burger"
    clear_output
    task tester burger -vn 123
    test_recording "burger"
    clear_output
    task tester burger --num 123 -v
    test_recording "burger"
    echo
    echo

    cd ..
    rm -r tester
    task global clean
  fi
}
arguments_test() {
  SUBCOMMANDS="record|"
}

clear_output() {
  echo > tester.tmp
}

create_recording() {
  echo "task record start -n tester" >> .rec_tester
  echo "echo '$1' > tester.tmp" >> .rec_tester
}

test_recording() {
  if [[ -f tester.tmp ]] && [[ "$(cat tester.tmp)" == "$1" ]]
  then
    echo "TEST SUCCESS +++++++++++++++++++++++++++++++++++++++++++"
  else
    echo "TEST FAILED --------------------------------------------"
  fi
}
