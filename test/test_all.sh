#!/bin/bash

cd $(dirname $0)

run/bats/bin/bats task-runner.bats load-global.bats lib/*.bats lib/builtins/*.bats lib/drivers/*.bats
