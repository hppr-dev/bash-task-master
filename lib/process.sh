spawn_start() {
  if [[ -z "$ARG_PROC" ]]
  then
    echo "No --proc argument supplied can't spawn"
    return
  fi
  persist_var NUM_SPAWNED $(expr $NUM_SPAWNED + 1)
  if [[ -z "$ARG_OUT" ]]
  then
    ARG_OUT=$RUNNING_DIR/spawn$NUM_SPAWNED.out
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
  kill ${SPAWNED_PROC[$ARG_NUM]}
  remove_var "SPAWNED_PROC[$ARG_NUM]"
  remove_var "SPAWNED_PROC_NAME[$ARG_NUM]"
  remove_var "SPAWNED_PROC_OUT[$NUM_SPAWNED]"
  persist_var NUM_SPAWNED $(expr $NUM_SPAWNED - 1)
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
  cat ${SPAWNED_PROC_OUT[$ARG_NUM]}
}

