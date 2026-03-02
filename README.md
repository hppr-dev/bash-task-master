
[![bash-task-master](https://circleci.com/gh/hppr-dev/bash-task-master.svg?style=shield)](https://circleci.com/gh/hppr-dev/bash-task-master)
[![codecov](https://codecov.io/gh/hppr-dev/bash-task-master/branch/master/graph/badge.svg?token=2DJJIA4TBL)](https://codecov.io/gh/hppr-dev/bash-task-master)

Bash Task Master
===================
Bash Task Master enhances bash by providing a way to create context for directories within project.

Features:

  - Centralized -- Tasks can be run in any folder under your home directory without adding them to your path

  - Parsed and Validated Input -- Easily access named command line arguments

  - Scoped -- Different tasks are loaded depending on the current working directory

  - Isolated -- Environment variables aren't affected (unless you want them to be)


Bash Task Master was designed with flexibility and expandibility in mind.

Read the full documentation [here](https://bash-task-master.readthedocs.io).

The [VSCode/Cursor extension](vscode-extension) lives in the `vscode-extension/` submodule, and the [BTM MCP server](btm-mcp) in the `btm-mcp/` submodule; use `git clone --recurse-submodules` or `git submodule update --init --recursive` to include them.

Dependencies
============================

 - GNU Awk 4.1.3
 - GNU sed 4.2.2
 - GNU bash 4.3.42

Bash Task Master was tested using these versions. It is likely that it works on other versions as well.

Development
============================

For contributors: clone with `git clone --recurse-submodules` so docs and submodules are present.

- **Lint:** Set `TASK_MASTER_HOME` to the repo root, source `task-runner.sh`, then run `test/shellcheck_all.sh`.
- **Tests:** Same env; run `test/test_all.sh` (requires [Bats](https://github.com/bats-core/bats-core); use the vendored copy under `test/run/bats`).
- **Coverage:** Run `test/coverage.sh` (requires kcov); results under `test/kcov`.

Core scripts do not use `set -e`/`set -u`; errors are handled explicitly with `|| return`/`|| exit` and conditionals.
