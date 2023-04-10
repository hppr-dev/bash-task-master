setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATION_FILE=$TASK_MASTER_HOME/test/locations.global
  echo "UUID_tmhome=$TASK_MASTER_HOME" > "$LOCATION_FILE"

  export STATE_DIR=$TASK_MASTER_HOME/state

  export COMMAND_STATE_FILE=$TASK_MASTER_HOME/state/command.vars
  echo hello=world > $COMMAND_STATE_FILE

  export OTHER_STATE_FILE=$TASK_MASTER_HOME/state/other.vars
  echo foo=bar > $OTHER_STATE_FILE

  cp -r $TASK_MASTER_HOME{,.bk}

  mkdir -p $TASK_MASTER_HOME/test/releases/latest/

  echo "BTM_VERSION=2.0" > $TASK_MASTER_HOME/test/releases/latest/version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases" >> $TASK_MASTER_HOME/test/releases/latest/version.env

  cd $TASK_MASTER_HOME

  mkdir -p dist/lib
  cp $TASK_MASTER_HOME/task-runner.sh dist
  echo "#ABEXCDAFEGRADSF" >> dist/task-runner.sh
  touch test_dict/lib/updated

  tar -xzf $TASK_MASTER_HOME/test/releases/latest/btm.tar.gz dist

  rm -r dist
}

teardown() {
  rm $TASK_MASTER_HOME/test/locations.global
  rm $COMMAND_STATE_FILE
  rm $OTHER_STATE_FILE

  mv $TASK_MASTER_HOME{.bk,}
}

@test 'Debug shows all variables when command not given' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  TASK_SUBCOMMAND="debug"

  run task_global

  assert_output --partial "hello=world"
  assert_output --partial "foo=bar"
}

@test 'Debug shows variables for given command' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_COMMAND=command
  TASK_SUBCOMMAND="debug"

  run task_global

  assert_output --partial "hello=world"
  refute_output --partial "foo=bar"
}

@test 'Sets a variable for a command' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_KEY=key
  ARG_VALUE=value
  ARG_COMMAND=command
  TASK_SUBCOMMAND="set"

  run task_global

  assert_output --partial "set key=value"
}

@test 'Unsets a variable for a command' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_KEY=key
  ARG_COMMAND=command
  TASK_SUBCOMMAND="unset"

  run task_global

  assert_output --partial "unset key"
}

@test 'Edits a commands variables' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  DEFAULT_EDITOR=echo

  ARG_COMMAND=command
  TASK_SUBCOMMAND=edit

  run task_global

  assert_output --partial "$COMMAND_STATE_FILE"
}

@test 'Clean removes locations from location file that no longer exist' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  echo "UUID_hello=$TASK_MASTER_HOME/test/doesnotexist" >> $LOCATION_FILE

  TASK_SUBCOMMAND="clean"

  task_global

  run cat $LOCATION_FILE

  assert_output --partial "UUID_tmhome=$TASK_MASTER_HOME"
  refute_output --partial "UUID_hello=$TASK_MASTER_HOME/test/doesnotexist"
}

@test 'Clean removes state files that refer to locations that no longer exist' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  mkdir -p $TASK_MASTER_HOME/state/doesnotexist
  echo some=var > $TASK_MASTER_HOME/state/doesnotexist/command.vars

  TASK_SUBCOMMAND="clean"

  task_global

  assert [ ! -d "$TASK_MASTER_HOME/state/doesnotexist" ]
}

@test 'Clean removes empty state files' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  touch $TASK_MASTER_HOME/state/empty.vars

  TASK_SUBCOMMAND="clean"

  run task_global

  assert [ ! -f "$TASK_MASTER_HOME/state/empty.vars" ]
}

@test 'Defines descriptions and arguments' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh
  
  arguments_global

  assert [ ! -z "$SUBCOMMANDS" ]
  assert [ ! -z "$DEBUG_DESCRIPTION" ]
  assert [ ! -z "$DEBUG_OPTIONS" ]
  assert [ ! -z "$SET_DESCRIPTION" ]
  assert [ ! -z "$SET_REQUIREMENTS" ]
  assert [ ! -z "$UNSET_DESCRIPTION" ]
  assert [ ! -z "$UNSET_REQUIREMENTS" ]
  assert [ ! -z "$EDIT_DESCRIPTION" ]
  assert [ ! -z "$EDIT_REQUIREMENTS" ]
  assert [ ! -z "$CLEAN_DESCRIPTION" ]
}

@test 'Updates development version to development version' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  echo "BTM_VERSION=dev" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=https://github.com/hppr-dev/bash-task-master.git" >> $TASK_MASTER_HOME/version.env

  git() {
    echo "$@"
  }

  TASK_SUBCOMMAND="update"

  run task_global

  assert_output --partial pull
}

@test 'Updates release version to release version' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  echo "BTM_VERSION=1.0" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> $TASK_MASTER_HOME/version.env

  TASK_SUBCOMMAND="update"

  run task_global

  assert [ -f $TASK_MASTER_HOME/lib/updated ]
  assert grep "#ABEXCDAFEGRADSF" $TASK_MASTER_HOME/task-runner.sh
}

@test 'Updates release version to dev version' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  echo "BTM_VERSION=1.0" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> $TASK_MASTER_HOME/version.env

  TASK_SUBCOMMAND="update"

  run task_global
}

persist_var() {
  echo set $1=$2
}

remove_var() {
  echo unset $1
}
