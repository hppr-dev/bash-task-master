setup_file() {
  export TASK_FILE_DRIVER=$TASK_MASTER_HOME/test/driver.help
  cat > $TASK_FILE_DRIVER <<EOF
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
  rm $TASK_FILE_DRIVER
}

setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

@test 'Should call driver help when driver returns zero' {
  source $TASK_MASTER_HOME/lib/builtins/help.sh
  
  TASK_SUBCOMMAND="tester"

  run task_help
  assert_output "tester"
  refute_output --partial "Task Master"
}

@test 'Should display global help when driver returns non-zero' {
  source $TASK_MASTER_HOME/lib/builtins/help.sh
  TASK_SUBCOMMAND="chester"

  run task_help
  assert_output --partial 'Task Master'
}

