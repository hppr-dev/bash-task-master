setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
  export EXAMPLE_TASKS_FILE=$TASK_MASTER_HOME/test/tasks.sh.bash_driver
  cat > $EXAMPLE_TASKS_FILE <<EOF
task_hello() {
  :
}
task_world() {
  :
}
task_foo() {
  :
}
task_bar() {
  :
}
echo I have been loaded
EOF
}

teardown() {
  rm $EXAMPLE_TASKS_FILE
}

@test 'Defines DRIVER_PARSE_ARGS, DRIVER_VALIDATE_ARGS, DRIVER_EXECUTE_TASK, DRIVER_HELP_TASK, ' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  assert [ ! -z "$DRIVER_EXECUTE_TASK" ]
  assert [ ! -z "$DRIVER_HELP_TASK" ]
  assert [ ! -z "$DRIVER_LIST_TASKS" ]
}

@test 'Parses long arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  bash_parse mytask --force --num 10 --out "hello world" --in foobar
  assert [ ! -z "$ARG_FORCE" ]
  assert [ "$ARG_NUM" == "10" ]
  assert [ "$ARG_OUT" == "hello world" ]
  assert [ "$ARG_IN" == "foobar" ]
}

@test 'Parses short arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  bash_parse mytask -f -n 10 -o "hello world" -i foobar
  assert [ ! -z "$ARG_FORCE" ]
  assert [ "$ARG_NUM" == "10" ]
  assert [ "$ARG_OUT" == "hello world" ]
  assert [ "$ARG_IN" == "foobar" ]
}

@test 'Parses combined bool arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  bash_parse mytask -fn 10 --out "hello world" --in foobar
  assert [ ! -z "$ARG_FORCE" ]
  assert [ "$ARG_NUM" == "10" ]
  assert [ "$ARG_OUT" == "hello world" ]
  assert [ "$ARG_IN" == "foobar" ]
}

@test 'Parses a lot of combined bool arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="boolbunch"

  bash_parse mytask -iozn 10
  assert [ ! -z "$ARG_IN" ]
  assert [ ! -z "$ARG_OUT" ]
  assert [ ! -z "$ARG_ZOO" ]
  assert [ "$ARG_NUM" == "10" ]
}

@test 'Parses subcommand arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask_withsub"

  bash_parse mytask_withsub sub -p y -t 192.168.1.3
  assert [ "$ARG_PASS" == "y" ]
  assert [ "$ARG_THING" == "192.168.1.3" ]
}

@test 'Does not parse bad short argument' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask_withsub"

  run bash_parse mytask_withsub sub -p y -t 192.168.1.3 -k
  assert_failure
}

@test 'Does not parse extra argument' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask_withsub"

  run bash_parse mytask_withsub sub -p y -t 192.168.1.3 dangit
  assert_failure
}

@test 'Validates argument when all are given correctly' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  ARG_FORCE="1"
  ARG_NUM=10
  ARG_OUT="hello world"
  ARG_IN="foobar"

  run bash_validate
  assert_success
}

@test 'Does not validate arguments when requirements are missing' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  ARG_FORCE="1"
  ARG_NUM="10"
  ARG_OUT="hello world"

  run bash_validate
  assert_failure
}

@test 'Does not validate bad int option' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  ARG_FORCE="1"
  ARG_NUM="something something"
  ARG_OUT="hello world"
  ARG_IN="foobar"

  run bash_validate
  assert_failure
}

@test 'Does not validate bad nowhite requirement' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  ARG_FORCE="T"
  ARG_NUM=10
  ARG_OUT="hello world"
  ARG_IN="foo bar"

  run bash_validate
  assert_failure
}

@test 'Does not validate with bad subcommand' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask_withsub"
  TASK_SUBCOMMAND="missing"

  ARG_FORCE="T"
  ARG_NUM=10
  ARG_OUT="hello world"
  ARG_IN="foobar"

  run bash_validate
  assert_failure
}

@test 'Does not validate with missing subcommand requirement' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask_withsub"
  TASK_SUBCOMMAND="sub"

  ARG_FORCE="T"
  ARG_NUM=10
  ARG_OUT="hello world"
  ARG_IN="foobar"
  ARG_PASS="y"

  run bash_validate
  assert_failure
}

@test 'Executes task' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="example"

  run $DRIVER_EXECUTE_TASK
  assert_output --partial "tymbd"
}

@test 'Shows help for task with subcommand' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_SUBCOMMAND="mytask_withsub"

  run $DRIVER_HELP_TASK
  assert_output --partial "task mytask_withsub"
  assert_output --partial "--force"
  assert_output --partial "--num"
  assert_output --partial "task mytask_withsub sub"
  assert_output --partial "--thing"
  assert_output --partial "--pass"
  assert_output --partial "--confirm"
  assert_output --partial "jiofni walki"
  assert_output --partial "qsc bie"
  assert_output --partial "task mytask_withsub some"
  assert_success
}

@test 'Shows help for task with no subcommands' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_SUBCOMMAND="mytask"

  run $DRIVER_HELP_TASK
  assert_output --partial "task mytask"
  assert_output --partial "odejfk fjwick"
  assert_output --partial "--force"
  assert_output --partial "--num"
  assert_output --partial "--out"
  assert_output --partial "--in"
  assert_success
}

@test 'Shows help for task with no description' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_SUBCOMMAND="nodescription"

  run $DRIVER_HELP_TASK
  assert_output --partial "task nodescription"
  assert_output --partial "--not"
  assert_success
}

@test 'Help does not fail when there are no arguments defined' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_SUBCOMMAND="example"

  run $DRIVER_HELP_TASK
  assert_success
}

@test 'Help fails if no task is given' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  run $DRIVER_HELP_TASK

  assert_failure
}

@test 'Lists tasks in a task file' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASKS_FILE_FOUND=1

  run $DRIVER_LIST_TASKS $EXAMPLE_TASKS_FILE
  assert_output "hello world foo bar "
  assert_success
}

@test 'Validates tasks file' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  run $DRIVER_VALIDATE_TASKS_FILE $EXAMPLE_TASKS_FILE
  assert_success
}

@test 'Does not validate bad tasks file {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh
  grep -v task_bar $EXAMPLE_TASKS_FILE > $EXAMPLE_TASKS_FILE.tmp
  mv $EXAMPLE_TASKS_FILE{.tmp,}

  run $DRIVER_VALIDATE_TASKS_FILE $EXAMPLE_TASKS_FILE
  assert_failure
}

arguments_mytask() {
  MYTASK_DESCRIPTION="odejfk fjwick"
  MYTASK_OPTIONS="force:f:bool num:n:int"
  MYTASK_REQUIREMENTS="out:o:str in:i:nowhite"
}

arguments_mytask_withsub() {
  MYTASK_WITHSUB_DESCRIPTION="jiofni walki"
  SUB_DESCRIPTION="qsc bie"
  SUBCOMMANDS="|sub|some"
  MYTASK_WITHSUB_OPTIONS="force:f:bool num:n:int"
  SUB_REQUIREMENTS="thing:t:ip pass:p:single"
  SUB_OPTIONS="confirm:c:bool dest:d:str"
}

arguments_nodescription() {
  NODESCRIPTION_OPTIONS="not:n:bool"
}

arguments_boolbunch() {
  BOOLBUNCH_OPTIONS="out:o:bool in:i:bool zoo:z:bool num:n:int"
}

task_example() {
  echo "tymbd"
}
