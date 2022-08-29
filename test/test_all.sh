#!/bin/bash

cd $(dirname $0)

run/bats/bin/bats builtins/*.bats
