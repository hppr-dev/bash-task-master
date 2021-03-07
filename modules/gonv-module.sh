arguments_gonv() {
  SUBCOMMANDS="init|enable|disable|list|destroy"
  INIT_DESCRIPTION="Initialize a new go environment"
  INIT_OPTIONS="version:v:str name:n:str platform:p:str"
  ENABLE_DESCRIPTION="Enable a go environment"
  ENABLE_OPTIONS="name:n:str"
  DISABLE_DESCRIPTION="Disable current go environment"
  DESTROY_DESCRIPTION="Remove go environment"
  DESTROY_OPTIONS="name:n:str"
  LIST_DESCRIPTION="List go environments"
}

task_gonv() {
  #See https://golang.org/dl/ for available versions/platforms
  DEFAULT_VERSION=1.16
  DEFAULT_PLATFORM=linux-amd64
  case $TASK_SUBCOMMAND in
    "init")
    gonv_init
    ;;
    "enable")
    gonv_enable
    ;;
    "disable")
    gonv_disable
    ;;
    "destroy")
    gonv_destroy
    ;;
    "list")
    gonv_list
    ;;
  esac
}

gonv_check_name() {
  if [[ -z "$ARG_NAME" ]] 
  then
    ARG_NAME=$LOCAL_TASKS_UUID
  fi
  if [[ -z "$ARG_NAME" ]] 
  then
    echo "--name not supplied and could not determine local uuid. Either supply --name or move to a directory with a tasks.sh file"
    exit 1
  fi
  ENV_DIR=$STATE_DIR/gonv/$ARG_NAME
}

gonv_check_active() {
  if [[ -n "$GONV_ACTIVE" ]]
  then
    echo "A go environment is already active. Cannot $TASK_SUBCOMMAND."
    exit 1
  fi
}

gonv_init() {
  gonv_check_name
  if [[ -z "$ARG_VERSION" ]]
  then
    ARG_VERSION=$DEFAULT_VERSION
  fi
  if [[ -z "$ARG_PLATFORM" ]]
  then
    ARG_PLATFORM=$DEFAULT_PLATFORM
  fi

  echo Initializing go $ARG_VERSION environment in $ENV_DIR
  mkdir -p $ENV_DIR/modules
  cd $ENV_DIR
  GO_TAR=go$ARG_VERSION.$ARG_PLATFORM.tar.gz
  wget https://golang.org/dl/$GO_TAR
  tar -xf $GO_TAR
  rm $GO_TAR
}

gonv_enable() {
  gonv_check_name
  gonv_check_active
  echo Enabling go environment $ARG_NAME
  hold_var "PS1"
  hold_var "PATH"
  hold_var "GOPATH"
  export_var "PS1" "(go-$ARG_NAME)-$PS1"
  export_var "PATH" "$PATH:$ENV_DIR/go/bin"
  export_var "GOPATH" "$ENV_DIR/modules"
  persist_var "GONV_ACTIVE" "T" 
  set_trap "cd $RUNNING_DIR; task gonv disable ;"
}

gonv_disable() {
  if [[ -n "$GONV_ACTIVE" ]]
  then
    echo Disabling go environment
    release_var "PS1"
    release_var "PATH"
    release_var "GOPATH"
    export GOPATH=$GOPATH
    remove_var "GONV_ACTIVE"
    unset_trap
  else
    echo Go environment not active
  fi
}

gonv_destroy() {
  gonv_check_name
  gonv_check_active
  echo Destroying go environment
  if [[ -d "$ENV_DIR" ]]
  then
   chmod -R +w $ENV_DIR/
   rm -r $ENV_DIR
  fi
}


readonly -f arguments_gonv
readonly -f task_gonv
readonly -f gonv_check_name
readonly -f gonv_check_active
readonly -f gonv_init
readonly -f gonv_enable
readonly -f gonv_disable
readonly -f gonv_destroy
