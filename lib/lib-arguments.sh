arguments_global() {
  SUBCOMMANDS='debug|set|unset|edit|clean|locations|uuid'

  SET_DESCRIPTION="Set a variable for a command"
  SET_REQUIREMENTS='key:k:str value:v:str command:c:str'

  UNSET_DESCRIPTION="Unset a variable for a command"
  UNSET_REQUIREMENTS='key:k:str command:c:str'

  EDIT_DESCRIPTION="Edit a command's variables"
  EDIT_REQUIREMENTS='command:c:str'

  DEBUG_DESCRIPTION="Show variables for a command"
  DEBUG_OPTIONS='command:c:str'

  LOCATIONS_DESCRIPTION="Manage locations"
  LOCATIONS_OPTIONS='list:l:bool del:d:str add:a:str'

  UUID_DESCRIPTION="Check UUIDs"
  UUID_OPTIONS='uuid:u:str update:U:bool check:c:bool'

  CLEAN_DESCRIPTION="Clean up stale location and state files."
}

arguments_list() {
  LIST_DESCRIPTION="List available tasks"
  LIST_OPTIONS="global:g:bool local:l:bool all:a:bool"
}

arguments_init() {
  INIT_DESCRIPTION="Create a new local tasks location"
  INIT_OPTIONS="dir:d:str name:n:str hidden:h:bool"
}

arguments_bookmark() {
  SUBCOMMANDS='|rm|list'
  BOOKMARK_DESCRIPTION="Add a bookmark to the current location."
  BOOKMARK_OPTIONS="dir:d:str name:n:str"
  RM_DESCRIPTION="Remove a bookmark"
  LIST_DESCRIPTION="List available bookmarks"
}

arguments_export() {
  EXPORT_DESCRIPTION="Export a task to a runnable bash script"
  EXPORT_REQUIREMENTS="command:c:str out:o:str"
}
