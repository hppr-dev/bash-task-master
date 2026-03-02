# Load built in tasks
source "$TASK_MASTER_HOME/lib/load-builtins.sh"

BUILTIN_TASKS_REG=$(declare -F 2>/dev/null | grep -e 'declare -fr task_' | sed 's/declare -fr task_//' | tr '\n' '|')
BUILTIN_TASKS_REG=${BUILTIN_TASKS_REG%?}

# Load module tasks
while IFS= read -r -d '' module
do
  source "$module"
done < <(find "$TASK_MASTER_HOME/modules/" -name "*-module.sh" -print0 2>/dev/null)

MODULE_TASKS_REG=""
readarray -t mod_task_names < <(declare -F 2>/dev/null | grep -e 'declare -fr task_' | sed 's/declare -fr task_//')
for t in "${mod_task_names[@]}"
do
  [[ "|${BUILTIN_TASKS_REG}|" != *"|${t}|"* ]] && MODULE_TASKS_REG="${MODULE_TASKS_REG}${t}|"
done
MODULE_TASKS_REG=${MODULE_TASKS_REG%?}
