setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  cp $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh{,.bk}

  export local_repo_dir=$TASK_MASTER_HOME/test/repo.driver
  mkdir $local_repo_dir

  export TASK_REPOS=file:///$local_repo_dir/inventory
  export driver_file=$local_repo_dir/drivers/yaml-driver.sh

  cat > $local_repo_dir/inventory <<EOF
DRIVER_DIR = drivers

driver-yaml = yaml-driver.sh
EOF

  mkdir $local_repo_dir/drivers
  cat > $driver_file <<EOF
# tasks_file_name = tasks.yaml
# extra_file = yaml/executor.py
# extra_file = yaml/validator.py

echo script goes here

EOF

  mkdir $local_repo_dir/drivers/yaml
  echo "#hello" > $local_repo_dir/drivers/yaml/executor.py
  echo "#world" > $local_repo_dir/drivers/yaml/validator.py
}

teardown() {
  echo "OUTPUT:"
  echo "$output"
  rm -rf $local_repo_dir $TASK_MASTER_HOME/lib/drivers/{yaml,yaml_driver.sh}
  mv $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh{.bk,}
}

@test 'Defines descriptions and requirements' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  arguments_driver
  assert [ -n "$DRIVER_DESCRIPTION" ]
  assert [ -n "$ENABLE_DESCRIPTION" ]
  assert [ -n "$ENABLE_REQUIREMENTS" ]
  assert [ -n "$DISABLE_DESCRIPTION" ]
  assert [ -n "$DISABLE_REQUIREMENTS" ]
  assert [ -n "$LIST_DESCRIPTION" ]
}

@test 'Protects the bash driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  ARG_NAME=bash
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_failure
}

@test 'Enables local driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  echo "#TASK_DRIVER_DICT[local]=local_driver.sh" >> $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  echo "#TASK_FILE_NAME_DICT[tasks.local]=local" >> $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh

  ARG_NAME=local
  TASK_SUBCOMMAND=enable

  run task_driver
  run cat $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  assert_output --partial "TASK_DRIVER_DICT[local]=local_driver.sh"
  assert_output --partial "TASK_FILE_NAME_DICT[tasks.local]=local"
  refute_output --partial "#TASK_DRIVER_DICT"
}

@test 'Downloads and enables remote driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  ARG_NAME=yaml
  TASK_SUBCOMMAND=enable

  run task_driver
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml_driver.sh ]
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml/executor.py ]
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml/validator.py ]

  run cat $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  assert_output --partial "TASK_DRIVER_DICT[yaml]=yaml_driver.sh"
  assert_output --partial "TASK_FILE_NAME_DICT[tasks.yaml]=yaml"
}

@test 'Fails to enable missing driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  ARG_NAME=miss
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_failure
}

@test 'Fails when inventory points to the wrong file' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh
  awk '/^driver-yaml = yaml-driver.sh$/ { print "driver-yaml = missing-driver.sh" }' $local_repo_dir/inventory > $local_repo_dir/inventory.tmp
  mv $local_repo_dir/inventory{.tmp,}

  ARG_NAME=yaml
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_failure
  assert_output --partial "missing-driver.sh"
}

@test 'Fails when remote extra_file doesnt exist' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh
  echo "# extra_file = yaml/noexist.py" > $driver_file

  ARG_NAME=yaml
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_failure
  assert_output --partial "yaml/noexist.py"
}

@test 'Fails when remote setup script fails to run' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh
  echo "# setup = yaml/setup.sh" > $driver_file
  echo "exit 1" > $local_repo_dir/drivers/yaml/setup.sh

  ARG_NAME=yaml
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_failure
  assert_output --partial "setup"
}

@test 'Fails when remote dependency is not met' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh
  echo "# dependency = thisissomethingthatisntexecutableinyourpath" > $driver_file

  ARG_NAME=yaml
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_failure
  assert_output --partial "thisissomethingthatisntexecutableinyourpath"
}

@test 'Downloads and places template' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh
  echo "# template = yaml/templatefile " > $driver_file
  echo "heyoo this is templ" > $local_repo_dir/drivers/yaml/templatefile

  ARG_NAME=yaml
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_success
  assert [ -f $TASK_MASTER_HOME/templates/yaml.template ]

  run diff $TASK_MASTER_HOME/templates/yaml.template $local_repo_dir/drivers/yaml/templatefile
  # Remove here in case of failure
  rm $TASK_MASTER_HOME/templates/yaml.template
  assert_output ""
}

@test 'Continues on bad template' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh
  echo "# template = missingtemplatefile" > $driver_file

  ARG_NAME=yaml
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_success
  assert_output --partial "missingtemplatefile"
  assert [ ! -f "$TASK_MASTER_HOME/templates/yaml.template" ]
}

@test 'Disables driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  echo "TASK_DRIVER_DICT[xml]=xml_driver.sh" >> $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  echo "TASK_FILE_NAME_DICT[tasks.xml]=xml" >> $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh

  ARG_NAME=xml
  TASK_SUBCOMMAND=disable

  run task_driver
  run cat $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  assert_output --partial "#TASK_DRIVER_DICT[xml]=xml_driver.sh"
  assert_output --partial "#TASK_FILE_NAME_DICT[tasks.xml]=xml"
}

@test 'Fails to disable missing driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  ARG_NAME=miss
  TASK_SUBCOMMAND=disable

  run task_driver
  assert_failure
}

@test 'Lists drivers' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  declare -A TASK_DRIVER_DICT
  declare -A TASK_FILE_NAME_DICT

  TASK_DRIVER_DICT[bash]=bash_driver.sh
  TASK_FILE_NAME_DICT[tasks.sh]=bash
  TASK_DRIVER_DICT[fake]=fake_driver.sh
  TASK_FILE_NAME_DICT[tasks.fake]=fake 

  TASK_SUBCOMMAND=list

  run task_driver
  assert_output --partial "bash"
  assert_output --partial "fake"
}
