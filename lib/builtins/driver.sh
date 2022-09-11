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

  driver_defs=$TASK_MASTER_HOME/lib/drivers/driver_defs.sh

  if [[ "$TASK_SUBCOMMAND" == "enable" ]]
  then

    if grep -q "${ARG_ID}_driver.sh" "$driver_defs"
    then
      sed "s/^#\(.*${ARG_ID}_driver.sh\)/\1/" "$driver_defs" > "$driver_defs.tmp"
      mv "$driver_defs"{.tmp,}
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
    echo "TASK_DRIVERS[$task_file_name]=${ARG_ID}_driver.sh" >> "$driver_defs"
    echo "$ARG_ID driver enabled for $task_file_name files."

  elif [[ "$TASK_SUBCOMMAND" == "disable" ]]
  then
    if ! grep -q "${ARG_DISABLE}_driver.sh" "$driver_defs"
    then
      echo "$ARG_ID not found"
      return 1
    fi

    sed "s/^.*=${ARG_DISABLE}_driver.sh/#\0/" "$driver_defs" > "$driver_defs.tmp"
    mv "$driver_defs"{.tmp,}
    echo "$ARG_ID driver disabled."
  else
    echo Current drivers:
    grep _driver.sh "$driver_defs" | sed 's/^.*=\(.*\)_driver.sh/   \1/'| uniq | tr -d '\n'
    echo
    echo
  fi
}

readonly -f task_driver
readonly -f arguments_driver
