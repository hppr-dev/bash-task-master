validate_args_for_task() {
  # Define available types
  declare -A verif
  local avail_types='str|varname|int|bool'
  local verif[str]='.*'
  local verif[varname]='[A-Z_\[\]]*'
  local verif[int]='[0-9]*'
  local verif[bool]='[01]'

  # Check if requirements exist
  type requirements_$TASK_COMMAND &> /dev/null 
  if [[ "$?" == "0" ]]
  then
    requirements_$TASK_COMMAND
    # check if subcommand exists or if there are no subcommands
    if [[ $TASK_SUBCOMMAND =~ ^$SUBCOMMANDS$ ]] || [[ -z "$SUBCOMMANDS" ]]
    then
      # handle subcommandless tasks
      local sub=${TASK_SUBCOMMAND^^}
      if [[ -z "$SUBCOMMANDS" ]]
      then
        sub=${TASK_COMMAND^^}
      fi
      # Check required arguments
      local reqvar="${sub}_REQUIREMENTS"
      if [[ ! -z "${!reqvar}" ]]
      then
        for requirement in ${!reqvar}
        do
          local name=${requirement%:*}
          local atype=${requirement##*:}
          echo "Checking $name:$atype"
          # Make sure that the argument exists
          local valname="ARG_$name"
          if [[ -z "${!valname}" ]]
          then
            echo "Missing required argument: --${name,,}"
            return 1
          fi
          # Make sure that the argument is the right type
          if [[ ! "${!valname}" =~ ^${verif[$atype]}$ ]]
          then
            echo "Argument does not follow verification requirements: $atype:::${verif[$atype]}\$"
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
          local name=${option%:*}
          local atype=${option##*:}
          local valname="ARG_$name"
          if [[ ! -z "${!valname}" ]] && [[ ! "${!valname}" =~ ^${verif[$atype]}$ ]]
          then
            echo "Argument does not follow verification requirements: $atype:::${verif[$atype]}\$"
            return 1
          fi
        done
      fi
    else
      echo $SUBCOMMANDS
      echo "Unknown subcommand: $TASK_SUBCOMMAND"
      return 1
    fi
  fi
  return 0

}

parse_args_for_task() {
  # All arguments after the command will be parsed into environment variables
  # Only long arguments can be used
  while [[ $# > 1 ]]
  do
    shift
    local ARGUMENT=$1
    if [[ $ARGUMENT =~ ^--[a-z]*$ ]]
    then
      local TRANSLATE_ARG=${ARGUMENT//-}
      if [[ -z "$2" ]] || [[ "$2" =~ ^--[a-z]$ ]]
      then
        export ARG_${TRANSLATE_ARG^^}='1'
      else
        shift
        export ARG_${TRANSLATE_ARG^^}="$1"
      fi
    elif [[ $ARGUMENT =~ ^[a-z]*$ ]] && [[ -z "$TASK_SUBCOMMAND" ]]
    then
      TASK_SUBCOMMAND=$ARGUMENT
    elif [[ $ARGUMENT =~ ^[a-z]*$ ]] && [[ ! -z "$TASK_SUBCOMMAND" ]]
    then
      echo "Only one subcommand is allowed"
      echo "Got $TASK_SUBCOMMAND as a subcommand, and also got $ARGUMENT"
      popd > /dev/null
      return
    else
      echo "Only long arguments are allowed"
      echo "Try using something like '--value value' that will be translated to \$ARG_VALUE=value in the task script."
      popd > /dev/null
      return
    fi
  done
}
