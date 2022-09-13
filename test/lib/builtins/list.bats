setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export DRIVER_LIST_TASKS="ltask"
}

@test 'Lists all tasks by default' {
  source $TASK_MASTER_HOME/lib/builtins/list.sh

  GLOBAL_TASKS_REG="gtask|gtask2"
  run task_list
  assert_output --partial "gtask"
  assert_output --partial "gtask2"
  assert_output --partial "ltask"
}

@test 'Lists global tasks when global flag given' {
  source $TASK_MASTER_HOME/lib/builtins/list.sh

  ARG_GLOBAL=T
  GLOBAL_TASKS_REG="gtask|gtask2"

  run task_list
  assert_output --partial "gtask"
  assert_output --partial "gtask2"
  refute_output --partial "ltask"
}

@test 'Lists local tasks when local flag given' {
  source $TASK_MASTER_HOME/lib/builtins/list.sh
  GLOBAL_TASKS_REG="gtask|gtask2"
  ARG_LOCAL=T

  run task_list
  assert_output --partial "ltask"
  refute_output --partial "gtask"
}

@test 'Sets descriptions and options' {
  source $TASK_MASTER_HOME/lib/builtins/list.sh

  arguments_list

  assert [ ! -z "$LIST_DESCRIPTION" ]
  assert [ ! -z "$LIST_OPTIONS" ]
}

task_gtask() {
  return 0
}

task_ltask() {
  return 0
}
