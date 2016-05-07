#!/bin/bash
ALREADY_INSTALLED="Task Master already installed"
if [[ ! -z "$TASK_MASTER_HOME" ]]
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


grep $HOME/.bashrc -e "export TASK_MASTER_HOME=$HOME/.task-master" > /dev/null
if [[ "$?" == "0" ]]
then
  echo "$ALREADY_INSTALLED"
  exit 1
fi

grep $HOME/.bashrc -e "[ -s \"\$TASK_MASTER_HOME/task-runner.sh\" ] && . \"\$TASK_MASTER_HOME/task-runner.sh\"" > /dev/null
if [[ "$?" == "0" ]]
then
  echo "$ALREADY_INSTALLED"
  exit 1
fi

echo >> ~/.bashrc
echo "export TASK_MASTER_HOME=$HOME/.task-master" >> ~/.bashrc
echo "[ -s \"\$TASK_MASTER_HOME/task-runner.sh\" ] && . \"\$TASK_MASTER_HOME/task-runner.sh\"" >> ~/.bashrc

echo "Task Master successfully installed"
echo "You may have to start a new bash session to apply changes"
echo "Run 'task list' to see available tasks"
