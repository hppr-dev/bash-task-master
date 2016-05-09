task_edit() {
  vim /home/swalker/.task-master/tests/tasks.sh
}

task_test-record(){
  task record start --name testing
  task global debug --command record > .testing.tmp
  assert_equal $(grep -e RECORDING_FILE .testing.tmp) "RECORDING_FILE=\"`pwd`/.rec_testing\""
  assert_equal $(grep -e RECORD_START .testing.tmp) "RECORD_START=\"`pwd`\""
  echo "ls -al" >> "`pwd`/.rec_testing"
  task record stop
  grep -e task_testing tasks.sh 
  assert_equal $? 0
  grep -e "ls -al" tasks.sh 
  assert_equal $? 0
  rm .testing.tmp
}

assert_equal() {
  if [[ "$1" != "$2" ]]
  then
    echo "Assertion error : $1 != $2"
  fi
}
