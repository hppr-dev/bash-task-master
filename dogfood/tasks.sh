LOCAL_TASKS_UUID=dogfood
task_edit() {
  vim /home/swalker/.task-master/dogfood/tasks.sh
}

# Task to update the lib-functions.sh with the current global functions
task_gen-lib-func() {
    cd $TASK_MASTER_HOME
    grep -h -I -R lib -e ".*()" | sed 's/\(.*\)().*/readonly -f \1/' | grep -v '\$' > lib-functions.sh
    echo >> lib-functions.sh
    grep -h -I global.sh -e ".*()" | sed 's/\(.*\)().*/readonly -f \1/' | grep -v '\$' | grep -v 'task_edit' >> lib-functions.sh
}
task_tester() {
  if [[ $TASK_SUBCOMMAND == "set" ]]
  then
    hold_var "PS1"
    export_var "PS1" "(tester)"
  elif [[ $TASK_SUBCOMMAND == "unset" ]]
  then
    release_var "PS1"
  fi

  #Recorded subcommand
  if [[ $TASK_SUBCOMMAND == "poop" ]]
  then
    task global debug -c record
  fi
}

task_env() {
  #Recorded subcommand
  if [[ $TASK_SUBCOMMAND == "diff" ]]
  then
    cd /home/swalker/.task-master/dogfood
    env > env.before
    set > set.before
    $ARG_PROC
    env > env.after
    set > set.after
    echo "Environment Additions"
    diff env.before env.after | grep -e '>' 
    echo "Set Additions"
    diff set.before set.after | grep -e '>'
    rm env.{before,after} set.{before,after}
  fi
}
arguments_env() {
  DIFF_REQUIREMENTS="proc:p:str"
  SUBCOMMANDS="diff"
}
