
spawn_help() {
  HELP_STRING="usage: task spawn (start|stop|kill|stop|list|output|clean)

  To start a background process run:

        task spawn start --proc 'my process' [--out outfile]

  To stop a background proccess run:

        task spawn stop --num 1

  To list the numbered processes run:

        task spawn list

  To show the output of the backgrounded process run:

        task spawn output --num 2 [--follow]

  To kill and clean all spawned processes run:

        task spawn clean
  "

  echo "HELP_STRING"
}

spawn_start() {
  if [[ -z "$ARG_PROC" ]]
  then
    echo "No --proc argument supplied can't spawn"
    return
  fi
  persist_var NUM_SPAWNED $(expr $NUM_SPAWNED + 1)
  if [[ -z "$ARG_OUT" ]]
  then
    ARG_OUT=$RUNNING_DIR/.spawn$NUM_SPAWNED.out
    echo "NO --out argument supplied defaulting to $ARG_OUT"
  fi
  nohup $ARG_PROC &> $ARG_OUT &
  persist_var "SPAWNED_PROC[$NUM_SPAWNED]" "$!"
  persist_var "SPAWNED_PROC_NAME[$NUM_SPAWNED]" "\"$ARG_PROC\""
  persist_var "SPAWNED_PROC_OUT[$NUM_SPAWNED]" "\"$ARG_OUT\""
}

spawn_stop() {
  if [[ -z "$ARG_NUM" ]]
  then
    echo "No --num argument supplied"
    echo "Use 'task spawn list' to find a number to stop"
    return
  fi
  echo "Killing ${SPAWNED_PROC[$ARG_NUM]}..."
  kill ${SPAWNED_PROC[$ARG_NUM]}
  remove_var "SPAWNED_PROC[$ARG_NUM]"
  remove_var "SPAWNED_PROC_NAME[$ARG_NUM]"
  remove_var "SPAWNED_PROC_OUT[$NUM_SPAWNED]"
  persist_var NUM_SPAWNED $(expr $NUM_SPAWNED - 1)
  #spawn_reindex
}

spawn_list() {
  echo "Listing spawned processes:"
  for i in $(seq 1 $NUM_SPAWNED)
  do
    echo "   $i : ${SPAWNED_PROC_NAME[i]}"
  done
}

spawn_output() {
  if [[ -z "$ARG_NUM" ]]
  then
    echo "No --num argument supplied"
    echo "Use 'task spawn list' to find a number to stop"
    return
  fi
  if [[ -z "$ARG_FOLLoW" ]]
  then
    tailf ${SPAWNED_PROC_OUT[$ARG_NUM]}
  else
    cat ${SPAWNED_PROC_OUT[$ARG_NUM]}
  fi
}

spawn_clean() {
  ## TODO write the code to stop all spawned processes
  echo "Cleaning"
}

spawn_reindex() {
  # ARG_NUM has been removed
  # todo create intellegent reindex
  local num = 1
  for i in ${SPAWNED_PROC[@]}
  do
    persist_var "SPAWNED_PROC[$num]" "$!"
    persist_var "SPAWNED_PROC_NAME[$num]" "\"$ARG_PROC\""
    persist_var "SPAWNED_PROC_OUT[$num]" "\"$ARG_OUT\""
  done
}
