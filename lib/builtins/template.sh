arguments_template() {
  SUBCOMMANDS="edit|list|rm"

  TEMPLATE_DESCRIPTION="Manage task file templates"

  EDIT_DESCRIPTION="Edit or create a template"
  EDIT_REQUIREMENTS="name:n:str"
  
  LIST_DESCRIPTION="List templates"
  
  RM_DESCRIPTION="Remove a template"
  RM_REQUIREMENTS="name:n:star"
}

task_template() {
  template_file="$TASK_MASTER_HOME/templates/$ARG_NAME.template"

  if [[ "$TASK_SUBCOMMAND" == "edit" ]]
  then
    $DEFAULT_EDITOR "$template_file"
  elif [[ "$TASK_SUBCOMMAND" == "rm" ]] 
  then
    if [[ ! -f "$template_file" ]]
    then
      echo "$ARG_NAME template does not exist."
      return 1
    fi
    echo "Removing $ARG_NAME template."
    rm "$template_file"
  else
    echo "Available templates:"
    find "$TASK_MASTER_HOME/templates"  -name '*.template' -exec basename {} \; | sed 's/\(.*\)\.template/    \1/' | tr -d '\n'
    echo
    echo
  fi
}

readonly -f arguments_template
readonly -f task_template
