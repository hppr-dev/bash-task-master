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

@test 'Parses arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh
}

@test 'Validates arguments' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh
}

@test 'Executes task' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh
}

@test 'Shows help' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh
}

@test 'Identifies existing task' {
  source $TASK_MASTER_HOME/lib/drivers/bash_driver.sh
}
