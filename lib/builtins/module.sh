arguments_module() {
  SUBCOMMANDS="enable|disable|list|clean"

  MODULE_DESCRIPTION="Manage modules."

  ENABLE_DESCRIPTION="Enable a module. Downloads modules from TASK_REPOS if not found locally."
  ENABLE_REQUIREMENTS="name:n:str"

  DISABLE_DESCRIPTION="Disable a module"
  DISABLE_REQUIREMENTS="name:n:str"

  LIST_DESCRIPTION="List modules"
  LIST_OPTIONS="all:a:bool remote:r:bool enabled:e:bool disabled:d:bool local:l:bool"

  CLEAN_DESCRIPTION="Remove all disabled modules files"
  CLEAN_OPTIONS="force:f:bool"
}

task_module() {
  if [[ "$TASK_SUBCOMMAND" == "enable" ]]
  then
    module_enable
  elif [[ "$TASK_SUBCOMMAND" == "disable" ]]
  then
    module_disable
  elif [[ "$TASK_SUBCOMMAND" == "list" ]]
  then
    module_list
  elif [[ "$TASK_SUBCOMMAND" == "clean" ]]
  then
    module_clean
  fi
}

module_enable() {
  filename="$TASK_MASTER_HOME/modules/$ARG_NAME-module.sh"
  if [[ -f "$filename.disabled" ]]
  then
    # Module already downloaded
    echo "Enabling $ARG_NAME module..."
    mv "$filename"{.disabled,}
  else
    echo Searching repositories...
    for repo in $TASK_REPOS
    do
      inventory=$(curl -s "$repo")
      module_file=$(echo "$inventory" | grep "module-$ARG_NAME" | awk -F '=' '{ print $2 }' | xargs )
      if [[ -n "$module_file" ]]
      then
        echo "$ARG_NAME module found in $repo"
        break
      fi
    done
    if [[ -z "$module_file" ]]
    then
      echo "Unable to find $ARG_NAME module"
      return 1
    fi
    module_dir=$(dirname "$repo")/$(echo "$inventory" | grep MODULE_DIR | awk -F '=' '{ print $2 }' | xargs )
    echo "Downloading $module_dir/$module_file..."
    curl -s "$module_dir/$module_file" --output "$filename"
    echo "$ARG_NAME module installed."
  fi 
}

module_disable() {
  if [[ -f "$TASK_MASTER_HOME/modules/$ARG_NAME-module.sh" ]]
  then
    echo "Disabling $ARG_NAME module..."
    mv "$TASK_MASTER_HOME/modules/$ARG_NAME-module.sh"{,.disabled}
  else
    echo "Could not find $ARG_NAME module"
    return 1
  fi
}

module_list() {
  local_files=$(get_local_module_files | awk -F "$TASK_MASTER_HOME/modules/" '{ print $2 }')
  if [[ -z "$ARG_REMOTE$ARG_ENABLED$ARG_DISABLED" ]]
  then
    ARG_ENABLED=1
  fi

  if [[ -n "$ARG_REMOTE" ]]
  then 
    get_repo_module_list
  fi
  if [[ -n "$ARG_ALL$ARG_DISABLED" ]]
  then
    grep disabled <<< "$local_files" | sed 's/\(.*\)-module.sh.disabled/\1/' | pr -5 -tT
  fi
  if [[ -n "$ARG_ALL$ARG_ENABLED" ]]
  then
    grep -v disabled <<< "$local_files" | sed 's/\(.*\)-module.sh/\1/' | pr -5 -tT
  fi
}

module_clean() {
  if [[ -z "$ARG_FORCE" ]]
  then
    echo -n "This will remove all disabled module files. Press enter to continue... (CTRL-C to cancel)"
    read -r
  fi

  find "$TASK_MASTER_HOME/modules" -name "*-module.sh.disabled" -exec rm {} \; -exec echo Removing {}... \;
}

get_repo_module_list() {
  for repo in $TASK_REPOS
  do
    echo "$repo:"
    curl -s "$repo" | awk '/module-.*/ { print } 0' | sed 's/\s*module-\(.*\) = .*/\1/' | pr -5 -tT
    echo
  done
}

get_local_module_files() {
  find "$TASK_MASTER_HOME/modules" -name '*-module.sh' -or -name '*-module.sh.disabled' 
}


readonly -f arguments_module
readonly -f task_module
readonly -f module_enable
readonly -f module_disable
readonly -f module_list
readonly -f module_clean
readonly -f get_repo_module_list
readonly -f get_local_module_files
