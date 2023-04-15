setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export STATE_FILE=$TASK_MASTER_HOME/test/test.state
  export MODULE_STATE_FILE=$TASK_MASTER_HOME/test/module.state
}

teardown() {
  rm -f "$STATE_FILE"{,.hold,.export}
  rm -f "$MODULE_STATE_FILE"{,.hold,.export}
}

@test 'Persists var in state_file' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  persist_var "MY_VAR" "hello"

  run cat "$STATE_FILE"
  assert_output 'MY_VAR="hello"'
}

@test 'Removes var in state_file' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  echo "hello=world" > "$STATE_FILE"
  echo "foo=bar" >> "$STATE_FILE"

  remove_var "hello"

  run cat "$STATE_FILE"
  assert_output "foo=bar"
}

@test 'Persists var in module state file' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  persist_module_var "MY_VAR" "hello"

  run cat "$MODULE_STATE_FILE"
  assert_output 'MY_VAR="hello"'
}

@test 'Removes var in module state file' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  echo "hello=world" > "$MODULE_STATE_FILE"
  echo "foo=bar" >> "$MODULE_STATE_FILE"

  remove_module_var "hello"

  run cat "$MODULE_STATE_FILE"
  assert_output "foo=bar"
}

@test 'Exports var in an export file' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  export_var "EXPORT_VAL" "something"

  assert [ -f "$STATE_FILE.export" ]
  run cat "$STATE_FILE.export"
  
}

@test 'Holds the current value of variable in a hold file' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  HOLDME=please
  hold_var "HOLDME"

  assert [ -f "$STATE_FILE.hold" ]
  run cat "$STATE_FILE.hold"
  assert_output 'HOLDME="please"'
}

@test 'Releases variable by putting it back in exports' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  echo 'HOLDED="variable"' >> "$STATE_FILE.hold"

  release_var "HOLDED"

  assert [ -f "$STATE_FILE.export" ]
  run cat "$STATE_FILE.export"
  assert_output 'HOLDED="variable"'
}

@test 'Holds the current value of variable in a module hold file' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  HOLDME=foobar
  hold_module_var "HOLDME"

  assert [ -f "$MODULE_STATE_FILE.hold" ]
  run cat "$MODULE_STATE_FILE.hold"
  assert_output 'HOLDME="foobar"'
}

@test 'Releases module variable by putting it back in exports' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  echo 'HOLDED="mememe"' >> "$MODULE_STATE_FILE.hold"

  release_module_var "HOLDED"

  assert [ -f "$STATE_FILE.export" ]
  run cat "$STATE_FILE.export"
  assert_output 'HOLDED="mememe"'
}

@test 'Sets a variable to set a trap' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  set_trap "echo hello"

  run cat "$STATE_FILE"
  assert_output 'TASK_TERM_TRAP="echo hello"'
}

@test 'Unsets a trap' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  echo 'TASK_TERM_TRAP="echo my trap"' > "$STATE_FILE"

  unset_trap

  run cat "$STATE_FILE"
  assert_output 'TASK_TERM_TRAP="-"'
}

@test 'Sets state file for clean up' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  touch "$STATE_FILE"

  clean_up_state

  grep 'DESTROY_STATE_FILE="1"' "$STATE_FILE"
  assert [ "$?" == 0 ]
}

@test 'Sets return directory' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  set_return_directory "$TASK_MASTER_HOME"

  run cat "$STATE_FILE"
  assert_output "TASK_RETURN_DIR=\"$TASK_MASTER_HOME\""
}

@test 'Loads state files' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  echo 'LOADME="yes"' >> "$STATE_FILE"
  echo 'MOD_LOADME="hello"' >> "$MODULE_STATE_FILE"

  load_state

  assert [ "$LOADME" == "yes" ]
  assert [ "$MOD_LOADME" == "hello" ]
}

@test 'Removes value from file' {
  source "$TASK_MASTER_HOME/lib/state-functions.sh"

  echo 'myvar="wellwellwell"' > "$STATE_FILE"

  remove_file_value "myvar" "$STATE_FILE"

  run cat "$STATE_FILE"
  assert_output ""
}
