setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export TASK_FILE=$TASK_MASTER_HOME/test/test_task_file.sh
  export DEFAULT_EDITOR=return_0
  export DRIVER_VALIDATE_TASK_FILE="bash -n "

  touch $TASK_FILE
}

teardown() {
  rm -f $TASK_FILE
}

@test "Sets description" {
  source $TASK_MASTER_HOME/lib/builtins/edit.sh

  arguments_edit

  assert [ ! -z "$EDIT_DESCRIPTION" ]
}

@test "Fails if a task file is not found" {
  source $TASK_MASTER_HOME/lib/builtins/edit.sh
  TASK_FILE=""

  run task_edit
  assert_failure
}

@test "Validates tasks file" {
  source $TASK_MASTER_HOME/lib/builtins/edit.sh

  run task_edit

  assert_output --partial "Changes validated."
}

@test "Asks to retry if not validated" {
  source $TASK_MASTER_HOME/lib/builtins/edit.sh
  mess_up_tasks_file
  DRIVER_VALIDATE_TASK_FILE=validate_success

  run task_edit <<< "no"
  assert_output --partial "Could not validate"
}

@test "Reverts if not validated" {
  source $TASK_MASTER_HOME/lib/builtins/edit.sh
  DEFAULT_EDITOR=mess_up_tasks_file

  run task_edit <<< "no"
  assert_output --partial "Could not validate"
  
  run cat $TASK_FILE
  assert_output ""
}

@test "Validates tasks file after fixing" {
  source $TASK_MASTER_HOME/lib/builtins/edit.sh
  DEFAULT_EDITOR=fix_tasks_file
  mess_up_tasks_file

  run task_edit <<< "no"
  assert_output --partial "Changes validated."
}

fix_tasks_file() {
  cat > $TASK_FILE <<EOF
hello() {
  return 0
}
EOF
}

mess_up_tasks_file() {
  cat > $TASK_FILE <<EOF
hello() {
  if [[ this == should ]]
    echo missing then
  fi
}
EOF
}

return_0() {
  return 0
}
