setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

# These test will probably change dramatically when functionality for drivers is included
# The global tasks should be the same, but the local tasks may have different drivers

@test 'Lists all tasks by default' {
  source $TASK_MASTER_HOME/lib/builtins/list.sh
  readonly -f task_gtask

  run task_list
  assert_output --partial "gtask"
  assert_output --partial "ltask"
}

@test 'Lists global tasks when global flag given' {
  source $TASK_MASTER_HOME/lib/builtins/list.sh
  readonly -f task_gtask
  ARG_GLOBAL=T

  run task_list
  assert_output --partial "gtask"
  refute_output --partial "ltask"
}

@test 'Lists local tasks when local flag given' {
  source $TASK_MASTER_HOME/lib/builtins/list.sh
  readonly -f task_gtask
  ARG_LOCAL=T

  run task_list
  assert_output --partial "ltask"
  refute_output --partial "gtask"
}

task_gtask() {
  return 0
}

task_ltask() {
  return 0
}
