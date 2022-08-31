#!/bin/bash

cd $(dirname $0)

run/bats/bin/bats lib/*.bats lib/builtins/*.bats lib/drivers/*.bats
