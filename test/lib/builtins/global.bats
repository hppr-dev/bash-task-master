setup_file() {

  export local_repo_dir=$TASK_MASTER_HOME/test/repo.global
  mkdir $local_repo_dir

  export TASK_REPOS=file:///$local_repo_dir/inventory

  cat > $local_repo_dir/inventory <<EOF
DRIVER_DIR = drivers

driver-yaml = yaml-driver.sh
EOF

  mkdir $local_repo_dir/drivers
  cat > $local_repo_dir/drivers/yaml-driver.sh <<EOF
# tasks_file_name = tasks.yaml
# extra_file = yaml/executor.py
# extra_file = yaml/validator.py

echo script goes here

EOF

  mkdir $local_repo_dir/drivers/yaml
  touch $local_repo_dir/drivers/{executor,validator}.py
}

teardown_file() {
  rm -rf $local_repo_dir $TASK_MASTER_HOME/lib/drivers/{yaml,yaml_driver.sh}
}

setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  export LOCATIONS_FILE=$TASK_MASTER_HOME/test/locations.global
  echo "UUID_tmhome=$TASK_MASTER" > "$LOCATIONS_FILE"

  export STATE_DIR=$TASK_MASTER_HOME/state

  export COMMAND_STATE_FILE=$TASK_MASTER_HOME/state/command.vars
  echo hello=world > $COMMAND_STATE_FILE

  export OTHER_STATE_FILE=$TASK_MASTER_HOME/state/other.vars
  echo foo=bar > $OTHER_STATE_FILE
  cp $TASK_MASTER_HOME/lib/drivers/driver_defs.sh{,.bk}
}

teardown() {
  rm $LOCATIONS_FILE
  rm $COMMAND_STATE_FILE
  rm $OTHER_STATE_FILE
  mv $TASK_MASTER_HOME/lib/drivers/driver_defs.sh{.bk,}
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

  echo "UUID_hello=$TASK_MASTER_HOME/test/doesnotexist" >> $LOCATIONS_FILE

  TASK_SUBCOMMAND="clean"

  task_global

  run cat $LOCATIONS_FILE

  refute_output --partial "UUID_hello=$TASK_MASTER_HOME/test/doesnotexist"
}

@test 'Clean removes state files that refer to locations that no longer exist' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  mkdir $TASK_MASTER_HOME/state/doesnotexist
  echo some=var > $TASK_MASTER_HOME/state/doesnotexist/command.vars

  TASK_SUBCOMMAND="clean"

  task_global

  assert [ ! -d "$TASK_MASTER_HOME/state/doesnotexist" ]
}

@test 'Clean removes empty state files' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  touch $TASK_MASTER_HOME/state/empty.vars

  TASK_SUBCOMMAND="clean"

  task_global

  assert [ ! -f "$TASK_MASTER_HOME/state/empty.vars" ]
}

@test 'Should define descriptions and arguments' {
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
  assert [ ! -z "$DRIVER_DESCRIPTION" ]
  assert [ ! -z "$DRIVER_OPTIONS" ]
}

@test 'Should protect bash driver' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_ENABLE=bash
  TASK_SUBCOMMAND=driver

  run task_global
  assert_failure
}

@test 'Should enable local driver' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  add_driver_def "tasks.local" "local" "#"

  ARG_ENABLE=local
  TASK_SUBCOMMAND=driver

  run task_global
  run cat $TASK_MASTER_HOME/lib/drivers/driver_defs.sh
  assert_output --partial "TASK_DRIVERS[tasks.local]=local_driver.sh"
  refute_output --partial "#"
}

@test 'Should download and enable remote driver' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_ENABLE=yaml
  TASK_SUBCOMMAND=driver

  run task_global
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml_driver.sh ]
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml/executor.py ]
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml/validator.py ]

  run cat $TASK_MASTER_HOME/lib/drivers/driver_defs.sh
  assert_output --partial "TASK_DRIVERS[tasks.yaml]=yaml_driver.sh"
}

@test 'Should fail to enable missing driver' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_ENABLE=miss
  TASK_SUBCOMMAND=driver

  run task_global
  assert_failure
}


@test 'Should disable driver' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  add_driver_def "tasks.xml" "xml"

  ARG_DISABLE=xml
  TASK_SUBCOMMAND=driver

  run task_global
  run cat $TASK_MASTER_HOME/lib/drivers/driver_defs.sh
  assert_output --partial "#TASK_DRIVERS[tasks.xml]=xml_driver.sh"
}

@test 'Should fail to disable missing driver' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  ARG_DISABLE=miss
  TASK_SUBCOMMAND=driver

  run task_global
  assert_failure
}

@test 'Should list drivers' {
  source $TASK_MASTER_HOME/lib/builtins/global.sh

  add_driver_def "tasks.fake" "fake"

  TASK_SUBCOMMAND=driver

  run task_global
  assert_output --partial "bash"
  assert_output --partial "fake"
}

add_driver_def() {
  echo "${3}TASK_DRIVERS[$1]=${2}_driver.sh" >> $TASK_MASTER_HOME/lib/drivers/driver_defs.sh
}

persist_var() {
  echo set $1=$2
}

remove_var() {
  echo unset $1
}
