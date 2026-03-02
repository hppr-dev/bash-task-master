setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
  export PROJECT_DIR=$TASK_MASTER_HOME/test/runner-proj
  mkdir -p $PROJECT_DIR
  mkdir -p $PROJECT_DIR/subdir

  echo "UUID_runner-proj=$PROJECT_DIR #TEST REMOVE ME" >> "$TASK_MASTER_HOME/state/locations.vars"

  cat > $PROJECT_DIR/tasks.sh <<EOF

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

task_save_something() {
  echo "saved=something" >> \$STATE_FILE
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

task_show_task_vars() {
  echo "TASK_DIR=\$TASK_DIR"
  echo "TASK_FILE=\$TASK_FILE"
  echo "RUNNING_DIR=\$RUNNING_DIR"
}

EOF

  export DRIVER_DIR=$TASK_MASTER_HOME/lib/drivers/

  echo "TASK_FILE_NAME_DICT[testtasks.myfile]=test_custom #TEST REMOVE ME" >> $DRIVER_DIR/installed_drivers.sh
  echo "TASK_DRIVER_DICT[test_custom]=test_custom_driver.sh #TEST REMOVE ME" >> $DRIVER_DIR/installed_drivers.sh

  cat > $DRIVER_DIR/test_custom_driver.sh <<EOF
DRIVER_EXECUTE_TASK=execute_test
DRIVER_LIST_TASKS=list_test
DRIVER_HELP_TASK=help_test
DRIVER_VALIDATE_TASK_FILE="not used in task runner"

execute_test() {
  echo I am executing: \$@
}

list_test() {
  echo "do something"
}

help_test() {
  echo I am helping: \$@
}

EOF
  export DRIVER_TEST_DIR=$TASK_MASTER_HOME/test/dtest
  mkdir -p $DRIVER_TEST_DIR
  touch $DRIVER_TEST_DIR/testtasks.myfile
}

teardown() {
  rm -r $PROJECT_DIR

  rm -r $DRIVER_TEST_DIR
  awk '/TEST REMOVE ME/ { next } { print }' $DRIVER_DIR/installed_drivers.sh > $DRIVER_DIR/installed_drivers.sh.tmp && mv $DRIVER_DIR/installed_drivers.sh{.tmp,}
  awk '/TEST REMOVE ME/ { next } { print }' $TASK_MASTER_HOME/state/locations.vars > $TASK_MASTER_HOME/state/locations.vars.tmp && mv $TASK_MASTER_HOME/state/locations.vars{.tmp,}
  rm $DRIVER_DIR/test_custom_driver.sh
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

@test 'Infers the STATE_FILE from a prokect directory' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  awk '/TEST REMOVE ME/ { next } { print }' $TASK_MASTER_HOME/state/locations.vars > $TASK_MASTER_HOME/state/locations.vars.tmp && mv $TASK_MASTER_HOME/state/locations.vars{.tmp,}

  if [[ -f "$TASK_MASTER_HOME/state/runner-proj.vars" ]]
  then
    rm "$TASK_MASTER_HOME/state/runner-proj.vars"
  fi

  run task save_something

  assert [ -f "$TASK_MASTER_HOME/state/runner-proj.vars" ]
}

@test 'Infers the STATE_FILE when running globally' {
  source $TASK_MASTER_HOME/task-runner.sh
  
  cd "$HOME"

  task_something_global() {
    echo "state file is $STATE_FILE"
  }

  run task something_global

  assert_output --partial "state file is $TASK_MASTER_HOME/state/global.vars"
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
  assert_output --partial "Invalid"
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

@test 'Internal task variables do not leak into caller environment' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR
  # Run task in this shell (no run) so we can inspect caller env after
  task list || true
  # Internal subshell-only variables must not be set in the caller
  refute [ -v TASK_DRIVER_DICT ]
  refute [ -v TASK_FILE_NAME_DICT ]
  refute [ -v TASK_FILE ]
  refute [ -v STATE_FILE ]
  refute [ -v RUN_NUMBER ]
  refute [ -v LOCAL_TASKS_REG ]
}

@test 'Caller shell variables are not changed by task subshell' {
  ISOLATED_TEST_VAR="caller value"
  ANOTHER_CALLER_VAR="unchanged"
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR
  task run_test
  # Variables that existed in the caller must be unchanged
  assert [ "$ISOLATED_TEST_VAR" = "caller value" ]
  assert [ "$ANOTHER_CALLER_VAR" = "unchanged" ]
}

@test 'Task file discovery uses parent directory when run from subdirectory' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR/subdir
  run task list
  assert_success
  assert_output --partial "run_test"
}

@test 'Sourcing task-runner adds only task, _TaskTabCompletion, _tmverbose_echo and TASK_MASTER_HOME' {
  run bash -c "export TASK_MASTER_HOME=$TASK_MASTER_HOME; source $TASK_MASTER_HOME/task-runner.sh; declare -F | grep -E 'declare -f (task|_TaskTabCompletion|_tmverbose_echo)\$' | wc -l"
  assert_success
  assert_output "3"
}

@test 'Global flag +v +s runs in silent mode (last wins)' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR
  run task +v +s run_test
  assert_success
  refute_output --partial "Running run_test"
}

@test 'Global flag +s +v runs in verbose mode (last wins)' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR
  run task +s +v run_test
  assert_success
  assert_output --partial "Running run_test"
}

@test 'Silent mode does not include runner or driver chatter in output' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR
  run task +s run_test
  assert_success
  refute_output --partial "Running run_test"
  assert_output --partial "test has been run"
}

@test 'Task sees correct TASK_DIR, TASK_FILE, and RUNNING_DIR' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR
  run task show_task_vars
  assert_success
  assert_output --partial "TASK_DIR=$PROJECT_DIR"
  assert_output --partial "TASK_FILE=$PROJECT_DIR/tasks.sh"
  assert_output --partial "RUNNING_DIR=$PROJECT_DIR"
  cd $PROJECT_DIR/subdir
  run task show_task_vars
  assert_success
  assert_output --partial "TASK_DIR=$PROJECT_DIR"
  assert_output --partial "TASK_FILE=$PROJECT_DIR/tasks.sh"
  assert_output --partial "RUNNING_DIR=$PROJECT_DIR/subdir"
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

@test 'Uses a working custom driver' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $DRIVER_TEST_DIR

  run task do something --special
  assert [ "${lines[0]}" == "I am executing: do something --special" ]
}

@test 'Fails if task file driver is missing an interface value' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $DRIVER_TEST_DIR

  awk '/DRIVER_EXECUTE_TASK/ { print "#" $0; next } { print }' $DRIVER_DIR/test_custom_driver.sh > $DRIVER_DIR/test_custom_driver.sh.tmp && mv $DRIVER_DIR/test_custom_driver.sh{.tmp,}

  run task do something --special
  assert_failure

  sed 's/#DRIVER_VALIDATE_ARGS/DRIVER_VALIDATE_ARGS/' $DRIVER_DIR/test_custom_driver.sh > $DRIVER_DIR/test_custom_driver.sh.tmp && mv $DRIVER_DIR/test_custom_driver.sh{.tmp,}
}

@test 'Calls global list task in custom driver task file scope' {
  source $TASK_MASTER_HOME/task-runner.sh

  cd $DRIVER_TEST_DIR

  run task list --local

  assert_output --partial "do"
  assert_output --partial "something"
  refute_output --partial "global"
}

@test 'Calls global help task in custom driver task file scope' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $DRIVER_TEST_DIR

  run task help do
  assert_output --partial "I am helping: do"
}

@test 'Installs tab completion on aliases to task command' {
  alias mytaskalias=task
  source $TASK_MASTER_HOME/task-runner.sh
  run display_completes
  assert_output --partial "_TaskTabCompletion mytaskalias"
}

@test 'list -a --json outputs valid JSON array of task names' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task list -a --json
  assert_success
  assert_output --partial '['
  assert_output --partial ']'
  assert_output --partial '"run_test"'
  assert_output --partial '"require_task"'
}

@test 'list -a -j outputs same JSON as --json' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task list -a -j
  assert_success
  assert_output --partial '['
  assert_output --partial '"run_test"'
}

@test 'list --json with no tasks outputs empty JSON array' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $TASK_MASTER_HOME

  run task list --json
  assert_success
  assert_output --partial '[]'
  assert_line --partial '[]'
}

@test 'help require_task --json outputs valid JSON with required optional subcommands' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task help require_task --json
  assert_success
  assert_output --partial '"description"'
  assert_output --partial '"required"'
  assert_output --partial '"optional"'
  assert_output --partial '"subcommands"'
  assert_output --partial '"long"'
  assert_output --partial '"short"'
  assert_output --partial '"type"'
  assert_output --partial '"--in"'
  assert_output --partial '"-i"'
  assert_output --partial '"int"'
}

@test 'help --json mytask works like help mytask --json' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task help --json require_task
  assert_success
  assert_output --partial '"required"'
  assert_output --partial '"--in"'
}

@test 'help --json with no task outputs minimal JSON not HELP_STRING' {
  source $TASK_MASTER_HOME/task-runner.sh
  cd $PROJECT_DIR

  run task help --json
  assert_success
  assert_output --partial '{"description":"","required":[],"optional":[],"subcommands":[]}'
  refute_output --partial "Task Master"
}

display_completes() {
  complete | grep _TaskTabCompletion
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
