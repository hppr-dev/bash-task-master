DRIVER_EXECUTE_TASK=execute_task
DRIVER_LIST_TASKS=bash_list
DRIVER_HELP_TASK=bash_help
DRIVER_VALIDATE_TASK_FILE=bash_validate_file

bash_parse() {
  # All arguments after the command will be parsed into environment variables
  # load argument specification
  if type -t "arguments_$TASK_COMMAND" &> /dev/null
  then
    "arguments_$TASK_COMMAND"
  fi

  local spec separated

  if [[ -z "$SPEC_REQUIREMENT_NAME" ]]
  then
    local SPEC_REQUIREMENT_NAME=${TASK_COMMAND^^}_REQUIREMENTS
    local SPEC_OPTION_NAME=${TASK_COMMAND^^}_OPTIONS
    local requirements="${!SPEC_REQUIREMENT_NAME} ${!SPEC_OPTION_NAME}"
    for spec in $requirements
    do
      if ! [[ "$spec" =~ [a-Z0-9_-]+:[a-Z0-9]:[a-z]+ ]]
      then
        echo "Bad argument specification for $TASK_COMMAND: $spec."
        return 1
      fi
    done
  fi

  unset ADDED_ARGS
  shift
  while [[ $# != "0" ]]
  do
    ARGUMENT="$1"
    if [[ $ARGUMENT =~ ^\-[A-Za-z]{2,}$ ]]
    then
      # Separate -ilt to -i -l -t
      # shellcheck disable=SC2001
      separated=$(echo "${ARGUMENT#-}" | sed 's/./ -&/g')
      # grab the last character as this argument
      ARGUMENT="-${separated:${#separated}-1:1}"
      # add added args
      local ADDED_ARGS="$ADDED_ARGS ${separated%-[[:alpha:]]}"
    fi
    #Translate shortend arg
    if [[ "$ARGUMENT" =~ ^-[A-Za-z]$ ]]
    then
      # shellcheck disable=SC2001
      spec=$(sed "s/[A-Za-z_-]*:[^${ARGUMENT#-}]:[a-z]*//g" <<< "$requirements" | tr -d '[:space:]' )
      local long_arg="${spec%%:*}"
      if [[ -z "$long_arg" ]] || [[ ! "$spec" =~ ^[a-z_-]+:[A-Za-z]:[a-z]+$ ]]
      then
        echo "Unrecognized short argument: $ARGUMENT"
        return 1
      fi
      ARGUMENT="--${long_arg,,}"
    fi
    # shellcheck disable=SC2001
    spec=$(sed "s/.*\(${ARGUMENT#--}:[A-Za-z]:[a-z]*\).*/\1/g" <<< "$requirements" |tr -d '[:space:]' )
    if [[ "$ARGUMENT" =~ ^--[a-z_-]+$ ]]
    then
      local TRANSLATE_ARG="${ARGUMENT#--}"
      TRANSLATE_ARG=${TRANSLATE_ARG//-/_}
      if [[ -z "$2" ]] || [[ "$2" =~ ^--[a-z_-]+$ ]] || [[ "$2" =~ ^-[[:alpha:]]$ ]] || [[ "${spec##*:}" == "bool" ]]
      then
        export "ARG_${TRANSLATE_ARG^^}=1"
      else
        shift
        export "ARG_${TRANSLATE_ARG^^}=$1"
      fi
    elif [[ "$ARGUMENT" =~ ^[a-z0-9_-]*$ ]] && [[ -z "$TASK_SUBCOMMAND" ]]
    then
      TASK_SUBCOMMAND="$ARGUMENT"
      SPEC_REQUIREMENT_NAME=${TASK_SUBCOMMAND^^}_REQUIREMENTS
      SPEC_OPTION_NAME=${TASK_SUBCOMMAND^^}_OPTIONS
      requirements="${requirements} ${!SPEC_REQUIREMENT_NAME} ${!SPEC_OPTION_NAME}"
    else
      echo "Unrecognized value: $ARGUMENT"
      return 1
    fi
    shift
  done
  if [[ -n "$ADDED_ARGS" ]]
  then
    # shellcheck disable=SC2086
    bash_parse "GARBAGE" $ADDED_ARGS
  fi
}

bash_validate() {
  # Define available types
  declare -A verif
  local avail_types='str|int|bool|nowhite|upper|lower|single|ip'
  local verif[str]='^[^1].*$'
  local verif[int]='^[0-9]+$'
  local verif[bool]='^1$'
  local verif[nowhite]='^[^[:space:]]+$'
  local verif[upper]='^[A-Z]+$'
  local verif[lower]='^[a-z]+$'
  local verif[single]="^.{1}$"
  local verif[ip]="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
  local SUBCOMMANDS=""

  # Check if argument specifications exist
  if type -t "arguments_$TASK_COMMAND" &> /dev/null
  then
    "arguments_$TASK_COMMAND"
    # check if subcommand exists
    if [[ $TASK_SUBCOMMAND =~ ^($SUBCOMMANDS)$ ]]
    then
      local sub=${TASK_SUBCOMMAND^^}
      # handle subcommandless tasks
      if [[ -z "$sub" ]]
      then
        sub=${TASK_COMMAND^^}
      fi
      # Check required arguments
      local reqvar_sub="${sub}_REQUIREMENTS"
      if [[ -n "${!reqvar_sub}" ]]
      then
        for requirement in ${!reqvar_sub}
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
          if [[ ! "${!valname}" =~ ${verif[$atype]} ]]
          then
            echo "--${name,,} argument does not follow verification requirements: $atype:::${verif[$atype]}"
            return 1
          fi
        done
      fi
      # Verify optional requirements
      local optvar="${sub}_OPTIONS"
      if [[ -n "${!optvar}" ]]
      then
        for option in ${!optvar}
        do
          local name=${option%%:*}
          name=${name//-/_}
          local atype=${option##*:}
          local valname="ARG_${name^^}"
          if [[ -n "${!valname}" ]] && [[ ! "${!valname}" =~ ${verif[$atype]} ]]
          then
            echo "Argument does not follow verification requirements: $name=${!valname} $atype:::${verif[$atype]}"
            return 1
          fi
        done
      fi
    else
      echo "Unknown subcommand: $TASK_SUBCOMMAND"
      echo "Available subcommands: $SUBCOMMANDS"
      return 1
    fi
  fi
  return 0
}

bash_help() {
  if [[ -n "$TASK_SUBCOMMAND" ]]
  then
    if type -t "arguments_$TASK_SUBCOMMAND" &> /dev/null
    then 
      "arguments_$TASK_SUBCOMMAND"
      reqname=${TASK_SUBCOMMAND^^}_REQUIREMENTS
      optname=${TASK_SUBCOMMAND^^}_OPTIONS
      descname=${TASK_SUBCOMMAND^^}_DESCRIPTION
      if [[ "${SUBCOMMANDS/\|\|/}" != "$SUBCOMMANDS" ]] || [[ -n "${!reqname}" ]] || [[ -n "${!optname}" ]] || [[ -n "${!descname}" ]]
      then
        echo "Command: task $TASK_SUBCOMMAND"
        TASK_SUBCOMMAND=${TASK_SUBCOMMAND//-/_}
        if [[ -n "${!descname}" ]]
        then
          echo "  ${!descname}"
        else
          echo "  No description available"
        fi
        if [[ -n "${!reqname}" ]]
        then
          echo "  Required:"
          for req in ${!reqname}
          do
            arg_spec=${req%:*}
            echo "    --${arg_spec%:*}, -${arg_spec#*:} ${req##*:}"
          done
        fi
        if [[ -n "${!optname}" ]]
        then
          echo "  Optional:"
          for opt in ${!optname}
          do
            arg_spec=${opt%:*}
            if [[ "${opt##*:}" == "bool" ]]
            then
              echo "    --${arg_spec%:*}, -${arg_spec#*:}"
            else
              echo "    --${arg_spec%:*}, -${arg_spec#*:} ${opt##*:}"
            fi
          done
        fi
        echo
      fi
      for sub in ${SUBCOMMANDS//\|/ }
      do 
        echo "Command: task $TASK_SUBCOMMAND $sub"
        sub=${sub//-/_}
        reqname=${sub^^}_REQUIREMENTS
        optname=${sub^^}_OPTIONS
        descname=${sub^^}_DESCRIPTION
        if [[ -n "${!descname}" ]]
        then
          echo "  ${!descname}"
        else
          echo "  No description available"
        fi
        if [[ -n "${!reqname}" ]]
        then
          echo "  Required:"
          for req in ${!reqname}
          do
            arg_spec=${req%:*}
            echo "    --${arg_spec%:*}, -${arg_spec#*:} ${req##*:}"
          done
        fi
        if [[ -n "${!optname}" ]]
        then
          echo "  Optional:"
          for opt in ${!optname}
          do
            arg_spec=${opt%:*}
            if [[ "${opt##*:}" == "bool" ]]
            then
              echo "    --${arg_spec%:*}, -${arg_spec#*:}"
            else
              echo "    --${arg_spec%:*}, -${arg_spec#*:} ${opt##*:}"
            fi
          done
        fi
        echo
      done
      
    else
      echo "No arguments are defined"
    fi
    return 0
  fi
  return 1
}

bash_list() {
  if [[ -f "$1" ]]
  then
    awk '/^task_.*(.*).*/ { print }' "$1" | sed 's/.*task_\(.*\)(.*).*/\1 /' | tr -d "\n"
  fi
}

execute_task() {
  #Load local tasks if the desired task isn't loaded
  if [[ -n "$TASK_FILE_FOUND" ]] 
  then
    _tmverbose_echo "Sourcing tasks file"
    source "$TASK_FILE"
  fi

  #Parse and validate arguments
  unset TASK_SUBCOMMAND
  # shellcheck disable=SC2068
  if ! bash_parse $@ || ! bash_validate
  then
    _tmverbose_echo "Parsing or validation of task args returned 1, exiting..."
    return 1 
  fi

  echo "Running $TASK_COMMAND:$TASK_SUBCOMMAND task..."
  "task_$TASK_COMMAND"
}

bash_validate_file() {
  bash -n "$1"
}


readonly -f bash_parse
readonly -f bash_validate
readonly -f bash_help
readonly -f bash_list
readonly -f execute_task
readonly -f bash_validate_file
