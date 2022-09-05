setup_file() {
  REPO_DIR=$TASK_MASTER_HOME/test/modtest
  mkdir $REPO_DIR

  export TASK_REPOS=file:///$REPO_DIR/inventory

  cat > $REPO_DIR/inventory <<EOF
MODULE_DIR=mods

module-test=test-module.sh.disabled
EOF

  mkdir $REPO_DIR/mods
  cat > $REPO_DIR/mods/test-module.sh.disabled <<EOF
task_test() {
  echo hello from test
}
EOF

  # Back up existing modules
  mv $TASK_MASTER_HOME/modules{,.bk}
  mkdir $TASK_MASTER_HOME/modules
}

teardown_file() {
  rm -r $REPO_DIR
  rm -r $TASK_MASTER_HOME/modules
  mv $TASK_MASTER_HOME/modules{.bk,}
}

setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

teardown() {
  rm -f $TASK_MASTER_HOME/modules/*
}

@test 'Defines arguments' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh

  arguments_module

  assert [ ! -z "$SUBCOMMANDS" ]
  assert [ ! -z "$MODULE_DESCRIPTION" ]
  assert [ ! -z "$ENABLE_DESCRIPTION" ]
  assert [ ! -z "$ENABLE_REQUIREMENTS" ]
  assert [ ! -z "$DISABLE_DESCRIPTION" ]
  assert [ ! -z "$DISABLE_REQUIREMENTS" ]
  assert [ ! -z "$LIST_DESCRIPTION" ]
  assert [ ! -z "$LIST_OPTIONS" ]
}

@test 'Enables module that exists in the modules directory' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh
  touch $TASK_MASTER_HOME/modules/local-module.sh.disabled

  ARG_ID="local"
  TASK_SUBCOMMAND="enable"

  run task_module
  assert [ -f "$TASK_MASTER_HOME/modules/local-module.sh" ]
  assert_success
}

@test 'Downloads remote module and enables it' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh

  ARG_ID="test"
  TASK_SUBCOMMAND="enable"

  run task_module
  assert [ -f "$TASK_MASTER_HOME/modules/test-module.sh" ]
  assert_success
}

@test 'Fails to find a non importable module' { 
  source $TASK_MASTER_HOME/lib/builtins/module.sh

  ARG_ID="missing"
  TASK_SUBCOMMAND="enable"

  run task_module
  assert_failure
}

@test 'Disables module' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh

  touch $TASK_MASTER_HOME/modules/local-module.sh

  ARG_ID="local"
  TASK_SUBCOMMAND="disable"

  run task_module
  assert [ -f "$TASK_MASTER_HOME/modules/local-module.sh.disabled" ]
  assert_success
}

@test 'Fails to disable module that isnt enabled' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh

  ARG_ID="missing"
  TASK_SUBCOMMAND="disable"

  run task_module
  assert_failure
}

@test 'Lists enabled modules by default' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh
  touch $TASK_MASTER_HOME/modules/one-module.sh
  touch $TASK_MASTER_HOME/modules/other-module.sh
  touch $TASK_MASTER_HOME/modules/not-me-module.sh.disabled
  touch $TASK_MASTER_HOME/modules/or-me-module.sh.disabled

  ARG_ENABLED=T
  TASK_SUBCOMMAND="list"

  run task_module
  assert_output --partial "one"
  assert_output --partial "other"
  refute_output --partial "not-me"
  refute_output --partial "or-me"
}

@test 'Lists disabled modules' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh
  touch $TASK_MASTER_HOME/modules/one-module.sh
  touch $TASK_MASTER_HOME/modules/other-module.sh
  touch $TASK_MASTER_HOME/modules/not-me-module.sh.disabled
  touch $TASK_MASTER_HOME/modules/or-me-module.sh.disabled

  ARG_DISABLED=T
  TASK_SUBCOMMAND="list"

  run task_module
  refute_output --partial "one"
  refute_output --partial "other"
  assert_output --partial "not-me"
  assert_output --partial "or-me"
}

@test 'Lists remote modules' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh

  ARG_REMOTE=T
  TASK_SUBCOMMAND="list"

  run task_module
  assert_output --partial "test"
}

@test 'Lists all modules' {
  source $TASK_MASTER_HOME/lib/builtins/module.sh
  touch $TASK_MASTER_HOME/modules/one-module.sh
  touch $TASK_MASTER_HOME/modules/other-module.sh
  touch $TASK_MASTER_HOME/modules/not-me-module.sh.disabled
  touch $TASK_MASTER_HOME/modules/or-me-module.sh.disabled

  ARG_ALL=T
  TASK_SUBCOMMAND="list"

  run task_module
  assert_output --partial "one"
  assert_output --partial "other"
  assert_output --partial "not-me"
  assert_output --partial "or-me"
}

