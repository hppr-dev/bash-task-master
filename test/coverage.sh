#!/bin/bash

cd "$(dirname $0)"

kcov --include-path=$TASK_MASTER_HOME --exclude-path=$TASK_MASTER_HOME/test $(pwd)/kcov $(pwd)/test_all.sh
