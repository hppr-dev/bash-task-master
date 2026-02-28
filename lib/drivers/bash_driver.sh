DRIVER_EXECUTE_TASK=execute_task
DRIVER_LIST_TASKS=bash_list
DRIVER_HELP_TASK=bash_help
DRIVER_VALIDATE_TASK_FILE=bash_validate_file

# Helpers for terse task definitions (available when tasks.sh is sourced)
task_spec() {
  local name="$1" desc="$2" req="${3:-}" opt="${4:-}"
  local n="${name^^}"
  n="${n//-/_}"
  declare -g "${n}_DESCRIPTION=$desc"
  [[ -n "$req" ]] && declare -g "${n}_REQUIREMENTS=$req"
  [[ -n "$opt" ]] && declare -g "${n}_OPTIONS=$opt"
}

has_arg() {
  [[ -n "${ARG_${1^^}}" ]]
}

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
      if ! [[ "$spec" =~ [[:alnum:]_-]+:[[:alnum:]]:[a-z]+ ]]
      then
        echo "Bad argument specification for $TASK_COMMAND: $spec." >&2
        return 1
      fi
    done
  fi

  unset ADDED_ARGS
  shift
  while [[ $# != "0" ]]
  do
    ARGUMENT="$1"
    if [[ $ARGUMENT =~ ^\-[[:alnum:]]{2,}$ ]]
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
    if [[ "$ARGUMENT" =~ ^-[[:alnum:]]$ ]]
    then
      # shellcheck disable=SC2001
      spec=$(sed "s/[[[:alnum:]_-]*:[^${ARGUMENT#-}]:[a-z]*//g" <<< "$requirements" | tr -d '[:space:]' )
      local long_arg="${spec%%:*}"
      if [[ -z "$long_arg" ]] || [[ ! "$spec" =~ ^[a-z_-]+:[[:alnum:]]:[a-z]+$ ]]
      then
        echo "Unrecognized short argument: $ARGUMENT" >&2
        return 1
      fi
      ARGUMENT="--${long_arg,,}"
    fi
    # shellcheck disable=SC2001
    spec=$(sed "s/.*\(${ARGUMENT#--}:[[:alnum:]]:[a-z]*\).*/\1/g" <<< "$requirements" |tr -d '[:space:]' )
    if [[ "$ARGUMENT" =~ ^--[[:alnum:]_-]+$ ]]
    then
      local TRANSLATE_ARG="${ARGUMENT#--}"
      TRANSLATE_ARG=${TRANSLATE_ARG//-/_}
      if [[ -z "$2" ]] || [[ "$2" =~ ^--[[:alnum:]_-]+$ ]] || [[ "$2" =~ ^-[[:alnum:]]$ ]] || [[ "${spec##*:}" == "bool" ]]
      then
        export "ARG_${TRANSLATE_ARG^^}=1"
      else
        shift
        export "ARG_${TRANSLATE_ARG^^}=$1"
      fi
    elif [[ "$ARGUMENT" =~ ^[[:alnum:]_-]*$ ]] && [[ -z "$TASK_SUBCOMMAND" ]]
    then
      TASK_SUBCOMMAND="${ARGUMENT//-/_}"
      SPEC_REQUIREMENT_NAME=${TASK_SUBCOMMAND^^}_REQUIREMENTS
      SPEC_OPTION_NAME=${TASK_SUBCOMMAND^^}_OPTIONS
      requirements="${requirements} ${!SPEC_REQUIREMENT_NAME} ${!SPEC_OPTION_NAME}"
    else
      echo "Unrecognized value: $ARGUMENT" >&2
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
  local verif[str]='^.*$'
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
            echo "Missing required argument: --${name,,}" >&2
            return 1
          fi
          # Make sure that the argument is the right type
          if [[ ! "${!valname}" =~ ${verif[$atype]} ]]
          then
            echo "--${name,,} argument does not follow verification requirements: $atype:::${verif[$atype]}" >&2
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
            echo "Argument does not follow verification requirements: $name=${!valname} $atype:::${verif[$atype]}" >&2
            return 1
          fi
        done
      fi
    else
      if [[ -n "$SUBCOMMANDS" ]]
      then
        echo "Unknown subcommand: $TASK_SUBCOMMAND" >&2
        echo "Available subcommands: $SUBCOMMANDS" >&2
        return 1
      fi
    fi
  fi
  return 0
}

_bash_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

_bash_help_arg_to_json() {
  local spec="$1"
  local longname="${spec%%:*}"
  local rest="${spec#*:}"
  local short="${rest%%:*}"
  local type="${rest#*:}"
  local long="--${longname}"
  local short_opt="-${short}"
  printf '{"long":"%s","short":"%s","type":"%s"}' "$(_bash_json_escape "$long")" "$(_bash_json_escape "$short_opt")" "$(_bash_json_escape "$type")"
}

_bash_help_emit_json() {
  local reqname="$1"
  local optname="$2"
  local descname="$3"
  local desc_val="${!descname}"
  local first=1
  printf '%s' '{"description":"'
  _bash_json_escape "${desc_val:-}"
  printf '%s' '","required":['
  for req in ${!reqname}
  do
    [[ $first -eq 1 ]] || printf '%s' ','
    _bash_help_arg_to_json "$req"
    first=0
  done
  first=1
  printf '%s' '],"optional":['
  for opt in ${!optname}
  do
    [[ $first -eq 1 ]] || printf '%s' ','
    _bash_help_arg_to_json "$opt"
    first=0
  done
  printf '%s' '],"subcommands":['
  first=1
  for sub_orig in ${SUBCOMMANDS//\|/ }
  do
    [[ $first -eq 1 ]] || printf '%s' ','
    sub_norm="${sub_orig//-/_}"
    reqname_sub="${sub_norm^^}_REQUIREMENTS"
    optname_sub="${sub_norm^^}_OPTIONS"
    descname_sub="${sub_norm^^}_DESCRIPTION"
    desc_sub="${!descname_sub}"
    printf '%s' '{"name":"'
    _bash_json_escape "$sub_orig"
    printf '%s' '","description":"'
    _bash_json_escape "${desc_sub:-}"
    printf '%s' '","required":['
    local first_inner=1
    for req in ${!reqname_sub}
    do
      [[ $first_inner -eq 1 ]] || printf '%s' ','
      _bash_help_arg_to_json "$req"
      first_inner=0
    done
    printf '%s' '],"optional":['
    first_inner=1
    for opt in ${!optname_sub}
    do
      [[ $first_inner -eq 1 ]] || printf '%s' ','
      _bash_help_arg_to_json "$opt"
      first_inner=0
    done
    printf '%s' ']}'
    first=0
  done
  printf '%s\n' ']}'
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
      if [[ -n "$ARG_JSON" ]]
      then
        TASK_SUBCOMMAND=${TASK_SUBCOMMAND//-/_}
        reqname=${TASK_SUBCOMMAND^^}_REQUIREMENTS
        optname=${TASK_SUBCOMMAND^^}_OPTIONS
        descname=${TASK_SUBCOMMAND^^}_DESCRIPTION
        _bash_help_emit_json "$reqname" "$optname" "$descname"
        return 0
      fi
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
      if [[ -n "$ARG_JSON" ]]
      then
        echo '{"description":"","required":[],"optional":[],"subcommands":[]}'
      else
        echo "No arguments are defined"
      fi
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
  if [[ -n "$TASK_FILE_FOUND" ]] && [[ "$TASK_FILE_DRIVER" == "bash" ]]
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

  echo "Running $TASK_COMMAND:$TASK_SUBCOMMAND task..." >&2
  "task_$TASK_COMMAND"
}

bash_validate_file() {
  bash -n "$1"
}


readonly -f task_spec
readonly -f has_arg
readonly -f bash_parse
readonly -f bash_validate
readonly -f _bash_json_escape
readonly -f _bash_help_arg_to_json
readonly -f _bash_help_emit_json
readonly -f bash_help
readonly -f bash_list
readonly -f execute_task
readonly -f bash_validate_file
