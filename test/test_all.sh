#!/bin/bash

if [[ -z "$TASK_MASTER_HOME" ]]
then
  echo TASK_MASTER_HOME not set.
  echo Install and retry
  exit 1
fi

cd $(dirname $0)

run/bats/bin/bats task-runner.bats load-global.bats lib/*.bats lib/builtins/*.bats lib/drivers/*.bats
