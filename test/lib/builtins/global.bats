setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATION_FILE=$TASK_MASTER_HOME/test/locations.global
  echo "UUID_tmhome=$TASK_MASTER_HOME" > "$LOCATION_FILE"

  export STATE_DIR=$TASK_MASTER_HOME/state

  export COMMAND_STATE_FILE=$TASK_MASTER_HOME/state/command.vars
  echo hello=world > "$COMMAND_STATE_FILE"

  export OTHER_STATE_FILE=$TASK_MASTER_HOME/state/other.vars
  echo foo=bar > "$OTHER_STATE_FILE"

  cd "$TASK_MASTER_HOME" || exit

  cp -r lib{,.bk}
  cp -r awk{,.bk}
  cp -r task-runner.sh{,.bk}
  cp -r version.env{,.bk}
  cp -r LICENSE.md{,.bk}

  LATEST_URL=$TASK_MASTER_HOME/test/releases/latest/download
  OLDVER_URL=$TASK_MASTER_HOME/test/releases/download/0.1

  mkdir -p "$LATEST_URL/dist/lib" "$OLDVER_URL/dist/lib"

  # Create latest repo
  echo "BTM_VERSION=2.0" > "$LATEST_URL/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases" >> "$LATEST_URL/version.env"
  cp task-runner.sh "$LATEST_URL/dist"
  echo "#ABEXCDAFEGRADSF" >> "$LATEST_URL/dist/task-runner.sh"
  touch "$LATEST_URL/dist/lib/updated"
  tar -czf "$LATEST_URL/btm.tar.gz" -C "$LATEST_URL" "$LATEST_URL/dist"

  #Create oldversion repo
  echo "BTM_VERSION=0.1" > "$OLDVER_URL/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases" >> "$OLDVER_URL/version.env"
  cp task-runner.sh "$OLDVER_URL/dist"
  echo "#OLDVER1234" >> "$OLDVER_URL/dist/task-runner.sh"
  touch "$OLDVER_URL/dist/lib/downgraded"
  tar -czf "$OLDVER_URL/btm.tar.gz" -C "$OLDVER_URL" "$OLDVER_URL/dist"

  rm -r "$LATEST_URL/dist" "$OLDVER_URL/dist"
}

teardown() {
  rm "$TASK_MASTER_HOME/test/locations.global"
  rm "$COMMAND_STATE_FILE"
  rm "$OTHER_STATE_FILE"

  cd "$TASK_MASTER_HOME" || exit
  rm -r test/releases
  rm -r lib
  mv lib{.bk,}
  rm -r awk
  mv awk{.bk,}
  mv task-runner.sh{.bk,}
  mv version.env{.bk,}
  mv LICENSE.md{.bk,}
}

@test 'Debug shows all variables when command not given' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  TASK_SUBCOMMAND="debug"

  run task_global

  assert_output --partial "hello=world"
  assert_output --partial "foo=bar"
}

@test 'Debug shows variables for given command' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  ARG_COMMAND=command
  TASK_SUBCOMMAND="debug"

  run task_global

  assert_output --partial "hello=world"
  refute_output --partial "foo=bar"
}

@test 'Sets a variable for a command' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  ARG_KEY=key
  ARG_VALUE=value
  ARG_COMMAND=command
  TASK_SUBCOMMAND="set"

  run task_global

  assert_output --partial "set key=value"
}

@test 'Unsets a variable for a command' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  ARG_KEY=key
  ARG_COMMAND=command
  TASK_SUBCOMMAND="unset"

  run task_global

  assert_output --partial "unset key"
}

@test 'Edits a commands variables' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  DEFAULT_EDITOR=echo

  ARG_COMMAND=command
  TASK_SUBCOMMAND=edit

  run task_global

  assert_output --partial "$COMMAND_STATE_FILE"
}

@test 'Clean removes locations from location file that no longer exist' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "UUID_hello=$TASK_MASTER_HOME/test/doesnotexist" >> $LOCATION_FILE

  TASK_SUBCOMMAND="clean"

  task_global

  run cat $LOCATION_FILE

  assert_output --partial "UUID_tmhome=$TASK_MASTER_HOME"
  refute_output --partial "UUID_hello=$TASK_MASTER_HOME/test/doesnotexist"
}

@test 'Clean removes state files that refer to locations that no longer exist' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  mkdir -p $TASK_MASTER_HOME/state/doesnotexist
  echo some=var > $TASK_MASTER_HOME/state/doesnotexist/command.vars

  TASK_SUBCOMMAND="clean"

  task_global

  assert [ ! -d "$TASK_MASTER_HOME/state/doesnotexist" ]
}

@test 'Clean removes empty state files' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  touch $TASK_MASTER_HOME/state/empty.vars

  TASK_SUBCOMMAND="clean"

  run task_global

  assert [ ! -f "$TASK_MASTER_HOME/state/empty.vars" ]
}

@test 'Defines descriptions and arguments' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"
  
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

@test 'Updates development to development' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=dev" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=https://github.com/hppr-dev/bash-task-master.git" >> $TASK_MASTER_HOME/version.env

  git() {
    echo git "$@"
  }

  TASK_SUBCOMMAND="update"

  run task_global

  assert_output --partial "git pull"
}

@test 'Checks development to development when there are no updates' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=dev" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=https://github.com/hppr-dev/bash-task-master.git" >> $TASK_MASTER_HOME/version.env

  git() {
    if [[ "$1" == "rev-parse" ]]
    then
      echo same
      return
    fi
    echo git "$@"
  }

  ARG_CHECK=T
  TASK_SUBCOMMAND="update"

  run task_global

  assert_output --partial "no updates"
  refute_output --partial "git pull"
}

@test 'Checks development to development when there are updates' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=dev" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=https://github.com/hppr-dev/bash-task-master.git" >> $TASK_MASTER_HOME/version.env

  git() {
    echo git "$@"
  }

  ARG_CHECK=T
  TASK_SUBCOMMAND="update"

  run task_global

  assert_output --partial "changes to pull."
  refute_output --partial "git pull"
}

@test 'Updates release to latest release' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> $TASK_MASTER_HOME/version.env

  TASK_SUBCOMMAND="update"

  run task_global <<< "\n"

  assert_output --partial "Press enter"
  assert grep "#ABEXCDAFEGRADSF" $TASK_MASTER_HOME/task-runner.sh
  assert [ -f $TASK_MASTER_HOME/lib/updated ]
}

@test 'Updates release to specified release' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> "$TASK_MASTER_HOME/version.env"

  ARG_VERSION=0.1
  TASK_SUBCOMMAND="update"

  run task_global <<< "\n"

  assert_output --partial "Press enter"
  assert grep "#OLDVER1234" $TASK_MASTER_HOME/task-runner.sh
  assert [ -f $TASK_MASTER_HOME/lib/downgraded ]
}

@test 'Fails to update release to release when target version does not exist' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> $TASK_MASTER_HOME/version.env

  ARG_VERSION=6.6
  TASK_SUBCOMMAND="update"

  run task_global <<< "\n"

  assert_output --partial "Could not retrieve version"
  refute_output --partial "grep:"
  refute_output --partial "rm:"
}

@test 'Checks release to release when there are updates' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> $TASK_MASTER_HOME/version.env

  TASK_SUBCOMMAND="update"

  ARG_CHECK=T
  run task_global

  assert_output --partial "Updates are available"
  refute_output --partial "Press enter"
  refute grep "#ABEXCDAFEGRADSF" $TASK_MASTER_HOME/task-runner.sh
  refute [ -f $TASK_MASTER_HOME/lib/updated ]
}

@test 'Checks release to release when there are no updates' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=2.0" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases" >> $TASK_MASTER_HOME/version.env

  TASK_SUBCOMMAND="update"

  ARG_CHECK=T
  run task_global

  assert_output --partial "does not differ"
  refute_output --partial "Press enter"
  refute grep "#ABEXCDAFEGRADSF" $TASK_MASTER_HOME/task-runner.sh
  refute [ -f $TASK_MASTER_HOME/lib/updated ]
}

@test 'Updates release version to dev version' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > $TASK_MASTER_HOME/version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> $TASK_MASTER_HOME/version.env

  ARG_DEV=T
  TASK_SUBCOMMAND="update"

  git() {
    if [[ "$1" == "clone" ]]
    then
      mkdir "$3"
    fi
    echo git "$@"
  }

  mv() {
    echo moving "$@"
  }

  touch modules/som-mod templates/somet state/state_file

  run task_global <<< "\n"

  assert_output --partial "Press enter"
  assert_output --partial "git clone"
  assert_output --partial "moving $TASK_MASTER_HOME /tmp/task-master-1.0"
  assert_output --partial "moving $TASK_MASTER_HOME.new $TASK_MASTER_HOME"
  assert_output --partial "moving $TASK_MASTER_HOME/modules $TASK_MASTER_HOME.new/modules"
  assert_output --partial "moving $TASK_MASTER_HOME/templates $TASK_MASTER_HOME.new/templates"
  assert_output --partial "moving $TASK_MASTER_HOME/state $TASK_MASTER_HOME.new/state"
  assert_output --partial "moving $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh $TASK_MASTER_HOME.new/lib/drivers/installed_drivers.sh"
}

persist_var() {
  echo set $1=$2
}

remove_var() {
  echo unset $1
}
