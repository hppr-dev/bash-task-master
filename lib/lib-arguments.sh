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
}

arguments_spawn(){
  SUBCOMMANDS='start|stop|kill|list|output|clean'

  START_DESCRIPTION='Start a background process'
  START_REQUIREMENTS='proc:p:str'
  START_OPTIONS='out:n:str'

  STOP_DESCRIPTION='Stop a backgroup process'
  STOP_REQUIREMENTS='num:n:int'
  KILL_DESCRIPTION=$STOP_DESCRIPTION
  KILL_REQUIREMENTS=$STOP_DESCRIPTION

  OUTPUT_DESCRIPTION='Show the output of a backgrounded process'
  OUTPUT_REQUIREMENTS='num:n:int'
  OUTPUT_OPTIONS='follow:f:bool'

  LIST_DESCRIPTION='List backgrounded processes'

  CLEAN_DESCRIPTION='Stop all backgrounded processes'
  
}

arguments_record() {
  SUBCOMMANDS='start|stop|restart|trash'

  START_DESCRIPTION="Start recording a named task and subtask with the given requirements and options"
  START_OPTIONS='name:n:str sub:s:str reqs:r:str opts:o:str'

  STOP_DESCRIPTION="Stop recording. Stop arguments will override start arguments if given"
  STOP_OPTIONS='name:n:str sub:s:str reqs:r:str opts:o:str'

  RESTART_DESCRIPTION="Restart current recording, discards current progress and starts from the beginning"

  TRASH_DESCRIPTION="Dicard the current recording."
  TRASH_OPTIONS='force:f:bool'
}

arguments_list() {
  LIST_DESCRIPTION="List available tasks"
  LIST_OPTIONS="global:g:bool local:l:bool all:a:bool"
}

arguments_init() {
  INIT_DESCRIPTION="Create a new local tasks location"
  INIT_OPTIONS="dir:d:str name:n:str clean:c:bool"
}

arguments_export() {
  EXPORT_DESCRIPTION="Export a task to a runnable bash script"
  EXPORT_REQUIREMENTS="command:c:str out:o:str"
}
