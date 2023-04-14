setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATION_FILE=$TASK_MASTER_HOME/test/locations.state
  echo "UUID_tmhome=$TASK_MASTER_HOME" > "$LOCATION_FILE"

  export STATE_FILE=$TASK_MASTER_HOME/state/command.vars
  echo hello=world > "$STATE_FILE"
}

teardown() {
  rm "$TASK_MASTER_HOME/test/locations.state"
  rm "$STATE_FILE"
}

@test 'Shows all variables' {
  source "$TASK_MASTER_HOME/lib/builtins/state.sh"

  TASK_SUBCOMMAND="show"

  run task_state

  assert_output --partial "hello=world"
}

@test 'Sets a variable' {
  source "$TASK_MASTER_HOME/lib/builtins/state.sh"

  ARG_KEY=key
  ARG_VALUE=value
  TASK_SUBCOMMAND="set"

  run task_state

  assert_output --partial "set key=value"
}

@test 'Unsets a variable' {
  source "$TASK_MASTER_HOME/lib/builtins/state.sh"

  ARG_KEY=key
  TASK_SUBCOMMAND="unset"

  run task_state

  assert_output --partial "unset key"
}

@test 'Edits a commands variables' {
  source "$TASK_MASTER_HOME/lib/builtins/state.sh"

  DEFAULT_EDITOR=echo

  ARG_COMMAND=command
  TASK_SUBCOMMAND=edit

  run task_state

  assert_output --partial "$COMMAND_STATE_FILE"
}

@test 'Clean removes locations from location file that no longer exist' {
  source "$TASK_MASTER_HOME/lib/builtins/state.sh"

  echo "UUID_hello=$TASK_MASTER_HOME/test/doesnotexist" >> "$LOCATION_FILE"

  TASK_SUBCOMMAND="clean"

  task_state

  run cat "$LOCATION_FILE"

  assert_output --partial "UUID_tmhome=$TASK_MASTER_HOME"
  refute_output --partial "UUID_hello=$TASK_MASTER_HOME/test/doesnotexist"
}

@test 'Clean removes state files that refer to locations that no longer exist' {
  source "$TASK_MASTER_HOME/lib/builtins/state.sh"

  mkdir -p "$TASK_MASTER_HOME/state/doesnotexist"
  echo some=var > "$TASK_MASTER_HOME/state/doesnotexist/command.vars"

  TASK_SUBCOMMAND="clean"

  task_state

  assert [ ! -d "$TASK_MASTER_HOME/state/doesnotexist" ]
}

@test 'Clean removes empty state files' {
  source "$TASK_MASTER_HOME/lib/builtins/state.sh"

  touch "$TASK_MASTER_HOME/state/empty.vars"

  TASK_SUBCOMMAND="clean"

  run task_state

  assert [ ! -f "$TASK_MASTER_HOME/state/empty.vars" ]
}

@test 'Defines descriptions and arguments' {
  source "$TASK_MASTER_HOME/lib/builtins/state.sh"
  
  arguments_state

  assert [ ! -z "$SUBCOMMANDS" ]
  assert [ ! -z "$SHOW_DESCRIPTION" ]
  assert [ ! -z "$SET_DESCRIPTION" ]
  assert [ ! -z "$UNSET_DESCRIPTION" ]
  assert [ ! -z "$EDIT_DESCRIPTION" ]
  assert [ ! -z "$CLEAN_DESCRIPTION" ]
}

persist_var() {
  echo "set $1=$2"
}

remove_var() {
  echo "unset $1"
}
