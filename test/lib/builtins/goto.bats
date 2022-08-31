setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATIONS_FILE=$TASK_MASTER_HOME/test/locations.goto

  cat > $LOCATIONS_FILE <<EOF
UUID_tmhome=$TASK_MASTER_HOME
UUID_project=$TASK_MASTER_HOME/test/proj
EOF

  cd $TASK_MASTER_HOME/test
  mkdir $TASK_MASTER_HOME/test/proj
}

teardown() {
  cd $TASK_MASTER_HOME/test/
  rmdir $TASK_MASTER_HOME/test/proj
  rm $LOCATIONS_FILE
}

@test "Should goto directory" {
  source $TASK_MASTER_HOME/lib/builtins/goto.sh

  TASK_SUBCOMMAND="project"

  task_goto

  run pwd
  assert_output $TASK_MASTER_HOME/test/proj
}

@test "Should stay when location does not exist" {
  source $TASK_MASTER_HOME/lib/builtins/goto.sh

  TASK_SUBCOMMAND="foobar"

  cd $TASK_MASTER_HOME/test

  task_goto

  run pwd
  assert_output $TASK_MASTER_HOME/test
}

set_return_directory() {
  cd $1
}

clean_up_state() {
  return 0
}
