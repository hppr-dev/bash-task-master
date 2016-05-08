record_start(){
  echo "Starting record..."
  # setup recording file to save context
  persist_var RECORDING_FILE "$TASKS_DIR/.rec_$NAME"
  # save starting directory
  persist_var RECORD_START "$RUNNING_DIR"
  # save name
  persist_var RECORD_NAME "$NAME"
  # Save prompt command and change it to save commands
  hold_var PROMPT_COMMAND
  export_var PROMPT_COMMAND "'echo \$(history 1 | tr -s \" \" | cut -f 3- -d \" \") >> $RECORDING_FILE;'"
}

record_stop(){
  if [ ! -z "$RECORDING_FILE" ]
  then
    #Check to see if the user gave a name on record stop
    if [[ ! -z "$NAME" ]] && [[ "$RECORD_NAME" != "$NAME" ]]
    then
      mv $RECORDING_FILE $TASKS_DIR/.rec_$NAME
      RECORDING_FILE=$TASKS_DIR/.rec_$NAME
    elif [[ -z "$NAME" ]] 
    then
      $NAME=$RECORD_NAME
    fi

    # Change prompt back what it was before recording
    release_var PROMPT_COMMAND
    echo "Stopped Recording..."

    # Test to see if task is already defined
    type "task_$NAME" &> /dev/null
    if [[ "$?" == "1" ]]
    then
      # Write it to file
      echo "Writing record to $TASKS_FILE : "
      tee -a $TASKS_FILE << EOM
# Recorded Task
task_$NAME() {
    pushd \`pwd\` > /dev/null
    cd $RECORD_START
`tail -n +2 $RECORDING_FILE | sed 's/^/    /'`
    popd > /dev/null
}
EOM
      # cleanup
      rm $RECORDING_FILE
      clean_up_state
    else
      echo "Wont write to file: task_$NAME already exists"
      echo "Try supplying another name using 'task record stop --name something_else'"
    fi
  else
    echo "You are not recording..."
    echo "Run 'task record start' to start "
  fi
}

record_trash(){
    if [ ! -z "$RECORDING_FILE" ]
    then
      #remove_state first
      clean_up_state 
      #then Change prompt back what it was before recording
      release_var PROMPT_COMMAND
      # Remove recording file
      echo "Trashing record file $RECORDING_FILE"
      # Remove recording file
      rm $RECORDING_FILE
    else
      if [ ! -z "$ARG_FORCE" ]
      then
        echo "Forcing removal of all .rec files in $TASKS_DIR"
        rm -i $TASKS_DIR/.rec_*
      else
        echo "You are not recording..."
        echo "Run 'task record trash --force' to remove all .rec_* files in $TASKS_DIR "
      fi
    fi
}

record_restart(){
    if [ ! -z "$RECORDING_FILE" ]
    then
      # Reset recording file
      echo "Resetting record file..."
      rm $RECORDING_FILE
      echo "Moving back to the start directory..."
      set_return_directory $RECORD_START
    else
      echo "You are not recording..."
      echo "Run 'task record start' to start "
    fi
}
