# Load built in tasks
source $TASK_MASTER_HOME/lib/load-builtins.sh

# Load module tasks
for module in $TASK_MASTER_HOME/modules/*-module.sh
do
  source $module
done
