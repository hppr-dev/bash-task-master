arguments_driver() {
  SUBCOMMANDS="enable|disable|list"
  DRIVER_DESCRIPTION="Manage drivers"

  ENABLE_DESCRIPTION="Enable a driver. Will check TASK_REPOS for drivers not available locally."
  ENABLE_REQUIREMENTS="name:n:str"

  DISABLE_DESCRIPTION="Disable a driver. Removes a driver from the list of available drivers but keeps driver files."
  DISABLE_REQUIREMENTS="name:n:str"

  LIST_DESCRIPTION="List available drivers"
  LIST_OPTIONS="remote:r:bool"
}

task_driver() {
  if [[ "$ARG_NAME" == "bash" ]]
  then
    echo Can not modify the bash driver!
    return 1
  fi

  driver_defs=$TASK_MASTER_HOME/lib/drivers/installed_drivers.sh

  if [[ "$TASK_SUBCOMMAND" == "enable" ]]
  then
    if grep -q "${ARG_NAME}_driver.sh" "$driver_defs"
    then
      sed "s/^#\(TASK_FILE_NAME_DICT\[.*\]=$ARG_NAME\)/\1/" "$driver_defs" > "$driver_defs.tmp"
      sed "s/^#\(TASK_DRIVER_DICT\[${ARG_NAME}\]=.*\)/\1/" "$driver_defs.tmp" > "$driver_defs"
      rm "$driver_defs.tmp"
      echo "$ARG_NAME driver re-enabled."
      return 0
    fi

    echo "Searching repositories for $ARG_NAME driver..."
    for repo in $TASK_REPOS
    do
      inventory=$(curl -s "$repo")
      remote_driver_file=$(echo "$inventory" | grep "driver-$ARG_NAME" | awk -F '=' '{ print $2 }' | xargs )
      if [[ -n "$remote_driver_file" ]]
      then
        echo "$ARG_NAME driver found in $repo"
        break
      fi
    done

    if [[ -z "$remote_driver_file" ]]
    then
      echo "Could not find $ARG_NAME driver."
      return 1
    fi

    local_file=$TASK_MASTER_HOME/lib/drivers/${ARG_NAME}_driver.sh
    remote_driver_dir=$(dirname "$repo")/$(echo "$inventory" | grep DRIVER_DIR | awk -F '=' '{ print $2 }' | xargs )

    echo Downloading driver file...
    if ! curl -s "$remote_driver_dir/$remote_driver_file" > "$local_file"
    then
      echo "Could not download $remote_driver_dir/$remote_driver_file"
      rm "$local_file"
      return 1
    fi

    echo Checking dependencies...
    if ! grep "#\s*dependency" "$local_file" | awk -F '=' '{ print $2 }' | tr -d ' ' | \
      while IFS= read -r dependency
      do
        if ! command -v "$dependency" &> /dev/null
        then
          echo "Can not find required $dependency in PATH."
          echo "Install $dependency and try again."
          rm "$local_file"
          return 1
        fi
      done
    then
      return 1
    fi

    echo Downloading extra files...
    if ! grep "#\s*extra_file\s*=" "$local_file" | awk -F '=' '{ print $2 }' | tr -d ' ' | \
      while IFS= read -r extra_file
      do
        target_dir=$( dirname "$extra_file" )
        if [[ -n "$target_dir" ]]
        then
          mkdir -p "$TASK_MASTER_HOME/lib/drivers/$target_dir"
        fi
        echo "Downloading extra file: $extra_file..."
        if ! curl -s "$remote_driver_dir/$extra_file" > "$TASK_MASTER_HOME/lib/drivers/$extra_file"
        then
          echo "Failed to download $remote_driver_dir/$extra_file."
          echo "Check repository availability and try again"
          rm "$local_file" "$TASK_MASTER_HOME/lib/drivers/$extra_file"
          return 1
        fi
      done
    then
      return 1
    fi

    setup_script=$(grep "#\s*setup\s*=" "$local_file" | head -n 1 | awk -F '=' '{ print $2 }' | tr -d ' ')
    if [[ -n "$setup_script" ]]
    then
      echo Running Setup...
      if ! curl -s "$remote_driver_dir/$setup_script" | bash -s 
      then
        echo "Something went wrong with the setup script."
        echo "Check output and try again."
        rm "$local_file"
        return 1
      fi
    fi

    template=$(grep "#\s*template\s*=" "$local_file" | head -n 1 | awk -F '=' '{ print $2 }' | tr -d ' ')
    if [[ -n "$template" ]]
    then
      echo Creating default template...
      if ! curl -s "$remote_driver_dir/$template" > "$TASK_MASTER_HOME/templates/$ARG_NAME.template"
      then
        echo "Could not download template $remote_driver_dir/$template"
        rm "$TASK_MASTER_HOME/templates/$ARG_NAME.template"
        echo "Continuing..."
      fi
    fi
      

    echo Adding driver definitions...
    task_file_name=$( grep "#\s*tasks_file_name" "$local_file" | awk -F '=' '{ print $2 }' | tr -d ' ' )
    echo "TASK_FILE_NAME_DICT[$task_file_name]=${ARG_NAME}" >> "$driver_defs"
    echo "TASK_DRIVER_DICT[$ARG_NAME]=${ARG_NAME}_driver.sh" >> "$driver_defs"
    echo "$ARG_NAME driver enabled for $task_file_name files."

  elif [[ "$TASK_SUBCOMMAND" == "disable" ]]
  then
    if ! grep -q "^TASK_DRIVER_DICT\[$ARG_NAME\]=" "$driver_defs"
    then
      echo "Driver $ARG_NAME not found"
      return 1
    fi

    sed "s/^TASK_FILE_NAME_DICT\[.*\]=$ARG_NAME/#\0/" "$driver_defs" > "$driver_defs.tmp"
    sed "s/^TASK_DRIVER_DICT\[$ARG_NAME\]=.*/#\0/" "$driver_defs.tmp" > "$driver_defs"
    rm "$driver_defs.tmp"
    echo "$ARG_NAME driver disabled."
  elif [[ "$TASK_SUBCOMMAND" == "list" ]]
  then
    if [[ -n "$ARG_REMOTE" ]]
    then
      for repo in $TASK_REPOS
      do
        echo "$repo:"
        curl -s "$repo" | awk '/driver-.*/ { print } 0' | sed 's/\s*driver-\(.*\) = .*/\1/' | pr -5 -tT
        echo
      done
    else
      echo "${!TASK_DRIVER_DICT[*]}" | tr ' ' '\n' | pr -5 -tT
    fi
  fi
}

readonly -f task_driver
readonly -f arguments_driver
