#########################################################################################################
# Main Task Runner:
#   Supplies the following environment variables to tasks:
#      - TASKS_DIR = directory of the local tasks.sh file
#      - RUNNING_DIR = directory that the task is being run from
#      - TASK_COMMAND = command that the task is running i.e 'record' in 'task record start'
#      - TASK_SUBCOMMAND = sub command of the running task i.e 'start' in 'task record start'
#      - TASK_NAME = method name of the parent task i.e. 'task_record' for 'task record stop'
#    
#
#   Arguments to commands and subcommands are supplied as long arguments ONLY
#   Arguments are supplied as environment variables to child tasks
#   for instance, running 'task record start --name hello --force' will set ARG_FORCE=1 and ARG_NAME=hello
#
##########################################################################################################
task(){
  # Save directory that you are running it from
  RUNNING_DIR=`pwd`
  pushd $RUNNING_DIR > /dev/null

  GLOBAL_TASKS_FILE=$TASK_MASTER_HOME/global.sh
  TASKS_DIR=$RUNNING_DIR
  TASKS_FILE=$TASKS_DIR/tasks.sh


  # Find tasks.sh file
  while [[ ! -f $TASKS_FILE ]] && [[ "$TASKS_DIR" != "$HOME" ]]
  do 
    cd ..
    TASKS_DIR=`pwd`
    TASKS_FILE=$TASKS_DIR/tasks.sh
  done

  if [[ "$TASKS_DIR" == "$HOME" ]]
  then
    echo Could not file local task file, only loading global
    TASKS_FILE=$GLOBAL_TASKS_FILE
  fi

  # Load global and local tasks
  . $GLOBAL_TASKS_FILE
  . $TASKS_FILE

  #Parse arguments
  TASK_COMMAND=$1
  shift
  TASK_SUBCOMMAND=$1
  # All arguments after the subcommand will be parsed into environment variables
  # Only long arguments can be used
  while [[ $# > 1 ]]
  do
    shift
    ARGUMENT=$1
    if [[ $ARGUMENT =~ ^--[a-z]*$ ]]
    then
      TRANSLATE_ARG=${ARGUMENT//-}
      TRANSLATE_ARG=${TRANSLATE_ARG^^}
      if [[ -z "$2" ]] || [[ "$2" =~ ^--[a-z]$ ]]
      then
        eval "ARG_$TRANSLATE_ARG='1'"
      else
        shift
        eval "ARG_$TRANSLATE_ARG=$1"
      fi
      unset TRANSLATE_ARG
    else
      echo "Only long arguments are allowed"
      echo "Try using something like '--arg value' that will be translated to \$ARG=value in the task script."
      exit 1
    fi
  done

  #Run requested task
  TASK_NAME=task_$TASK_COMMAND
  type $TASK_NAME &> /dev/null
  if [ "$?" == "0" ]
  then
    echo "Running $TASK_COMMAND task..."
    shift
    eval "$TASK_NAME"
  else
    echo "Can't find $TASK_COMMAND task in the global or local tasks file"
    echo "check $TASKS_FILE for a definition of $TASK_NAME"
  fi

  # unset task functions
  eval $(grep $TASKS_FILE -e "task_.*()" | sed 's/\(task_.*\)() *{*/unset \1;/')
  eval $(grep $GLOBAL_TASKS_FILE -e "task_.*()" | sed 's/\(task_.*\)() *{*/unset \1;/')

  #Return to working directory
  popd > /dev/null
}
