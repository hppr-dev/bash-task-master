#!/bin/bash

shellcheck $(find "$TASK_MASTER_HOME" -name '*.sh' -not -path "$TASK_MASTER_HOME/test/*")
