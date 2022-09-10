# This file defines functions to interacte through the state files
# Any thing that is requested loads after the task is finished


#This function writes to the state file
#Used for when values are needed to be retained between runs
persist_var() {
  remove_file_value "$1" "$STATE_FILE"
  echo "$1=\"$2\"" >> "$STATE_FILE"
  eval "$1=\"$2\""
}

remove_var() {
  remove_file_value "$1" "$STATE_FILE"
}

# export a variable to the outside session
export_var(){
  remove_file_value "$1" "$STATE_FILE".export
  echo "export $1=\"$2\"" >> "$STATE_FILE".export
}

# hold the current value of a variable
hold_var() {
  remove_file_value "$1" "$STATE_FILE".hold
  echo "$1=\"${!1}\"" >> "$STATE_FILE".hold
}

# release a held value of a variable and export it back to the outside session
release_var() {
  if [[ -f $STATE_FILE.hold ]]
  then
    remove_file_value "$1" "$STATE_FILE".export
    grep -e "$1" "$STATE_FILE".hold >> "$STATE_FILE".export
    remove_file_value "$1" "$STATE_FILE".hold
  fi
}

set_trap() {
  persist_var TASK_TERM_TRAP "$1"
}

unset_trap() {
  remove_var TASK_TERM_TRAP
}

clean_up_state() {
  if [[ -f $STATE_FILE ]]
  then
    persist_var DESTROY_STATE_FILE 1
  fi
}

set_return_directory() {
  persist_var "TASK_RETURN_DIR" "$1"
}

load_state() {
  if [[ -f $STATE_FILE ]]
  then
      source "$STATE_FILE"
  fi
}

remove_file_value() {
  if [[ -f $2 ]]
  then
    awk "/^$1=/ { next } { print }" "$2" > "$2".tmp
    mv "$2".tmp "$2"
  fi
}


readonly -f persist_var
readonly -f remove_var
readonly -f export_var
readonly -f hold_var
readonly -f release_var
readonly -f set_trap
readonly -f unset_trap
readonly -f clean_up_state
readonly -f set_return_directory
readonly -f load_state
readonly -f remove_file_value
