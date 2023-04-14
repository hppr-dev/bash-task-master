arguments_global() {
  SUBCOMMANDS='update'

  UPDATE_DESCRIPTION="Update bash task master to another version"
  UPDATE_OPTIONS="dev:d:bool version:v:nowhite check:c:bool"
}

task_global() {
  if [[ $TASK_SUBCOMMAND == "update" ]]
  then
    global_update
  fi
}

global_debug() {
  if [[ -n "$ARG_COMMAND" ]]
  then
    for f in "$STATE_FILE"*
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
  sed 's/.*=\(.*\)/\1/' "$LOCATION_FILE" | while IFS= read -r file
  do
    if [[ ! -d "$file" ]]
    then
      grep -v "$file" "$LOCATION_FILE" > "$LOCATION_FILE.tmp"
      mv "$LOCATION_FILE.tmp" "$LOCATION_FILE"
    fi
  done

  echo "Cleaning state files from tasks files not in $LOCATION_FILE"
  for file in "$TASK_MASTER_HOME/state/"*
  do
    if [[ -d "$file" ]]
    then
      if ! grep -q "$file" "$LOCATION_FILE"
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

global_update() {
  if [[ -z "$ARG_VERSION" ]]
  then
    ARG_VERSION=latest
  fi

  cd "$TASK_MASTER_HOME" || exit 1

  source version.env

  if [[ "$BTM_VERSION" == "dev" ]]
  then
    echo Current version is the development version

    git fetch "$BTM_ASSET_URL" &> /dev/null
    if [[ "$(git rev-parse HEAD)" != "$(git rev-parse '@{u}')" ]]
    then
      if [[ -n "$ARG_CHECK" ]]
      then
        echo There are changes to pull.
        exit 0
      else
        git pull
      fi
    else
      echo There are no updates to pull.
    fi
  else
    echo "Current release version is $BTM_VERSION"

    if [[ -z "$ARG_DEV" ]]
    then
      echo "Retrieving release $ARG_VERSION info..."

      full_asset_url=$BTM_ASSET_URL/download/$ARG_VERSION
      if [[ "$ARG_VERSION" == "latest" ]]
      then
        full_asset_url=$BTM_ASSET_URL/latest/download
      fi
  
      curl -Ls "$full_asset_url/version.env" --output "$TASK_MASTER_HOME/$ARG_VERSION.env"
      if ! grep BTM_VERSION "$TASK_MASTER_HOME/$ARG_VERSION.env" &> /dev/null
      then
        echo "Could not retrieve version $ARG_VERSION."
        rm "$TASK_MASTER_HOME/$ARG_VERSION.env" &> /dev/null
        exit 1
      fi

      if [[ -z "$(diff version.env "$TASK_MASTER_HOME/$ARG_VERSION.env")" ]]
      then
        echo "$ARG_VERSION does not differ from installed version: $BTM_VERSION."
        rm "$TASK_MASTER_HOME/$ARG_VERSION.env"
        exit 1
      fi

      if [[ -n "$ARG_CHECK" ]]
      then
        echo "Updates are available."
        rm "$TASK_MASTER_HOME/$ARG_VERSION.env"
        exit 0
      else
        echo Updating bash-task-master files could lead to instability when using older modules.
        echo It is advisable to check the compatibility of any installed modules and/or drivers before upgrading.
        echo "Press enter to continue... (CTRL-C to cancel)"
        read -r 
      fi

      echo "Backing up current version in /tmp/task-master-$BTM_VERSION..."
      cp -r "$TASK_MASTER_HOME" "/tmp/task-master-$BTM_VERSION"

      echo "Getting $ARG_VERSION assets..."
      curl -Ls "$full_asset_url/btm.tar.gz" | tar -xz

      echo "Installing $ARG_VERSION assets..."
      cp -rf dist/* "$TASK_MASTER_HOME"

      echo Updating version file...
      mv "$ARG_VERSION.env" version.env
      rm -r dist

    else
      echo Updating bash-task-master files could lead to instability when using older modules.
      echo It is advisable to check the compatibility of any installed modules and/or drivers before upgrading.
      echo Updating from a release version to the development version is irreversible
      echo You will need to reinstall any custom drivers.
      echo "Press enter to continue... (CTRL-C to cancel)"
      read -r 

      git clone https://github.com/hppr-dev/bash-task-master.git "$TASK_MASTER_HOME.new"

      for d in modules state templates
      do
        cp -r "$TASK_MASTER_HOME/$d"/* "$TASK_MASTER_HOME.new/$d"
      done

      mv "$TASK_MASTER_HOME" "/tmp/task-master-$BTM_VERSION"
      mv "$TASK_MASTER_HOME"{.new,}

    fi
    echo "bash-task-master $ARG_VERSION now installed"
    echo "Please log out and log back in to complete installation."
  fi
}

readonly -f arguments_global
readonly -f task_global
readonly -f global_update
