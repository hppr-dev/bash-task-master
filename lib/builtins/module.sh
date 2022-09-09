arguments_module() {
  SUBCOMMANDS="enable|disable|list"

  MODULE_DESCRIPTION="Manage modules."

  ENABLE_DESCRIPTION="Enable a module. Downloads modules from TASK_REPOS if not found locally."
  ENABLE_REQUIREMENTS="id:i:str"

  DISABLE_DESCRIPTION="Disable a module"
  DISABLE_REQUIREMENTS="id:i:str"

  LIST_DESCRIPTION="List modules"
  LIST_OPTIONS="all:a:bool remote:r:bool enabled:e:bool disabled:d:bool local:l:bool"
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
  fi
}

module_enable() {
  filename="$TASK_MASTER_HOME/modules/$ARG_ID-module.sh"
  if [[ -f "$filename.disabled" ]]
  then
    # Module already downloaded
    echo "Enabling $ARG_ID module..."
    mv "$filename"{.disabled,}
  else
    echo Searching repositories...
    for repo in $TASK_REPOS
    do
      inventory=$(curl -s "$repo")
      module_file=$(echo "$inventory" | grep "module-$ARG_ID" | awk -F '=' '{ print $2 }' | xargs )
      if [[ -n "$module_file" ]]
      then
        echo "$ARG_ID module found in $repo"
        break
      fi
    done
    if [[ -z "$module_file" ]]
    then
      echo "Unable to find $ARG_ID module"
      return 1
    fi
    module_dir=$(dirname "$repo")/$(echo "$inventory" | grep MODULE_DIR | awk -F '=' '{ print $2 }' | xargs )
    echo "Downloading $module_dir/$module_file..."
    curl -s "$module_dir/$module_file" >> "$filename"
    echo "$ARG_ID module installed."
  fi 
}

module_disable() {
  if [[ -f "$TASK_MASTER_HOME/modules/$ARG_ID-module.sh" ]]
  then
    echo "Disabling $ARG_ID module..."
    mv "$TASK_MASTER_HOME/modules/$ARG_ID-module.sh"{,.disabled}
  else
    echo "Could not find $ARG_ID module"
    return 1
  fi
}

module_list() {
  local_files=$(get_local_module_files | awk -F "$TASK_MASTER_HOME/modules/" '{ print $2 }')

  if [[ -n "$ARG_REMOTE" ]]
  then 
    echo Available Remote Modules:
    get_repo_module_list
    echo
  fi
  if [[ -n "$ARG_ALL$ARG_DISABLED" ]]
  then
    echo "Disabled Modules:"
    echo "$local_files" | grep disabled | sed 's/\(.*\)-module.sh.disabled/    \1/'
    echo
  fi
  if [[ -n "$ARG_ALL$ARG_ENABLED" ]]
  then
    echo "Enabled Modules:"
    echo "$local_files" | grep -v disabled | sed 's/\(.*\)-module.sh/    \1/'
    echo
  fi
}

get_repo_module_list() {
  for repo in $TASK_REPOS
  do
    curl -s "$repo" | awk '/module-.*/ { print } 0' | sed 's/\s*module-\(.*\) = .*/    \1/'
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
readonly -f get_repo_module_list
readonly -f get_local_module_files
