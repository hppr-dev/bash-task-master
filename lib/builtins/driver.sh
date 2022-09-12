arguments_driver() {
  SUBCOMMANDS="enable|disable|list"
  DRIVER_DESCRIPTION="Manage drivers"
  ENABLE_REQUIREMENTS="id:i:str"
  DISABLE_REQUIREMENTS="id:i:str"
}

task_driver() {
  if [[ "$ARG_ID" == "bash" ]]
  then
    echo Can not modify the bash driver!
    return 1
  fi

  driver_defs=$TASK_MASTER_HOME/lib/drivers/installed_drivers.sh

  if [[ "$TASK_SUBCOMMAND" == "enable" ]]
  then
    if grep -q "${ARG_ID}_driver.sh" "$driver_defs"
    then
      sed "s/^#\(TASK_FILE_NAME_DICT\[.*\]=$ARG_ID\)/\1/" "$driver_defs" > "$driver_defs.tmp"
      sed "s/^#\(TASK_DRIVER_DICT\[${ARG_ID}\]=.*\)/\1/" "$driver_defs.tmp" > "$driver_defs"
      rm "$driver_defs.tmp"
      echo "$ARG_ID driver re-enabled."
      return 0
    fi

    echo "Searching repositories for $ARG_ID driver..."
    for repo in $TASK_REPOS
    do
      inventory=$(curl -s "$repo")
      remote_driver_file=$(echo "$inventory" | grep "driver-$ARG_ID" | awk -F '=' '{ print $2 }' | xargs )
      if [[ -n "$remote_driver_file" ]]
      then
        echo "$ARG_ID driver found in $repo"
        break
      fi
    done

    if [[ -z "$remote_driver_file" ]]
    then
      echo "Could not find $ARG_ID driver."
      return 1
    fi

    local_file=$TASK_MASTER_HOME/lib/drivers/${ARG_ID}_driver.sh
    remote_driver_dir=$(dirname "$repo")/$(echo "$inventory" | grep DRIVER_DIR | awk -F '=' '{ print $2 }' | xargs )

    echo Downloading driver file...
    if ! curl -s "$remote_driver_dir/$remote_driver_file" > "$local_file"
    then
      echo "Could not download $remote_driver_dir/$remote_driver_file"
      return 1
    fi

    echo Checking dependencies...
    grep "#\s*dependency" "$local_file" | awk -F '=' '{ print $2 }' | tr -d ' ' | while IFS= read -r dependency
    do
      if ! command -v $dependency &> /dev/null
      then
        echo "Can not find required $dependency in PATH."
        echo "Install $dependency and try again."
        rm "$local_file"
        return 1
      fi
    done

    echo Downloading extra files...
    grep "#\s*extra_file\s*=" "$local_file" | awk -F '=' '{ print $2 }' | tr -d ' ' | while IFS= read -r extra_file
    do
      target_dir=$( dirname "$extra_file" )
      if [[ -n "$target_dir" ]]
      then
        mkdir -p "$TASK_MASTER_HOME/lib/drivers/$target_dir"
      fi
      echo "Downloading extra file: $extra_file..."
      if ! curl -s "$remote_driver_dir/$extra_file" > "$TASK_MASTER_HOME/lib/drivers/$extra_file"
      then
        echo "Failed to download $remote_driver_dir/$target_dir/$target_file."
        echo "Check repository availability and try again"
        rm "$local_file"
        return 1
      fi
    done

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
      if ! curl -s "$remote_driver_dir/$template" > "$TASK_MASTER_HOME/templates/$ARG_ID.template"
      then
        echo "Could not download template $remote_driver_dir/$template"
        echo "Continuing..."
      fi
    fi
      

    echo Adding driver definitions...
    task_file_name=$( grep "#\s*tasks_file_name" "$local_file" | awk -F '=' '{ print $2 }' | tr -d ' ' )
    echo "TASK_FILE_NAME_DICT[$task_file_name]=${ARG_ID}" >> "$driver_defs"
    echo "TASK_DRIVER_DICT[$ARG_ID]=${ARG_ID}_driver.sh" >> "$driver_defs"
    echo "$ARG_ID driver enabled for $task_file_name files."

  elif [[ "$TASK_SUBCOMMAND" == "disable" ]]
  then
    if ! grep -q "^TASK_DRIVER_DICT\[$ARG_ID\]=" "$driver_defs"
    then
      echo "Driver $ARG_ID not found"
      return 1
    fi

    sed "s/^TASK_FILE_NAME_DICT\[.*\]=$ARG_ID/#\0/" "$driver_defs" > "$driver_defs.tmp"
    sed "s/^TASK_DRIVER_DICT\[$ARG_ID\]=.*/#\0/" "$driver_defs.tmp" > "$driver_defs"
    rm "$driver_defs.tmp"
    echo "$ARG_ID driver disabled."
  else
    echo Current drivers:
    echo "    ${!TASK_DRIVER_DICT[@]}"
    echo
  fi
}

readonly -f task_driver
readonly -f arguments_driver
