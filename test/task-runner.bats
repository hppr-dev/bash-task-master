setup_file() {
  export PROJECT_DIR=$TASK_MASTER_HOME/test/runner-proj
  mkdir -p $PROJECT_DIR

  cat > $PROJECT_DIR/tasks.sh <<EOF
LOCAL_TASKS_UUID="runner-proj"

arguments_run_test() {
  RUN_TEST_OPTIONS="force:f:bool"
}

task_run_test() {
  echo "test has been run"
}

arguments_require_task() {
  REQUIRE_TASK_REQUIREMENTS="in:i:int"
}

task_require_task() {
  echo "require test"
}

task_run_recurse() {
  task run_test
}

task_change_dir() {
  echo "TASK_RETURN_DIR=$TASK_MASTER_HOME" >> \$STATE_FILE
}

task_export_var() {
  echo "export SOME_VAR=\"some value\"" >> \$STATE_FILE.export
}

task_set_trap() {
  echo "TASK_TERM_TRAP=\"echo exiting...\"" >> \$STATE_FILE
}

task_remove_state() {
  echo "DESTROY_STATE_FILE=T" >> \$STATE_FILE
}

EOF
}

teardown_file() {
  rm -r $PROJECT_DIR
}

setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

# The tests in this file are integration tests with the bash_driver
@test 'Executes a given task' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task run_test
  assert_output --partial "test has been run"
}

@test 'Executes a given task with global verbose argument' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task +v run_test
  assert_output --partial "test has been run"
}

@test 'Executes a given task with options' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task run_test -f
  assert_output --partial "test has been run"
}

@test 'Executes a task within a task' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task run_recurse
  assert_output --partial "test has been run"
}

@test 'Executes a global task' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $HOME

  run task help
  assert_success
}

@test 'Fails when LOCAL_TASKS_UUID is not set in task file' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  cp tasks.sh tasks.sh.bk
  awk -i inplace '/LOCAL_TASKS_UUID/ {next} 0' tasks.sh

  run task change_dir

  assert_failure

  cp tasks.sh.bk tasks.sh
}

@test 'Fails when an argument doesnt exist in spec' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task run_test -p
  assert_failure
}

@test 'Fails when a task does not have the right arguments' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task require_task
  assert_failure
}

@test Fails when a task arguments do not validate' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task require_task -i notanumber
  assert_failure
}

@test 'Fails when a task does not exist' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task missing
  assert_failure
}

@test 'Returns to directory specified in TASK_RETURN_DIR in state file' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run wrap_change_dir

  assert_output --partial $TASK_MASTER_HOME
}

@test 'Sets trap from TASK_TERM_TRAP in state file' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run wrap_set_trap

  assert_output --partial "echo exiting..." 
}

@test 'Removes state file when DESTROY_STATE_FILE is in state file' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task remove_state

  assert [ ! -f $TASK_MASTER_HOME/state/remove_state.vars ]
}

@test 'Exports variables in export state file' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run wrap_export_var

  assert_output --partial "some value"
}

@test 'Lists all tasks for tab completion' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  declare -A COMP_WORDS
  COMP_WORDS[0]=task

  run wrap_TaskTabCompletion

  assert_output --partial "bookmark"
  assert_output --partial "edit"
  assert_output --partial "global"
  assert_output --partial "goto"
  assert_output --partial "help"
  assert_output --partial "init"
  assert_output --partial "list"
  assert_output --partial "run_test"
  assert_output --partial "change_dir"
  assert_output --partial "export_var"
  assert_output --partial "set_trap"
  assert_output --partial "remove_state"
}

@test 'Lists limited tasks for tab completion' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  declare -A COMP_WORDS
  COMP_WORDS[0]=task
  COMP_WORDS[1]=g

  run wrap_TaskTabCompletion

  assert_output --partial "global"
  assert_output --partial "goto"
}

@test 'Only logs verbose logs when GLOBAL_VERBOSE is set' {
  source $TASK_MASTER_HOME/task-runner.sh

  run _tmverbose_echo "hello"
  assert_output ""

  GLOBAL_VERBOSE=T
  run _tmverbose_echo "hello"
  assert_output "hello"
}

wrap_change_dir() {
  task change_dir
  pwd
}

wrap_set_trap() {
  task set_trap
  trap
  return 0
}

wrap_export_var() {
  task export_var
  echo $SOME_VAR
}

wrap_TaskTabCompletion() {
  _TaskTabCompletion
  echo "${COMPREPLY[@]}"
}
