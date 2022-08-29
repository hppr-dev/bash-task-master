setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATIONS_FILE=$TASK_MASTER_HOME/test/locations.global
  touch $LOCATIONS_FILE
}

teardown() {
  rm $LOCATIONS_FILE
}

@test 'Debug shows all variables when command not given' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  TASK_SUBCOMMAND="debug"
}

@test 'Debug shows variables for given command' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_COMMAND=command
  TASK_SUBCOMMAND="debug"
}

@test 'Sets a variable for a command' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_KEY=key
  ARG_VALUE=value
  ARG_COMMAND=command
  TASK_SUBCOMMAND="set"
}

@test 'Unsets a variable for a command' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_KEY=key
  ARG_COMMAND=command
  TASK_SUBCOMMAND="unset"
}

@test 'Edits a commands variables' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_COMMAND=command
  TASK_SUBCOMMAND="edit"
}

@test 'Clean removes locations from location file that no longer exist' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  TASK_SUBCOMMAND="clean"
}

@test 'Clean removes state files that refer to locations that no longer exist' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  TASK_SUBCOMMAND="clean"
}

@test 'Clean removes empty state files' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  TASK_SUBCOMMAND="clean"
}
