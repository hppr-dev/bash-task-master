setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

@test 'Should call driver help when driver returns zero' {
  source $TASK_MASTER_HOME/lib/builtins/help.sh
  DRIVER_HELP_TASK=echo_subcommand

  TASK_SUBCOMMAND="tester"

  run task_help
  assert_output "tester"
  refute_output --partial "Task Master"
}

@test 'Should display global help when driver returns non-zero' {
  source $TASK_MASTER_HOME/lib/builtins/help.sh
  DRIVER_HELP_TASK=return_1

  run task_help
  assert_output --partial 'Task Master'
}

echo_subcommand() {
  echo $TASK_SUBCOMMAND
}

return_1() {
  return 1
}
