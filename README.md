
Bash Task Master
===================

Manage tasks in bash by enhancing POBS (Plain Old Bash Scripting).

The bash task master provides the functionality to automate almost any command line process in a breeze.

Benifits over just POBS:

  - Centralized -- Tasks can be run in any folder under your home directory without adding them to the path

  - Isolated -- Each task is run in a restricted subshell, meaning your environment variables aren't affected (unless you want them to be)

  - State Preserved -- Tasks can preserve their state between runs and interact

  - Input Validated -- Validate input without needing to write script

  - Reusable -- Reuse tasks within tasks to make complex tasks more simple

  - Scoped -- Depending on where it is being run, different tasks can be loaded


Quick Start
=================
Run the install script to install the task command to your .bashrc.

Change directories to the root of your project directory and run:

```
  task init -n hello_world
```

This will create a tasks.sh file in your current directory.

Start by recording a task:

```
  $task record start --name hello-world
  Starting recording
  $echo 'Hello World!!'
  Hello World!!
  $task record stop
  Storing recording to tasks.sh
```

Now run your new script:
```
  $task hello-world
  Hello World!!
```

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


Validating Command Line Arguments
================================

To validate command line arguments and set short arguments simply create an arguments specification like so:

```

  arguments_build() {
    SUBCOMMANDS="help|frontend|backend|all"
    FRONTEND_REQUIREMENTS="OUT:o:str IN:i:str"
    BACKEND_REQUIREMENTS="PID:P:int"
    FRONTEND_OPTIONS="VERBOSE:v:bool LINT:L:bool DIR:d:str"
    BACKEND_OPTIONS="VERBOSE:v:bool BUILD-FIRST:B:bool"
  }

```

Which would allow all of the following to run:

```

  $task build frontend --out outdir --in infile
  $task build frontend --out outdir --in infile --lint --verbose
  $task build frontend -o outdir -i infile -L -v
  $task build all
  $task build backend --pid 123
  $task build backend -P 123
  $task build backend -vBP 123
  $task build frontend -Lo outdir -vi infile

```

But none of the following to run:

```

  $task build frontend 
  $task build frontend --in infile --lint --verbose
  $task build backend --pid 12 --verbose garbage
  $task build backend -P 12 -v garbage

```

Note that short arguments can be combined to one combined argument, e.g -vBP, but only the last can be a non bool.

AVailable types are as follows:

  Type         | Identifier | Description
  String       | str        | A string of characters, can pretty much be anything.
  Integer      | int        | An integer
  Boolean      | bool       | An argument that is either T if preset or an empty string if not*
  Word         | nowhite    | A string with no whitespaces
  Uppercase    | upper      | An uppercase string
  Lowercase    | lower      | A lowercase string
  Single Char  | single     | A single character*

* A single character may be confused as a boolean at validation time.
If a value for a single character argument is left out, it will be set to "T"

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

Process Management
==================

You may spawn background processes by running:

```
  $task spawn --proc "tailf /var/log/messages"
```

use task list to list the running processes and task stop to stop them

Exporting Tasks to Scripts
==========================

Sometimes you need a POBS. Use `task export --command mycommand --out mycommand.sh` to create a bash script with the contents of mycommand.

Recording Input
==================

An easy way to write a task is by using the record command:

```
  task record start --name my-task
  task record restart
  task record trash
  task record stop
```

Just start a recording by using `task record start --name taskname` and do what you want to do then `task record stop` to write it to your tasks file.
--name can be specified either at the start or stop.
The command automatically records where you start and navigate to so that the context of your commands is the same everytime.

Only one recording may be started for a given tasks file.
That being said, it is possible to record 2 tasks at once, as long as the recordings are going to separate tasks.sh files.


Jumping Between Locations
===========================

When you create a task file the file location is saved in $TASK_MASTER_HOME/state/locations.vars .
This is so that you may jump from local tasks locations quickly.
Say earlier you created a tasks file by running the command `task init --name work`.
You may return to this location from anywhere in your directory tree by typing `task goto work`
Locations can be listed by running `task global locations`, which will show your locations file.

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
If left unspecified, the UUID will be generated based on the number of locations in the locations.vars file.
This value is used to specify where to place state variables.
