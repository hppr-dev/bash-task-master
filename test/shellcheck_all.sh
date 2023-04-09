#!/bin/bash

shellcheck $(find "$TASK_MASTER_HOME" -name '*.sh' -path "$TASK_MASTER_HOME/lib/*")
