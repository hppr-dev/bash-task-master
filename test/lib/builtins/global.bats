setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

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
  cd "$LATEST_URL" || exit
  echo "BTM_VERSION=2.0" > version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases" >> version.env
  cp "$TASK_MASTER_HOME/task-runner.sh" dist
  echo "#ABEXCDAFEGRADSF" >> dist/task-runner.sh
  touch dist/lib/updated
  tar -czf btm.tar.gz dist

  #Create oldversion repo
  cd "$OLDVER_URL" || exit
  echo "BTM_VERSION=0.1" > version.env
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases" >> version.env
  cp "$TASK_MASTER_HOME/task-runner.sh" dist
  echo "#OLDVER1234" >> dist/task-runner.sh
  touch dist/lib/downgraded
  tar -czf btm.tar.gz dist

  rm -r "$LATEST_URL/dist" "$OLDVER_URL/dist"
}

teardown() {
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

@test 'Defines descriptions and arguments' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"
  
  arguments_global

  assert [ ! -z "$SUBCOMMANDS" ]
  assert [ ! -z "$UPDATE_DESCRIPTION" ]
}

@test 'Updates development to development' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=dev" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=https://github.com/hppr-dev/bash-task-master.git" >> "$TASK_MASTER_HOME/version.env"

  git() {
    echo git "$@"
  }

  TASK_SUBCOMMAND="update"

  run task_global

  assert_output --partial "git pull"
}

@test 'Checks development to development when there are no updates' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=dev" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=https://github.com/hppr-dev/bash-task-master.git" >> "$TASK_MASTER_HOME/version.env"

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

  echo "BTM_VERSION=dev" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=https://github.com/hppr-dev/bash-task-master.git" >> "$TASK_MASTER_HOME/version.env"

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

  echo "BTM_VERSION=1.0" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> "$TASK_MASTER_HOME/version.env"

  TASK_SUBCOMMAND="update"

  run task_global <<< "\n"

  assert_output --partial "Press enter"
  assert grep "#ABEXCDAFEGRADSF" "$TASK_MASTER_HOME/task-runner.sh"
  assert [ -f "$TASK_MASTER_HOME/lib/updated" ]
}

@test 'Updates release to specified release' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> "$TASK_MASTER_HOME/version.env"

  ARG_VERSION=0.1
  TASK_SUBCOMMAND="update"

  run task_global <<< "\n"

  assert_output --partial "Press enter"
  assert grep "#OLDVER1234" "$TASK_MASTER_HOME/task-runner.sh"
  assert [ -f "$TASK_MASTER_HOME/lib/downgraded" ]
}

@test 'Fails to update release to release when target version does not exist' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> "$TASK_MASTER_HOME/version.env"

  ARG_VERSION=6.6
  TASK_SUBCOMMAND="update"

  run task_global <<< "\n"

  assert_output --partial "Could not retrieve version"
  refute_output --partial "grep:"
  refute_output --partial "rm:"
}

@test 'Checks release to release when there are updates' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> "$TASK_MASTER_HOME/version.env"

  TASK_SUBCOMMAND="update"

  ARG_CHECK=T
  run task_global

  assert_output --partial "Updates are available"
  refute_output --partial "Press enter"
  refute grep "#ABEXCDAFEGRADSF" "$TASK_MASTER_HOME/task-runner.sh"
  refute [ -f "$TASK_MASTER_HOME/lib/updated" ]
}

@test 'Checks release to release when there are no updates' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=2.0" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases" >> "$TASK_MASTER_HOME/version.env"

  TASK_SUBCOMMAND="update"

  ARG_CHECK=T
  run task_global

  assert_output --partial "does not differ"
  refute_output --partial "Press enter"
  refute grep "#ABEXCDAFEGRADSF" "$TASK_MASTER_HOME/task-runner.sh"
  refute [ -f "$TASK_MASTER_HOME/lib/updated" ]
}

@test 'Updates release version to dev version' {
  source "$TASK_MASTER_HOME/lib/builtins/global.sh"

  echo "BTM_VERSION=1.0" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> "$TASK_MASTER_HOME/version.env"

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

  cp() {
    echo copying "$@"
  }

  run task_global <<< "\n"

  unset -f mv 
  unset -f cp 

  mods="$(find "$TASK_MASTER_HOME/modules/"* | tr '\n' ' ')"
  templs="$(find "$TASK_MASTER_HOME/templates/"* | tr '\n' ' ')"
  states="$(find "$TASK_MASTER_HOME/state/"* | tr '\n' ' ')"

  assert_output --partial "Press enter"
  assert_output --partial "git clone"
  assert_output --partial "moving $TASK_MASTER_HOME /tmp/task-master-1.0"
  assert_output --partial "moving $TASK_MASTER_HOME.new $TASK_MASTER_HOME"
  assert_output --partial "copying -r $mods$TASK_MASTER_HOME.new/modules"
  assert_output --partial "copying -r $templs$TASK_MASTER_HOME.new/templates"
  assert_output --partial "copying -r $states$TASK_MASTER_HOME.new/state"

}

@test 'Shows version information' {
  echo "BTM_VERSION=9.9" > "$TASK_MASTER_HOME/version.env"
  echo "BTM_ASSET_URL=file:///$TASK_MASTER_HOME/test/releases/" >> "$TASK_MASTER_HOME/version.env"

  TASK_SUBCOMMAND="version"

  run task_global

  assert_output --partial "9.9"
  assert_output --partial "file:///$TASK_MASTER_HOME/test/releases/"
}
