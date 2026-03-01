# Load built in tasks
source "$TASK_MASTER_HOME/lib/load-builtins.sh"

BUILTIN_TASKS_REG=$(declare -F 2>/dev/null | grep -e 'declare -fr task_' | sed 's/declare -fr task_//' | tr '\n' '|')
BUILTIN_TASKS_REG=${BUILTIN_TASKS_REG%?}

# Load module tasks
enabled=$(find "$TASK_MASTER_HOME/modules/" -name "*-module.sh" 2>/dev/null)
if [[ -n "$enabled" ]]
then
  for module in $enabled
  do
    source "$module"
  done
fi
unset enabled
unset module

MODULE_TASKS_REG=""
for t in $(declare -F 2>/dev/null | grep -e 'declare -fr task_' | sed 's/declare -fr task_//')
do
  [[ "|${BUILTIN_TASKS_REG}|" != *"|${t}|"* ]] && MODULE_TASKS_REG="${MODULE_TASKS_REG}${t}|"
done
MODULE_TASKS_REG=${MODULE_TASKS_REG%?}
