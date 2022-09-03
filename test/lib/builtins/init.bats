setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATIONS_FILE=$TASK_MASTER_HOME/test/locations.init
  export TEST_DIR=$TASK_MASTER_HOME/test/init_test
  export RUNNING_DIR=$TEST_DIR

  mkdir $TEST_DIR
}

teardown() {
  cd $TASK_MASTER_HOME/test
  rm $LOCATIONS_FILE
  rm -r $TEST_DIR
  if [[ -d "$TASK_MASTER_HOME/state/init_test" ]]
  then
    rm -r $TASK_MASTER_HOME/state/init_test
  fi
  if [[ -d "$TASK_MASTER_HOME/state/project" ]]
  then
    rm -r $TASK_MASTER_HOME/state/project
  fi
}

@test 'Initialize empty tasks file with UUID of current dir' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh
  cd $TEST_DIR

  task_init

  assert [ -f "$TEST_DIR/tasks.sh" ]

  run cat $TEST_DIR/tasks.sh
  assert_output "LOCAL_TASKS_UUID=init_test"

  run cat $LOCATIONS_FILE
  assert_output "UUID_init_test=$TEST_DIR"
}

@test 'Initialize empty hidden tasks file' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh
  cd $TASK_DIR
  ARG_HIDDEN=T

  task_init

  assert [ -f "$TEST_DIR/.tasks.sh" ]

  run cat $TEST_DIR/.tasks.sh
  assert_output "LOCAL_TASKS_UUID=init_test"

  run cat $LOCATIONS_FILE
  assert_output "UUID_init_test=$TEST_DIR"
}

@test 'Initialize with custom uuid' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh
  cd $TASK_DIR
  ARG_NAME=project

  task_init

  assert [ -f "$TEST_DIR/tasks.sh" ]

  run cat $TEST_DIR/tasks.sh
  assert_output "LOCAL_TASKS_UUID=project"

  run cat $LOCATIONS_FILE
  assert_output "UUID_project=$TEST_DIR"
}

@test 'Initialize with custom uuid and foreign dir' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh
  cd $TASK_MASTER_HOME/test
  ARG_NAME=project
  ARG_DIR=$TEST_DIR

  task_init

  assert [ -f "$TEST_DIR/tasks.sh" ]

  run cat $TEST_DIR/tasks.sh
  assert_output "LOCAL_TASKS_UUID=project"

  run cat $LOCATIONS_FILE
  assert_output "UUID_project=$TEST_DIR"
}

@test 'Sets description and options' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh

  arguments_init

  assert [ ! -z "$INIT_DESCRIPTION" ]
  assert [ ! -z "$INIT_OPTIONS" ]
}

@test 'Alerts user when file already exists' {
  source $TASK_MASTER_HOME/lib/builtins/init.sh
  cd $TASK_MASTER_HOME/test
  ARG_NAME=project
  ARG_DIR=$TEST_DIR
  touch $TEST_DIR/tasks.sh

  run task_init
  assert_output --partial "exists"

  run cat $TEST_DIR/tasks.sh
  assert_output ""
}
