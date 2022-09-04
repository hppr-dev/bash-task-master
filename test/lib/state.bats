setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export STATE_FILE=$TASK_MASTER_HOME/test/test.state
}

teardown() {
  if [[ -f "$STATE_FILE" ]]
  then
    rm $STATE_FILE
  fi
}

@test 'Persists var in state_file' {
  source $TASK_MASTER_HOME/lib/state.sh

  persist_var "MY_VAR" "hello"

  run cat $STATE_FILE
  assert_output 'MY_VAR="hello"'
}

@test 'Removes var in state_file' {
  source $TASK_MASTER_HOME/lib/state.sh

  echo "hello=world" > $STATE_FILE
  echo "foo=bar" >> $STATE_FILE

  remove_var "hello"

  run cat $STATE_FILE
  assert_output "foo=bar"
}

@test 'Exports var in an export file' {
  source $TASK_MASTER_HOME/lib/state.sh

  export_var "EXPORT_VAL" "something"

  assert [ -f $STATE_FILE.export ]
  run cat $STATE_FILE.export
  assert_output 'export EXPORT_VAL="something"'
  
  rm $STATE_FILE.export
}

@test 'Holds the current value of variable in a hold file' {
  source $TASK_MASTER_HOME/lib/state.sh

  HOLDME=please
  hold_var "HOLDME"

  assert [ -f $STATE_FILE.hold ]
  run cat $STATE_FILE.hold
  assert_output 'HOLDME="please"'

  rm $STATE_FILE.hold
}

@test 'Releases variable by putting it back in exports' {
  source $TASK_MASTER_HOME/lib/state.sh

  echo 'HOLDED="variable"' >> $STATE_FILE.hold

  release_var "HOLDED"

  assert [ -f "$STATE_FILE.export" ]
  run cat $STATE_FILE.export
  assert_output 'HOLDED="variable"'

  rm $STATE_FILE.hold
  rm $STATE_FILE.export
}

@test 'Sets a variable to set a trap' {
  source $TASK_MASTER_HOME/lib/state.sh

  set_trap "echo hello"

  run cat $STATE_FILE
  assert_output 'TASK_TERM_TRAP="echo hello"'
}

@test 'Unsets a trap' {
  source $TASK_MASTER_HOME/lib/state.sh

  echo 'TASK_TERM_TRAP="echo my trap"' > $STATE_FILE

  unset_trap

  run cat $STATE_FILE
  assert_output ""
}

@test 'Sets state file for clean up' {
  source $TASK_MASTER_HOME/lib/state.sh

  touch $STATE_FILE

  clean_up_state

  grep 'DESTROY_STATE_FILE="1"' $STATE_FILE
  assert [ "$?" == 0 ]
}

@test 'Sets return directory' {
  source $TASK_MASTER_HOME/lib/state.sh

  set_return_directory "$TASK_MASTER_HOME"

  run cat $STATE_FILE
  assert_output "TASK_RETURN_DIR=\"$TASK_MASTER_HOME\""
}

@test 'Loads state file' {
  source $TASK_MASTER_HOME/lib/state.sh

  echo 'LOADME="yes"' >> $STATE_FILE

  load_state

  assert [ "$LOADME" == "yes" ]
}

@test 'Removes value from file' {
  source $TASK_MASTER_HOME/lib/state.sh

  echo 'myvar="wellwellwell"' > $STATE_FILE

  remove_file_value "myvar" $STATE_FILE

  run cat $STATE_FILE
  assert_output ""
}
