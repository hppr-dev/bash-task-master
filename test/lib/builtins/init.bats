setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATION_FILE=$TASK_MASTER_HOME/test/locations.init
  export TEST_DIR=$TASK_MASTER_HOME/test/init_test
  export RUNNING_DIR=$TEST_DIR
  export DEFAULT_TASK_DRIVER=bash

  echo "hello world" > $TASK_MASTER_HOME/templates/test.template

  mkdir $TEST_DIR
}

teardown() {
  echo "OUTPUT:"
  echo "$output"
  rm -f $TASK_MASTER_HOME/test/locations.init
  rm -rf $TEST_DIR
  rm -rf $TASK_MASTER_HOME/state/init_test
  rm -rf $TASK_MASTER_HOME/state/project
  rm -f $TASK_MASTER_HOME/templates/test.template
}

@test 'Initialize tasks file with default template and bookmarks the directory' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  declare -A TASK_FILE_NAME_DICT
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  declare -A TASK_DRIVER_DICT
  TASK_DRIVER_DICT[bash]=bash_driver.sh

  cd $TEST_DIR

  run task_init
  assert_output --partial "Bookmark $TEST_DIR init_test"

  assert [ -f "$TEST_DIR/tasks.sh" ]

  run diff $TASK_MASTER_HOME/templates/bash.template $TEST_DIR/tasks.sh
  assert_output ""
}

@test 'Fails to initialize tasks file when a task file is already set' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  declare -A TASK_FILE_NAME_DICT
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  TASK_FILE_NAME_DICT[.tasks.sh]=bash
  declare -A TASK_DRIVER_DICT
  TASK_DRIVER_DICT[bash]=bash_driver.sh

  cd $TEST_DIR

  TASK_FILE=tasks.sh

  run task_init

  assert_output --partial "Bookmark $TEST_DIR init_test"
  refute [ -f "$TEST_DIR/tasks.sh" ]
}

@test 'Initialize tasks file with specified template and bookmarks the directory' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  declare -A TASK_FILE_NAME_DICT
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  declare -A TASK_DRIVER_DICT
  TASK_DRIVER_DICT[bash]=bash_driver.sh

  cd $TASK_DIR
  ARG_TEMPLATE=test

  run task_init
  assert_output --partial "Bookmark $TEST_DIR init_test"

  assert [ -f "$TEST_DIR/tasks.sh" ]

  run diff $TASK_MASTER_HOME/templates/test.template $TEST_DIR/tasks.sh
  assert_output ""
}

@test 'Initialize with custom name' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  declare -A TASK_FILE_NAME_DICT
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  declare -A TASK_DRIVER_DICT
  TASK_DRIVER_DICT[bash]=bash_driver.sh

  cd $TASK_DIR
  ARG_NAME=project

  run task_init
  assert_output --partial "Bookmark $TEST_DIR project"
}

@test 'Initialize with custom name and foreign dir' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  declare -A TASK_FILE_NAME_DICT
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  declare -A TASK_DRIVER_DICT
  TASK_DRIVER_DICT[bash]=bash_driver.sh

  cd $TASK_MASTER_HOME/test

  ARG_NAME=project
  ARG_DIR=$TEST_DIR

  run task_init
  assert_output --partial "Bookmark $TEST_DIR project"

  assert [ -f "$TEST_DIR/tasks.sh" ]
}

@test 'Sets description and options' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  arguments_init

  assert [ ! -z "$INIT_DESCRIPTION" ]
  assert [ ! -z "$INIT_OPTIONS" ]
}

@test 'Alerts user when file already exists' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  declare -A TASK_FILE_NAME_DICT
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  declare -A TASK_DRIVER_DICT
  TASK_DRIVER_DICT[bash]=bash_driver.sh

  cd $TASK_MASTER_HOME/test
  touch $TEST_DIR/tasks.sh

  ARG_NAME=project
  ARG_DIR=$TEST_DIR

  run task_init
  assert_output --partial "exists"

  run cat $TEST_DIR/tasks.sh
  assert_output ""
}

@test 'Fails when driver does not exist' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  declare -A TASK_FILE_NAME_DICT
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  declare -A TASK_DRIVER_DICT
  TASK_DRIVER_DICT[bash]=bash_driver.sh

  cd $TEST_DIR

  ARG_DRIVER=missing

  run task_init
  assert_failure

  assert [ ! -f "$TEST_DIR/tasks.sh" ]
}

@test 'Creates empty file when template does not exist' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  declare -A TASK_FILE_NAME_DICT
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  declare -A TASK_DRIVER_DICT
  TASK_DRIVER_DICT[bash]=bash_driver.sh

  cd $TEST_DIR

  ARG_TEMPLATE=missing

  run task_init
  assert_success

  assert [ -f "$TEST_DIR/tasks.sh" ]

  run cat $TEST_DIR/tasks.sh
  assert_output ""
}

task_bookmark() {
  echo Bookmark $ARG_DIR $ARG_NAME
}
