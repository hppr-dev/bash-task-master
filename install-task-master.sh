#!/bin/bash
GIT_DIR=$(dirname "$(readlink -f "$0")")
ALREADY_INSTALLED="Task Master already installed"

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

if [[ -n "$TASK_MASTER_HOME" ]]
then
  echo "$ALREADY_INSTALLED"
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

if [[ -d "$HOME/.task-master" ]]
then
  echo "Task master home $HOME/.task-master already exists. Either task master is already installed or there is a dependency conflict"
  exit 1
fi


if grep -q "$HOME/.bashrc" -e "export TASK_MASTER_HOME=$HOME/.task-master"
then
  echo "$ALREADY_INSTALLED"
  exit 1
fi


if grep -q "$HOME/.bashrc" -e "[ -s \"\$TASK_MASTER_HOME/task-runner.sh\" ] && . \"\$TASK_MASTER_HOME/task-runner.sh\""
then
  echo "$ALREADY_INSTALLED"
  exit 1
fi

cat >> ~/.bashrc <<EOF
alias t=task
export TASK_MASTER_HOME=$HOME/.task-master
[ -s \"\$TASK_MASTER_HOME/task-runner.sh\" ] && . \"\$TASK_MASTER_HOME/task-runner.sh\"
EOF

cd ..
mv "$GIT_DIR" "$HOME/.task-master"

echo "Task Master successfully installed"
echo "You may have to start a new bash session to apply changes"
echo "Run 'task list' to see available tasks"
