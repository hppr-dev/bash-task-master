# Load built in tasks
source "$TASK_MASTER_HOME/lib/load-builtins.sh"

# Load module tasks
enabled=$(find "$TASK_MASTER_HOME/modules/" -name "*-module.sh")
if [[ -n "$enabled" ]]
then
  for module in $enabled
  do
    source "$module"
  done
fi
