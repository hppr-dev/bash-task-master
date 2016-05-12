record_help() {
  HELP_STRING="usage: task record (start|stop|restart|trash|help)

  This task is designed to create other tasks by recording your bash history

  To start a recording run:

        task record start [--name <task_name>]

  To stop a recording and write it as a task to the local tasks.sh file run:

        task record stop [--name <task_name>]

  To throw away the current recording or old recordings run:

         task record trash [--force]

  To start a new recording after you have started recording run:

         task record restart

  To view this help run

         task record (start|stop|restart|trash) --help
                    or
         task record help"

  echo "$HELP_STRING"
}

arguments_record() {
  SUBCOMMANDS='start|stop|restart|trash|help'
  START_OPTIONS='name:n:str sub:s:str reqs:r:str opts:o:str'
  STOP_OPTIONS='name:n:str sub:s:str reqs:r:str opts:o:str'
  TRASH_OPTIONS='force:f:bool'
}

record_start(){
  if [[ "$RUNNING_GLOBAL" == "1" ]]
  then
    echo "Can't record with a tasks file. run 'task init' to create one" 
    return 1
  fi
  NAME=${ARG_NAME,,}
  if [[ -z "$NAME" ]] || [[ $NAME == "1" ]]
  then
     NAME="unnamed"
  fi
  echo "Starting record..."
  # setup recording file to save context
  persist_var RECORDING_FILE "$TASKS_DIR/.rec_$NAME"
  # save starting directory
  persist_var RECORD_START "$RUNNING_DIR"
  # save name
  persist_var RECORD_NAME "$NAME"
  # save current tasks file
  persist_var RECORD_TASKS_FILE "$TASKS_FILE"
  # save if the sub was given
  if [[ ! -z "$ARG_SUB" ]]
  then
    persist_var "ARG_SUB" "$ARG_SUB"
  fi
  if [[ ! -z "$ARG_OPTS" ]]
  then
    persist_var "ARG_OPTS" "$ARG_OPTS"
  fi
  if [[ ! -z "$ARG_REQS" ]]
  then
    persist_var "ARG_REQS" "$ARG_REQS"
  fi
  # Save prompt command and change it to save commands
  echo 'echo $( history 1 | tr -s " " | cut -f 3- -d " ") >>' $RECORDING_FILE > $TASKS_DIR/.record-script
  chmod +x $TASKS_DIR/.record-script
  hold_var PROMPT_COMMAND " $TASKS_DIR/.record-script ; $PROMPT_COMMAND"
  hold_var PS1 "(rec/$LOCAL_TASKS_UUID) $PS1"
}

record_stop(){
  NAME=${ARG_NAME,,}
  if [[ -z "$NAME" ]] || [[ $NAME == "1" ]]
  then
     NAME="unnamed"
  fi
  if [[ ! -z "$RECORDING_FILE" ]]
  then
    #Check to see if the user gave a name on record stop
    #user gives name on start: $RECORD_NAME is set but $NAME is unnamed
    if [[ "$NAME" == "unnamed" ]] && [[ ! -z "$RECORD_NAME" ]]
    then
      NAME=$RECORD_NAME
      mv $RECORDING_FILE $TASKS_DIR/.rec_$NAME
      RECORDING_FILE=$TASKS_DIR/.rec_$NAME
    fi

    # Change prompt back what it was before recording
    release_var PROMPT_COMMAND
    release_var PS1
    echo "Stopped Recording..."

    echo "Backing up tasks file to $TASK_MASTER_HOME/backup/tasks.bk"
    cp $TASKS_FILE $TASK_MASTER_HOME/backup/tasks.bk

    # Test to see if task is already defined
    type "task_$NAME" &> /dev/null
    if [[ "$?" == "1" ]] || [[ ! -z "$ARG_SUB" ]]
    then
      # Write it to file
      echo "Writing record to $RECORD_TASKS_FILE : "
      local insert_text="  cd $RECORD_START
$(tail -n +2 $RECORDING_FILE | sed 's/^/  /')"
      if [[ ! -z "$ARG_SUB" ]]
      then
        # Write subcommand
        local insert_text="
  #Recorded subcommand
  if [[ \$TASK_SUBCOMMAND == \"$ARG_SUB\" ]]
  then
$(sed 's/^/  /' <<< "$insert_text")
  fi"
      fi
      awk -f $TASK_AWK_DIR/command.awk -v name="$NAME" -v code="$insert_text" -i inplace $TASKS_FILE

      local task_ref=${ARG_SUB^^}
      if [[ -z "$ARG_SUB" ]]
      then
        local task_ref=${NAME^^}
      fi

      # Load existing options if they exist
      SUBCOMMANDS=""
      type arguments_$NAME &> /dev/null 
      if [[ "$?" == "0" ]]
      then
        arguments_$NAME
      fi

      # Write requirements
      if [[ ! -z "$ARG_REQS" ]]
      then
        echo "Writing Requirements..."
        awk -f $TASK_AWK_DIR/arguments.awk -v name="$NAME" -v key="${task_ref}_REQUIREMENTS" -v value="$ARG_REQS" -i inplace $TASKS_FILE
      fi
  
      # Write options
      if [[ ! -z "$ARG_OPTS" ]]
      then
        echo "Writing Options..."
        awk -f $TASK_AWK_DIR/arguments.awk -v name="$NAME" -v key="${task_ref}_OPTIONS" -v value="$ARG_OPTS" -i inplace $TASKS_FILE
      fi

      # Update subcommands
      echo "Updating subcommands.."
      # If the task already exists we want to match empty string
      type "task_$NAME" &> /dev/null
      if [[ "$?" != "0" ]] || [[ ! -z "$SUBCOMMANDS" ]]
      then
        ARG_SUB="$ARG_SUB|$SUBCOMMANDS"
      fi
      awk -f $TASK_AWK_DIR/arguments.awk -v name="$NAME" -v key="SUBCOMMANDS" -v value="$ARG_SUB" -i inplace $TASKS_FILE

      # cleanup
      rm $RECORDING_FILE $TASKS_DIR/.record-script
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
    if [[ ! -z "$RECORDING_FILE" ]]
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
      if [[ ! -z "$ARG_FORCE" ]]
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
    if [[ ! -z "$RECORDING_FILE" ]]
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

# before text = everything before the given def
# text = everything up to the close of the def
# after text = everything after (includes the } of the def)
record_extract_text_from_tasks(){
  before_text=$(awk "/^$1.*/ {f=1} f==0" $TASKS_FILE)
  text=$(awk "/^$1.*/ {f=1} /^}$/ {f=0;next} f" $TASKS_FILE)
  after_text=$(awk "/^$1.*/ {f=1} /^}$/ {s=f} f&&s" $TASKS_FILE)
}
