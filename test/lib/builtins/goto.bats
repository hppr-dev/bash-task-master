setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATION_FILE=$TASK_MASTER_HOME/test/locations.goto

  cat > $LOCATION_FILE <<EOF
UUID_tmhome=$TASK_MASTER_HOME
UUID_project=$TASK_MASTER_HOME/test/proj
UUID_some_thing=$TASK_MASTER_HOME/test/proj
EOF

  cd $TASK_MASTER_HOME/test
  mkdir $TASK_MASTER_HOME/test/proj
}

teardown() {
  cd $TASK_MASTER_HOME/test/
  rmdir $TASK_MASTER_HOME/test/proj
  rm $TASK_MASTER_HOME/test/locations.goto
}

@test "Sets descripton" {
  source $TASK_MASTER_HOME/lib/builtins/goto.sh

  arguments_goto

  assert [ ! -z "$GOTO_DESCRIPTION" ]
}

@test "Changes the current directory" {
  source $TASK_MASTER_HOME/lib/builtins/goto.sh

  TASK_SUBCOMMAND="project"

  task_goto

  run pwd
  assert_output $TASK_MASTER_HOME/test/proj
}

@test "Stays in the current directory when location does not exist" {
  source $TASK_MASTER_HOME/lib/builtins/goto.sh

  TASK_SUBCOMMAND="foobar"

  cd $TASK_MASTER_HOME/test

  task_goto

  run pwd
  assert_output "$TASK_MASTER_HOME/test"
}

@test "Goes to directory with dash in name" {
  source $TASK_MASTER_HOME/lib/builtins/goto.sh

  TASK_SUBCOMMAND="some-thing"

  task_goto

  run pwd
  assert_output $TASK_MASTER_HOME/test/proj
}

set_return_directory() {
  cd $1
}

clean_up_state() {
  return 0
}
