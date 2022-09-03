#!/bin/bash

cd "$(dirname $0)"

echo $TASK_MASTER_HOME

kcov --include-path=$TASK_MASTER_HOME --include-pattern=.sh --exclude-path=$TASK_MASTER_HOME/test $(pwd)/kcov $(pwd)/test_all.sh
