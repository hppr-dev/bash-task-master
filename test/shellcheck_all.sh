#!/bin/bash

shellcheck \
  "$TASK_MASTER_HOME/task-runner.sh" \
  "$TASK_MASTER_HOME/install-latest.sh" \
  $(find "$TASK_MASTER_HOME" -name '*.sh' -path "$TASK_MASTER_HOME/lib/*")
