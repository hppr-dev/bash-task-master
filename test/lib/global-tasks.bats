setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

@test 'Loads global modules when there is one to load' {
  TEST_MOD_FILE=$TASK_MASTER_HOME/modules/test-module.sh

  cat > $TEST_MOD_FILE <<EOF
task_something() {
  echo "I AM HERE"
}
EOF

  source $TASK_MASTER_HOME/lib/global-tasks.sh

  assert [ "$(task_something)" == "I AM HERE" ]

  rm $TEST_MOD_FILE
}

@test 'Loads global modules when are no enabled modules' {
  source $TASK_MASTER_HOME/lib/global-tasks.sh

  run declare -F

  refute_output --partial "task_something"
}


