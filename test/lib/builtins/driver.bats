setup_file() {
  export local_repo_dir=$TASK_MASTER_HOME/test/repo.driver
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
  echo "#hello" > $local_repo_dir/drivers/yaml/executor.py
  echo "#world" > $local_repo_dir/drivers/yaml/validator.py
}

teardown_file() {
  rm -rf $local_repo_dir $TASK_MASTER_HOME/lib/drivers/{yaml,yaml_driver.sh}
}

setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  cp $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh{,.bk}
}

teardown() {
  mv $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh{.bk,}
}

@test 'Should protect bash driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  ARG_ID=bash
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_failure
}

@test 'Should enable local driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  echo "#TASK_DRIVER_DICT[local]=local_driver.sh" >> $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  echo "#TASK_FILE_NAME_DICT[tasks.local]=local" >> $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh

  ARG_ID=local
  TASK_SUBCOMMAND=enable

  run task_driver
  run cat $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  assert_output --partial "TASK_DRIVER_DICT[local]=local_driver.sh"
  assert_output --partial "TASK_FILE_NAME_DICT[tasks.local]=local"
  refute_output --partial "#TASK_DRIVER_DICT"
}

@test 'Should download and enable remote driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  ARG_ID=yaml
  TASK_SUBCOMMAND=enable

  run task_driver
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml_driver.sh ]
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml/executor.py ]
  assert [ -f $TASK_MASTER_HOME/lib/drivers/yaml/validator.py ]

  run cat $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  assert_output --partial "TASK_DRIVER_DICT[yaml]=yaml_driver.sh"
  assert_output --partial "TASK_FILE_NAME_DICT[tasks.yaml]=yaml"
}

@test 'Should fail to enable missing driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  ARG_ID=miss
  TASK_SUBCOMMAND=enable

  run task_driver
  assert_failure
}


@test 'Should disable driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh


  echo "TASK_DRIVER_DICT[xml]=xml_driver.sh" >> $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  echo "TASK_FILE_NAME_DICT[tasks.xml]=xml" >> $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh

  ARG_ID=xml
  TASK_SUBCOMMAND=disable

  run task_driver
  run cat $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
  assert_output --partial "#TASK_DRIVER_DICT[xml]=xml_driver.sh"
  assert_output --partial "#TASK_FILE_NAME_DICT[tasks.xml]=xml"
}

@test 'Should fail to disable missing driver' {
  source $TASK_MASTER_HOME/lib/builtins/driver.sh

  ARG_ID=miss
  TASK_SUBCOMMAND=disable

  run task_driver
  assert_failure
}

@test 'Should list drivers' {
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
