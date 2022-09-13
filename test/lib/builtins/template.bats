setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"

  echo "I am template" > $TASK_MASTER_HOME/templates/template_test.template
}

teardown() {
  rm -f $TASK_MASTER_HOME/templates/template_test.template
}

@test 'Defines description and options' {
  source $TASK_MASTER_HOME/lib/builtins/template.sh

  arguments_template

  assert [ -n "$TEMPLATE_DESCRIPTION" ]
  assert [ -n "$SUBCOMMANDS" ]

  assert [ -n "$LIST_DESCRIPTION" ]

  assert [ -n "$EDIT_DESCRIPTION" ]
  assert [ -n "$EDIT_REQUIREMENTS" ]

  assert [ -n "$RM_DESCRIPTION" ]
  assert [ -n "$RM_REQUIREMENTS" ]
}

@test 'Edits template by name with the default editor' {
  source $TASK_MASTER_HOME/lib/builtins/template.sh
  DEFAULT_EDITOR=cat

  TASK_SUBCOMMAND="edit"
  ARG_NAME=template_test

  run task_template
  assert_output "I am template"
}

@test 'Fails to remove template that doesnt exist' {
  source $TASK_MASTER_HOME/lib/builtins/template.sh

  TASK_SUBCOMMAND="rm"
  ARG_NAME=nonexist

  run task_template
  assert_failure
}

@test 'Removes template by name' {
  source $TASK_MASTER_HOME/lib/builtins/template.sh

  TASK_SUBCOMMAND="rm"
  ARG_NAME=template_test

  run task_template
  run ls $TASK_MASTER_HOME/templates
  refute_output "template_test"
}

@test 'Lists templates' {
  source $TASK_MASTER_HOME/lib/builtins/template.sh

  TASK_SUBCOMMAND="list"

  run task_template
  assert_output --partial "bash"
  assert_output --partial "template_test"
}
