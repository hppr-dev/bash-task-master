setup() {
  load "$TASK_MASTER_HOME/test/run/bats-support/load"
  load "$TASK_MASTER_HOME/test/run/bats-assert/load"
}

@test 'Exports a simple script with no arguments' {
  source $TASK_MASTER_HOME/lib/builtins/export.sh
}

@test 'Exports a script with requirements' {
  source $TASK_MASTER_HOME/lib/builtins/export.sh
}

@test 'Exports a script with options' {
  source $TASK_MASTER_HOME/lib/builtins/export.sh
}

@test 'Exports a script with descriptions' {
  source $TASK_MASTER_HOME/lib/builtins/export.sh
}
