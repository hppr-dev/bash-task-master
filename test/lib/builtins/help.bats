setup_file() {
  cat > $TASK_MASTER_HOME/test/driver.help <<EOF
DRIVER_HELP_TASK=echo_subcommand

echo_subcommand() {
  if [[ "\$TASK_SUBCOMMAND" == "tester" ]]
  then
    echo \$1
  else
    return 1
  fi
}
EOF
}

teardown_file() {
  rm $TASK_MASTER_HOME/test/driver.help
}

setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

@test 'Calls driver help when driver returns zero' {
  source $TASK_MASTER_HOME/lib/builtins/help.sh

  declare -A TASK_DRIVER_DICT
  DRIVER_DIR=$TASK_MASTER_HOME/test
  TASK_FILE_DRIVER=help_test
  TASK_DRIVER_DICT[help_test]=driver.help
  
  TASK_SUBCOMMAND="tester"

  run task_help
  assert_output "tester"
  refute_output --partial "Task Master"
}

@test 'Displays global help when driver returns non-zero' {
  source $TASK_MASTER_HOME/lib/builtins/help.sh
  TASK_SUBCOMMAND="chester"

  declare -A TASK_DRIVER_DICT
  DRIVER_DIR=$TASK_MASTER_HOME/test
  TASK_FILE_DRIVER=help_test
  TASK_DRIVER_DICT[help_test]=driver.help

  run task_help
  assert_output --partial 'Task Master'
}

