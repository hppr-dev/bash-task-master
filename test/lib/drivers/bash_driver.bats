setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

@test 'Defines PARSE_ARGS, VALIDATE_ARGS, EXECUTE_TASK, DRIVER_HELP_TASK, HAS_TASK' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  assert [ ! -z "$PARSE_ARGS" ]
  assert [ ! -z "$VALIDATE_ARGS" ]
  assert [ ! -z "$EXECUTE_TASK" ]
  assert [ ! -z "$DRIVER_HELP_TASK" ]
  assert [ ! -z "$HAS_TASK" ]
}

@test 'Parses long arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  $PARSE_ARGS mytask --force --num 10 --out "hello world" --in foobar
  assert [ ! -z "$ARG_FORCE" ]
  assert [ "$ARG_NUM" == "10" ]
  assert [ "$ARG_OUT" == "hello world" ]
  assert [ "$ARG_IN" == "foobar" ]
}

@test 'Parses short arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  $PARSE_ARGS mytask -f -n 10 -o "hello world" -i foobar
  assert [ ! -z "$ARG_FORCE" ]
  assert [ "$ARG_NUM" == "10" ]
  assert [ "$ARG_OUT" == "hello world" ]
  assert [ "$ARG_IN" == "foobar" ]
}

@test 'Parses combined bool arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  $PARSE_ARGS mytask -fn 10 --out "hello world" --in foobar
  assert [ ! -z "$ARG_FORCE" ]
  assert [ "$ARG_NUM" == "10" ]
  assert [ "$ARG_OUT" == "hello world" ]
  assert [ "$ARG_IN" == "foobar" ]
}

@test 'Parses subcommand arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask_withsub"

  $PARSE_ARGS mytask_withsub sub -p y -t 192.168.1.3
  assert [ "$ARG_PASS" == "y" ]
  assert [ "$ARG_THING" == "192.168.1.3" ]
}

@test 'Does not parse bad short argument' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask_withsub"

  run $PARSE_ARGS mytask_withsub sub -p y -t 192.168.1.3 -k
  assert_failure
}

@test 'Does not parse extra argument' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask_withsub"

  run $PARSE_ARGS mytask_withsub sub -p y -t 192.168.1.3 dangit
  assert_failure
}

@test 'Validates argument when all are given correctly' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  ARG_FORCE="1"
  ARG_NUM=10
  ARG_OUT="hello world"
  ARG_IN="foobar"

  run $VALIDATE_ARGS
  assert_success
}

@test 'Does not validate arguments when requirements are missing' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  ARG_FORCE="1"
  ARG_NUM="10"
  ARG_OUT="hello world"

  run $VALIDATE_ARGS
  assert_failure
}

@test 'Does not validate bad int option' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  ARG_FORCE="1"
  ARG_NUM="something something"
  ARG_OUT="hello world"
  ARG_IN="foobar"

  run $VALIDATE_ARGS
  assert_failure
}

@test 'Does not validate bad nowhite requirement' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  TASK_COMMAND="mytask"

  ARG_FORCE="T"
  ARG_NUM=10
  ARG_OUT="hello world"
  ARG_IN="foo bar"

  run $VALIDATE_ARGS
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

  run $VALIDATE_ARGS
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

  run $VALIDATE_ARGS
  assert_failure
}

@test 'Executes task' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh

  run $EXECUTE_TASK task_example
  assert_output "tymbd"
}

@test 'Shows help' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh
}

@test 'Identifies existing task' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh
}

arguments_mytask() {
  MYTASK_OPTIONS="force:f:bool num:n:int"
  MYTASK_REQUIREMENTS="out:o:str in:i:nowhite"
}

arguments_mytask_withsub() {
  SUBCOMMANDS="|sub"
  MYTASK_OPTIONS="force:f:bool num:n:int"
  SUB_REQUIREMENTS="thing:t:ip pass:p:single"
}

task_example() {
  echo "tymbd"
}
