arguments_global() {
  SUBCOMMANDS='debug|set|unset|edit|clean|driver'

  DEBUG_DESCRIPTION="Show variables for a command"
  DEBUG_OPTIONS='command:c:str'

  SET_DESCRIPTION="Set a variable for a command"
  SET_REQUIREMENTS='key:k:str value:v:str command:c:str'

  UNSET_DESCRIPTION="Unset a variable for a command"
  UNSET_REQUIREMENTS='key:k:str command:c:str'

  EDIT_DESCRIPTION="Edit a command's variables"
  EDIT_REQUIREMENTS='command:c:str'

  CLEAN_DESCRIPTION="Clean up stale location and state files."

  DRIVER_DESCRIPTION="Manage drivers"
  DRIVER_OPTIONS="enable:e:str disable:d:str list:l:bool"
}

task_global() {
  if [[ $TASK_SUBCOMMAND == "debug" ]]
  then
    global_debug
  elif [[ $TASK_SUBCOMMAND == "set" ]]
  then
    global_set
  elif [[ $TASK_SUBCOMMAND == "unset" ]]
  then
    global_unset
  elif [[ $TASK_SUBCOMMAND == "edit" ]]
  then
    global_edit
  elif [[ $TASK_SUBCOMMAND == "clean" ]]
  then
    global_clean
  elif [[ $TASK_SUBCOMMAND == "driver" ]]
  then
    global_driver
  fi
}

global_debug() {
  if [[ -n "$ARG_COMMAND" ]]
  then
    for f in "$STATE_DIR/$ARG_COMMAND.vars"*
    do
      echo "==================== $f ======================"
      cat "$f"
    done
  else
    for f in "$TASK_MASTER_HOME/state/"***.vars*
    do
      echo "==================== $f ======================"
      cat "$f"
    done
  fi
}

global_set() {
  local STATE_FILE=$TASK_MASTER_HOME/state/$ARG_COMMAND.vars
  persist_var "$ARG_KEY" "$ARG_VALUE"
  echo "Value saved, variables for $ARG_COMMAND :"
  global_debug
}

global_unset() {
  local STATE_FILE=$TASK_MASTER_HOME/state/$ARG_COMMAND.vars
  remove_var "$ARG_KEY" "$ARG_VALUE"
  echo "Value removed, variables for $ARG_COMMAND :"
  global_debug
}

global_edit() {
    $DEFAULT_EDITOR "$TASK_MASTER_HOME/state/$ARG_COMMAND.vars"
}

global_clean() {
  echo "Removing nonexistant locations from locations file..."
  sed 's/.*=\(.*\)/\1/' "$LOCATIONS_FILE" | while IFS= read -r file
  do
    if [[ ! -d "$file" ]]
    then
      grep -v "$file" "$LOCATIONS_FILE" > "$LOCATIONS_FILE.tmp"
      mv "$LOCATIONS_FILE.tmp" "$LOCATIONS_FILE"
    fi
  done

  echo "Cleaning state files from tasks files not in $LOCATIONS_FILE"
  for file in "$TASK_MASTER_HOME/state/"*
  do
    if [[ -d "$file" ]]
    then
      if ! grep -q "$file" "$LOCATIONS_FILE"
      then
        echo "Removing $file..."
        rm -r "$file"
      fi
    fi
  done

  echo "Removing empty files from state directory..."
  local empty_files
  empty_files=$(find "$TASK_MASTER_HOME/state/"* -type f -empty)
  if [[ -n "$empty_files" ]]
  then
    rm "$empty_files"
  fi
}

global_driver() {
  if [[ "$ARG_DISABLE" == "bash" ]] || [[ "$ARG_ENABLE" == "bash" ]]
  then
    echo Can not modify the bash driver!
    return 1
  fi

  driver_defs=$TASK_MASTER_HOME/lib/drivers/driver_defs.sh

  if [[ -n "$ARG_ENABLE" ]]
  then
    if grep -q "${ARG_ENABLE}_driver.sh" "$driver_defs"
    then
      sed "s/^#\(.*${ARG_DISABLE}_driver.sh\)/\1/" "$driver_defs" > "$driver_defs.tmp"
      mv "$driver_defs"{.tmp,}
      echo "$ARG_ENABLE driver re-enabled."
      return 0
    fi
    echo "Searching repositories for $ARG_ENABLE driver..."
    for repo in $TASK_REPOS
    do
      inventory=$(curl -s "$repo")
      remote_driver_file=$(echo "$inventory" | grep "driver-$ARG_ENABLE" | awk -F '=' '{ print $2 }' | xargs )
      if [[ -n "$remote_driver_file" ]]
      then
        echo "$ARG_ENABLE driver found in $repo"
        break
      fi
    done
    if [[ -z "$remote_driver_file" ]]
    then
      echo "Could not find $ARG_ENABLE driver."
      return 1
    fi
    local_file=$TASK_MASTER_HOME/lib/drivers/${ARG_ENABLE}_driver.sh
    remote_driver_dir=$(dirname "$repo")/$(echo "$inventory" | grep DRIVER_DIR | awk -F '=' '{ print $2 }' | xargs )
    echo Downloading driver file...
    curl -s "$remote_driver_dir/$remote_driver_file" > "$local_file"
    echo Downloading extra files...
    grep "#\s*extra_file" "$local_file" | awk -F '=' '{ print $2 }' | tr -d ' ' | while IFS= read -r extra_file
    do
      target_dir=$( dirname "$extra_file" )
      target_file=$( basename "$extra_file" )
      if [[ -n "$target_dir" ]]
      then
        mkdir -p "$TASK_MASTER_HOME/lib/drivers/$target_dir"
      fi
      echo "Downloading extra file: $target_dir/$target_file..."
      curl -s "$remote_driver_dir/$target_dir/$target_file" > "$TASK_MASTER_HOME/lib/drivers/$target_dir/$target_file"
    done

    echo Adding driver def...
    task_file_name=$( grep "#\s*tasks_file_name" "$local_file" | awk -F '=' '{ print $2 }' | xargs )
    echo "TASK_DRIVERS[$task_file_name]=${ARG_ENABLE}_driver.sh" >> "$driver_defs"
    echo "$ARG_ENABLE driver enabled for $task_file_name files."
  elif [[ -n "$ARG_DISABLE" ]]
  then
    if ! grep -q "${ARG_DISABLE}_driver.sh" "$driver_defs"
    then
      echo "$ARG_DISABLE not found"
      return 1
    fi

    sed "s/^.*=${ARG_DISABLE}_driver.sh/#\0/" "$driver_defs" > "$driver_defs.tmp"
    mv "$driver_defs"{.tmp,}
    echo "$ARG_DISABLE driver disabled."
  else
    echo Current drivers:
    grep _driver.sh "$driver_defs" | sed 's/^.*=\(.*\)_driver.sh/   \1/'| uniq | tr -d '\n'
    echo
    echo
  fi
}

readonly -f task_global
readonly -f global_debug
readonly -f global_set
readonly -f global_unset
readonly -f global_edit
readonly -f global_clean
readonly -f global_driver
