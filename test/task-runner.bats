setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

@test 'Parses arguments for a given task' {
  source $TASK_MASTER_HOME/task-runner.sh
}

@test 'Validates arguments for a given task' {
  source $TASK_MASTER_HOME/task-runner.sh
}

@test 'Executes a given task' {
  source $TASK_MASTER_HOME/task-runner.sh
}

@test 'Returns to directory specified in TASK_RETURN_DIR in state file' {
  source $TASK_MASTER_HOME/task-runner.sh
}

@test 'Sets trap from TASK_TERM_TRAP in state file' {
  source $TASK_MASTER_HOME/task-runner.sh
}

@test 'Removes state file when DESTROY_STATE_FILE is in state file' {
  source $TASK_MASTER_HOME/task-runner.sh
}

@test 'Exports variables in export state file' {
  source $TASK_MASTER_HOME/task-runner.sh
}

@test 'Lists tasks for tab completion' {
  source $TASK_MASTER_HOME/task-runner.sh
}

@test 'Only logs verbose logs when GLOBAL_VERBOSE is set' {
  source $TASK_MASTER_HOME/task-runner.sh

  run _tmverbose_echo "hello"
  assert_output ""

  GLOBAL_VERBOSE=T
  run _tmverbose_echo "hello"
  assert_output "hello"
}

