
Bash Task Master
===================

Bash task master enhances bash by providing a way to centralize scripts for a single location with argument validation.

Features:

  - Centralized -- Tasks can be run in any folder under your home directory without adding them to your path

  - Validated Input -- Validate input without needing to write the bulky script

  - Scoped -- Depending on where it is being run, different tasks are loaded

  - Isolated -- Each task is run in a restricted subshell, meaning your environment variables aren't affected (unless you want them to be)

  - Preserved State -- Tasks can preserve state between subsequent runs

  - Reusable -- Reuse tasks and functions within tasks to make complex tasks more simple

Bash task master is a bash shortcut system that includes an argument parser.

Quick Start
=================
Run the install script to install the task command to your .bashrc.

Change directories to the root of your project directory and run:

```
  task init -n hello_world
```

This will create a tasks.sh file in your current directory.

Example Workflow
===================

```

  t goto pyproject             # Jump to pyproject directory
  t venv enable                # Activate the virtual env
  vim project.py               # Make changes to my project
  t test --only project.py     # Test my changes
  t docker deploy -v 1.2       # Deploy my changes to a docker image tagged 1.2
  t docker shell               # Open the shell to the docker container

  # Uhoh looks like the build failed for my other project

  t venv disable               # Disable the virtual environment
  t goto other                 # Jump to the other directory
  t test                       # run tests to show what I messed up
  vim other.rb                 # Fix the error

  # Now that that's fixed I want to start a new go project

  mkdir ~/goproj ; cd ~/goproj # Create the directory and move to it
  t init -n goproj             # Create a new tasks file
  t gonv init -v 1.15          # Initialize a go 1.15 environment
  t gonv enable                # Enable the go environment
  t edit                       # Edit the tasks file to add some useful tasks

```

Note t is an alias to task.
I prefer to use t becuase it saves keystrokes.

Editing task files
======================

Running `task edit` will open up the current task.sh file for editing.
This provides an extra layer of security as it checks the validity of the tasks file after writing.

Bookmarking
================
bash-task-master provides an easy way to move around your system.
Bookmarks can be used to denote places where you'd like to return to frequently.
A bookmark is automatically created when you init a task file.
Use `task goto BOOKMARK_NAME` to change directories to your bookmark.
For instance, from the quick start example run `task goto hello_world` to go to the directory where you ran `task init`.

Bookmarks can also be created without a tasks file initialized by using `task bookmark --name BOOKMARK_NAME`
For example, while developing bash-task-master I would frequently need to go back to the .task-master home directory.
I setup a bookmark by running `task bookmark --name tmhome` and any time I need to go back I run `task goto tmhome`.


Manually writing tasks
===========================

Manually writing tasks to local tasks.sh files is the prefered and recommended way to create tasks.

Two bash functions are used to define and describe the task:

  - the task definition -- what runs when you run `task TASK_NAME`
  - the task argument specification -- defines what subcommands and arguments are able to be used

When used in combination, this greatly simplifies writing and validating bash functions with arguments.
It also provides an easy way to create help strings, for when your memory fails you.

Writing Tasks
===========================

Tasks are written as bash functions with the `task_` prefix.
The following task would be named hello and it would print "foo bar" when run:

```
task_hello() {
  echo foo bar
}
```

After placing this in your tasks.sh file, run `task list` and you should see the hello task in the listed local tasks.

Using Command Line Arguments
============================

The task command itself doesn't have any command line arguments, but created tasks can use arguments to retrieve data.
Arguments are parsed and passed to the task as ARG_NAME. See the following section about defining short arguments.
For instance with a task definition like:

```
  task_echo() {
    echo "$ARG_MSG"
    echo "$ARG_MSG"
    echo "$ARG_MSG"
    echo "..."
  }
```

You may run:

```
  $task echo --msg 'Hello!!!!'
  Hello!!!!
  Hello!!!!
  Hello!!!!
  ...
```

Arguments without specified values are set to `'1'`.


Writing Command Line Argument Specifications
=============================================

To validate command line arguments and set short arguments simply create an arguments specification like so:

```

  arguments_build() {
    SUBCOMMANDS="help|frontend|backend|all"
    FRONTEND_REQUIREMENTS="out:o:str in:i:str"
    FRONTEND_OPTIONS="VERBOSE:v:bool LINT:L:bool DIR:d:str"
    BACKEND_REQUIREMENTS="PID:P:int"
    BACKEND_OPTIONS="VERBOSE:v:bool BUILD-FIRST:B:bool"
  }

```

Arguments specifications can include all (or none) of the following:

  - SUBCOMMANDS - a `|` delimited list of subcommands (frontend would be the subcommand in `task build frontend` from the example above)
  - <subcommand_name>_DESCRIPTION - help string for given subcommand
  - <subcommand_name>_REQUIREMENTS - required arguments for the given subcommand
  - <subcommand_name>_OPTIONS - arguments for the given subcommand
  - <command_name>_DESCRIPTION - help string for the command
  - <command_name>_REQUIREMENTS - required arguments for the command
  - <command_name>_OPTIONS - optional arguments for the command


REQUIREMENTS and OPTIONS are written as lists of space delimited argument specifications that are of the form: long-arg:short-arg:arg-type.
The long-arg of the argument specifies the flag to be used with `--` and also denotes the portion of the `ARG_` variable in the tasks.
The short-arg is the flag to be used with `-` (single dash).
The arg-type specifies what type the argument is. See below for available types.
For example, the specification `num:n:int` could be called with `--num 12`, `-n 12` and `$ARG_NUM` would hold the argument value.


Returning to the above example, all of the following would be valid calls the build task.

```

  $ task build frontend --out outdir --in infile
  $ task build frontend --out outdir --in infile --lint --verbose
  $ task build frontend -o outdir -i infile -L -v
  $ task build all
  $ task build backend --pid 123
  $ task build backend -P 123
  $ task build backend -vBP 123
  $ task build frontend -Lo outdir -vi infile

```

But none of the following would succeed:

```

  $ task build frontend 
  $ task build frontend --in infile --lint --verbose
  $ task build backend --pid 12 --verbose garbage
  $ task build backend -P 12 -v garbage

```

Supported Argument Types
==============================

Available types are as follows:

|  Type         | Identifier | Description |
|  ----         | ---------- | ----------- |
|  String       | str        | A string of characters, can pretty much be anything. |
|  Integer      | int        | An integer |
|  Boolean      | bool       | An argument that is either T if present or an empty string if not* |
|  Word         | nowhite    | A string with no whitespaces |
|  Uppercase    | upper      | An uppercase string |
|  Lowercase    | lower      | A lowercase string |
|  Single Char  | single     | A single character* |

All types, except for bool, require that a value is given.
With bool arguments, the argument being present automatically sets the ARG_VAR.
Note that short arguments can be combined to one combined argument, e.g -vBP, but only the last can be a non bool.

* A single character may be confused as a boolean at validation time.
If a value for a single character argument is left out, it will be set to "T"

Showing and Displaying Help
===========================

Given that a task and it's arguments have been fully specified in a ` arguments_TASK_NAME ` function, running ` task help TASK_NAME ` will show you the available options and requirements.
A description can be added to be more descriptive when this help is being displayed.
For example, from the last section, you could add:

```

  arguments_build() {
    SUBCOMMANDS="help|frontend|backend|all"
    FRONTEND_DESCRIPTION="Build the frontend system. --out is the thing and --in is the other thing"
    FRONTEND_REQUIREMENTS="OUT:o:str IN:i:str"
    FRONTEND_OPTIONS="VERBOSE:v:bool LINT:L:bool DIR:d:str"
    BACKEND_DESCRIPTION="Build the backend system."
    BACKEND_REQUIREMENTS="PID:P:int"
    BACKEND_OPTIONS="VERBOSE:v:bool BUILD-FIRST:B:bool"
  }

```


Saving State Between Runs
===========================

Each task potentially has a file in $TASK_MASTER_HOME/state/$TASK_NAME.vars to save state variables in.

To take advantage of this you may use in a task:

```
  persist_var "MY_VAR" "10"
```

The next time the same task is run $MY_VAR will be set to 10, but not in your outside environment.
This also sets the variable in the current task as well.
The variable will remain set until the following is called within a subtask of task:

```
  remove_var "MY_VAR"
```

If you need to use a variable outside of the task process run:

```
  export_var "SOME_VAR" "44"
```

If you need to save the current value of a variable use:

```
  hold_var "SOME_VAR"
```

which will save the current value of SOME_VAR until `release_var` is called:

```
  release_var "SOME_VAR"
```

which will reset and export the variable to it's previous value.

For example the following creates a task to change the value of PS1 to "(tester)":

```
  task_tester() {
    if [[ $TASK_SUBCOMMAND == "set" ]]
    then
      hold_var "PS1"
      export_var "PS1" "(tester)"
    elif [[ $TASK_SUBCOMMAND == "unset" ]]
    then
      release_var "PS1"
    fi
  }
```

Exporting Tasks to Scripts
==========================

Use `task export --command mycommand --out mycommand.sh` to create a bash script that takes the same arguments and does the same thing as the mycommand task.

Some caveats:

  - Requirements and options are parsed the same way in the exported script. Input is not validated and missing requirements are not required.

  - Only one level of function nesting is supported. Functions immediately inside of the task are expanded to include their contents, but no further.

Cleaning Up and Debugging
==========================

The global task gives you access to state variables that have been set.
Type `task global set -k MY_VAR -v 1234 -c my_task` to set MY_VAR=1234 in the state variables of my_task for your current local tasks.

Task Scoping
==========================

There are two main scopes:

  1. Global scope - when there is no tasks.sh file present

  2. Local scope - when a tasks.sh file is found in one of the parent directories from where you are running task

The global scope is just that: it contains tasks available from anywhere under your home directory.
Global built-in functions are marked read only when running tasks to make sure that they are not being overwritten.
Global state variables are store and communicated in the $TASK_MASTER_HOME/state directory


The local scope is defined by your current tasks file.
Each local scope stores it's state in it's  $TASK_MASTER_HOME/state/$LOCAL_TASKS_UUID directory.
This has the benifit of isolating which state variables are used when running tasks under seperate tasks locations.


Each tasks file should include it's UUID (AKA name) in the LOCAL_TASKS_UUID variable at the top of every tasks file.
Using `task init --name UUID` will set this up correctly.
If left unspecified, the UUID will default to the directory name (i.e. /home/me/proj would default to proj).
This value is used to specify where to place state variables.

Yaml Argument Format
============================

The yaml format can be used by setting `ARG_FORMAT=yaml` in your tasks.sh file and then including a yaml string under a ARGUMENTS variable like so:

```
ARGUMENTS="
---
  - my-command:
      description: command to do things
      subcomands: this,[his|hat]
      optional:
        - build:
            short: b
            type: bool
            description: set to build the thing
        - clean: c,bool,set to clean the thing
      this:
        required:
          - name: n,str,name of the thing
        optional:
          - ssh:
            short: s
            type: bool
            description: ssh to the thing
"
```
A few things to note:

There are two possible formats for arguments:

    - long format: short, type and description are specified as fields (as in the build argument above)
    - short format: short,type,description are implied as a string (as in the clean argument above)

The subcommands field may contain regexes or the exact subcommand string.

YAML format allows for descriptions on specific arguments, which the bash format does not.

Creating your own parsing and validation drivers
=================================================

UNIMPLEMENTED

Parsing and validation drivers are called from the lib/validate-args.sh script.
The following commands are required to be implemented by the driver:

```

CUSTOM_DRIVER arguments_file parse $ARGUMENTS
CUSTOM_DRIVER arguments_file validate $ARGUMENTS
CUSTOM_DRIVER arguments_file help $TASK_SUBCOMMAND

```

The first argument should be a file that holds the argument specification.
The second argument should be parse, validate, or help.
For parse and validate the rest of the arguments are the arguments that are being parsed or validated.
For help, the subcommand that is being queried is the last argument.

To enable the custom driver, add a value to the drivers dictionary in the validate-args.sh script in the form:

```
VP_DRIVERS[FORMAT_NAME]="driver_command"
```

Then to use the new format, set the ARG_FORMAT in your task file to the FORMAT_NAME above.
=======
Modules
===============

Modules are task files that are applied at the global level.
All modules that match `modules/*-modules.sh` are loaded with task master.
To disable a module, simply add `.disabled` to the module file.

Python Virtual Environment module
===================================

The venv module centralizes the creation of virtual environments created with virtualenv.
This makes it so that the path of your project no longer requires a venv directory in it and the virtual environment can be activated anywhere.
The virtual environment is instead created and managed in the task master state directories.

Initialize a virtualenv:

```
task venv init --name myvenv
```

Enable/activate a virtualenv:

```
task venv enable --name myvenv
```

Disable the active virtualenv:

```
task venv disable
```

Note that if you have initialized a task.sh file in a parent directory, the name argument can be ommitted and the tasks location name will be used.
For example, you have `/home/lelo/my-project/tasks.sh` with the name myproj, the venv task will automatically create/select the myproj venv when running `task venv init` or `task venv enable`.

Process management with the spawn module
===========================================

This is an experimental feature. More development and testing is needed.

The spawn module is available to create background processes.
Change the name of the `modules/spawn-module.sh.disabled` to `modules/spawn-module.sh` to enable it.

You may spawn background processes by running:

```
  $task spawn --proc "tailf /var/log/messages"
```

use task spawn list to list the running processes and task spawn stop to stop them

Recording a new task with the record module
==============================================

A recording module is available to easily record commands and put them into the local tasks file.
To enable the recording module, change the name of `modules/record-module.sh.disabled` to `modules/record-module.sh`

Start by recording a task:

```
  $ task record start --name hello-world
  Starting recording
  $ echo 'Hello World!!'
  Hello World!!
  $ task record stop
  Storing recording to tasks.sh
```

Now run your new script:
```
  $ task hello-world
  Hello World!!
```

Dependencies
============================

 - GNU Awk 4.1.3
 - GNU sed 4.2.2
 - GNU bash 4.3.42
 - VIM 7.4

Bash Task Master was tested using these versions. It is likely that it works on other versions as well. 
awk and sed must be able to take '-i inplace' (gawk > 4.1.0).
