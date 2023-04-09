setup_file() {
  cat > $TASK_MASTER_HOME/test/driver.help <<EOF
DRIVER_HELP_TASK=echo_subcommand
DRIVER_LIST_TASKS=match_tester

echo_subcommand() {
  if [[ "\$TASK_SUBCOMMAND" == "tester" ]]
  then
    echo \$1
  else
    return 1
  fi
}

match_tester() {
  echo "tester"
}

EOF

  cat > $TASK_MASTER_HOME/test/driver2.help <<EOF
DRIVER_HELP_TASK=say_global

say_global() {
  echo global
}

EOF
}

teardown_file() {
  rm $TASK_MASTER_HOME/test/driver.help
  rm $TASK_MASTER_HOME/test/driver2.help
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
  TASK_DRIVER=help_test
  TASK_DRIVER_DICT[help_test]=driver.help
  
  TASK_SUBCOMMAND="tester"

  run task_help
  assert_output "tester"
  refute_output --partial "Task Master"
}

@test 'Calls default task driver help when subcommand is not local' {
  source $TASK_MASTER_HOME/lib/builtins/help.sh

  declare -A TASK_DRIVER_DICT
  DRIVER_DIR=$TASK_MASTER_HOME/test
  TASK_FILE_DRIVER=help_test
  TASK_DRIVER_DICT[help_test]=driver.help

  TASK_DRIVER=help_test2
  TASK_DRIVER_DICT[help_test2]=driver2.help
  
  TASK_SUBCOMMAND="something"

  run task_help
  assert_output "global"
  refute_output --partial "tester"
  refute_output --partial "Task Master"
}

@test 'Displays global help when driver returns non-zero' {
  source $TASK_MASTER_HOME/lib/builtins/help.sh
  TASK_SUBCOMMAND="chester"

  declare -A TASK_DRIVER_DICT
  DRIVER_DIR=$TASK_MASTER_HOME/test
  TASK_FILE_DRIVER=help_test
  TASK_DRIVER=help_test
  TASK_DRIVER_DICT[help_test]=driver.help

  run task_help
  assert_output --partial 'Task Master'
}
