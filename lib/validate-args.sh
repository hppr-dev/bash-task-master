validate_args_for_task() {
  # Define available types
  declare -A verif
  local avail_types='str|int|bool'
  local verif[str]='.*'
  local verif[int]='[0-9]*'
  local verif[bool]='[01]'

  # Check if argument specifications exist
  type arguments_$TASK_COMMAND &> /dev/null 
  if [[ "$?" == "0" ]]
  then
    # check if subcommand exists or if there are no subcommands
    if [[ $TASK_SUBCOMMAND =~ ^($SUBCOMMANDS)$ ]] || [[ -z "$SUBCOMMANDS" ]]
    then
      # handle subcommandless tasks
      local sub=${TASK_SUBCOMMAND^^}
      if [[ -z "$TASK_SUBCOMMAND" ]]
      then
        sub=${TASK_COMMAND^^}
      fi
      # Check required arguments
      local reqvar="${sub}_REQUIREMENTS"
      if [[ ! -z "${!reqvar}" ]]
      then
        for requirement in ${!reqvar}
        do
          local name=${requirement%%:*}
          local atype=${requirement##*:}
          # Make sure that the argument exists
          local valname="ARG_${name^^}"
          if [[ -z "${!valname}" ]]
          then
            echo "Missing required argument: --${name,,}"
            return 1
          fi
          # Make sure that the argument is the right type
          if [[ ! "${!valname}" =~ ^${verif[$atype]}$ ]]
          then
            echo "--${name,,} argument does not follow verification requirements: $atype:::${verif[$atype]}\$"
            return 1
          fi
        done
      fi
      # Verify optional requirements
      local optvar="${sub}_OPTIONS"
      if [[ ! -z "${!optvar}" ]]
      then
        for option in ${!optvar}
        do
          local name=${option%%:*}
          local atype=${option##*:}
          local valname="ARG_${name^^}"
          if [[ ! -z "${!valname}" ]] && [[ ! "${!valname}" =~ ^${verif[$atype]}$ ]]
          then
            echo "Argument does not follow verification requirements: $atype:::${verif[$atype]}\$"
            return 1
          fi
        done
      fi
    else
      echo "Unknown subcommand: $TASK_SUBCOMMAND"
      echo Available subcommands: $SUBCOMMANDS
      return 1
    fi
  fi
  return 0

}

parse_args_for_task() {
  # All arguments after the command will be parsed into environment variables
  # load argument specification
  type arguments_$TASK_COMMAND &> /dev/null 
  if [[ "$?" == "0" ]]
  then
    arguments_$TASK_COMMAND
  fi
  if [[ -z "$SPEC_REQUIREMENT_NAME" ]]
  then
    local SPEC_REQUIREMENT_NAME=${TASK_COMMAND^^}_REQUIREMENTS
    local SPEC_OPTION_NAME=${TASK_COMMAND^^}_OPTIONS
    local requirements="${!SPEC_REQUIREMENT_NAME} ${!SPEC_OPTION_NAME}"
  fi
  #check if there are more than one specified arg and add the first ones to the end
  unset ADDED_ARGS
  shift
  while [[ $# != "0" ]]
  do
    ARGUMENT="$1"
    if [[ $ARGUMENT =~ ^\-[A-Za-z]{2,}$ ]]
    then
      local separated=$(echo "$ARGUMENT" | awk '{ match($1,"-[A-Za-z]{2,}", a); split(a[0], b, "") ; j="" ; s = " -" ; for(i=2;i in b; i++) { j = j s b[i] ; } print j }')
      # grab the last character as this argument
      ARGUMENT="-${separated:${#separated}-1:1}"
      # add added args
      local ADDED_ARGS="$ADDED_ARGS ${separated%-[[:alpha:]]}"
    fi
    #ignore any whitespace arguments
    if [[ -z "$ARGUMENT" ]]
    then
      shift
      ARGUMENT="$1"
    fi
    #Translate shortend arg
    if [[ "$ARGUMENT" =~ ^-[A-Za-z]$ ]]
    then
      local spec=$(sed "s/[A-Za-z_]*:[^${ARGUMENT#-}]:[a-z]*//g" <<< "$requirements" |tr -d '[[:space:]]' )
      local long_arg="${spec%%:*}"
      if [[ -z "$long_arg" ]]
      then
        echo "Unknown argument: $ARGUMENT"
        return 1
      fi
      ARGUMENT="--${long_arg,,}"
    fi
    if [[ "$ARGUMENT" =~ ^--[a-z]+$ ]]
    then
      local TRANSLATE_ARG="${ARGUMENT#--}"
      if [[ -z "$2" ]] || [[ "$2" =~ ^--[a-z]+$ ]] || [[ "$2" =~ ^-[[:alpha:]]$ ]] || [[ "${spec##*:}" == "bool" ]]
      then
        export ARG_${TRANSLATE_ARG^^}='1'
      else
        shift
        export ARG_${TRANSLATE_ARG^^}="$1"
      fi
    elif [[ "$ARGUMENT" =~ ^[a-z0-9_-]*$ ]] && [[ -z "$TASK_SUBCOMMAND" ]]
    then
      TASK_SUBCOMMAND="$ARGUMENT"
      SPEC_REQUIREMENT_NAME=${TASK_SUBCOMMAND^^}_REQUIREMENTS
      SPEC_OPTION_NAME=${TASK_SUBCOMMAND^^}_OPTIONS
      requirements="${requirements} ${!SPEC_REQUIREMENT_NAME} ${!SPEC_OPTION_NAME}"
    else
      echo "Unrecognized argument: $ARGUMENT"
      return 1
    fi
    shift
  done
  if [[ ! -z "$ADDED_ARGS" ]]
  then
    parse_args_for_task "GARBAGE" $ADDED_ARGS
  fi
}
