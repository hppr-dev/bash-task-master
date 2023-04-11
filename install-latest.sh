#!/bin/bash

RELEASE_URL=https://github.com/hppr-dev/bash-task-master/releases/latest/download

if ! command -v awk &> /dev/null
then
  echo "awk not installed"
  echo "Install awk and try again"
  exit 1
fi

if ! command -v sed &> /dev/null
then
  echo "sed not installed"
  echo "Install sed and try again"
  exit 1
fi

if [[ -z "$HOME" ]]
then
  echo "HOME environment variable not set, cannot continue"
  exit 1
fi

if [[ ! -f "$HOME/.bashrc" ]]
then
  echo "You must have a $HOME/.bashrc file to install task master"
  exit 1
fi

if [[ -n "$TASK_MASTER_HOME" ]] || [[ -d "$HOME/.task-master" ]] ||
  grep -q "$HOME/.bashrc" -e "[ -s \"\$TASK_MASTER_HOME/task-runner.sh\" ] && . \"\$TASK_MASTER_HOME/task-runner.sh\"" ||
  grep -q "$HOME/.bashrc" -e "export TASK_MASTER_HOME=$HOME/.task-master"
then
  echo "Task Master already installed"
  exit 1
fi

cp ~/.bashrc{,.bk}
mkdir -p "$HOME/.task-master/"{modules,state,templates}

revert() {
  mv ~/.bashrc{.bk,} &> /dev/null
  rm -r .task-master &> /dev/null
}

trap revert EXIT

set -e

cat >> ~/.bashrc <<EOF
alias t=task
export TASK_MASTER_HOME=$HOME/.task-master
[ -s "\$TASK_MASTER_HOME/task-runner.sh" ] && . "\$TASK_MASTER_HOME/task-runner.sh"
EOF

curl -Ls "$RELEASE_URL/btm.tar.gz" | tar -xz -C "$HOME/.task-master"
curl -Ls "$RELEASE_URL/version.env" --output "$HOME/.task-master/version.env"

mv "$HOME/.task-master/dist/"* "$HOME/.task-master"

rmdir "$HOME/.task-master/dist"
rm ~/.bashrc.bk

trap - EXIT

echo "Task Master successfully installed"
echo "You may have to start a new bash session to apply changes"
echo "Run 'task list' to see available tasks"
