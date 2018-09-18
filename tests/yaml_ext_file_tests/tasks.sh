LOCAL_TASKS_UUID=l10
ARG_FORMAT=yaml
ARGUMENTS="task-args.yaml"

task_test(){
  echo "$ARG_ONE is string"
  echo "$ARG_TWO is a boolean flag"
  echo "$ARG_THREE is a integer"
}
