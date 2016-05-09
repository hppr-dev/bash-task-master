
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
  task init
```

This will create a tasks.sh file in your current directory.

Start by recording a task:

```
  $task record start --name hello-world
  Starting recording
  $echo "Hello World!!"
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

The task command itself doesn't have any command line arguments, but created tasks can use long arguments to retrieve data.
Arguments are parsed and passed to the task as ARG_NAME.
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
  $task echo --msg "Hello!!!!"
  Hello!!!!
  Hello!!!!
  Hello!!!!
  ...
```

Arguments without specified values are set to `'1'`.


Validating Command Line Arguments
================================

To validate command line arguments simply create an arguments specification like so:

```

  arguments_build() {
    SUBCOMMANDS="help|frontend|backend|all"
    FRONTEND_REQUIREMENTS="OUT:str IN:str"
    BACKEND_REQUIREMENTS="PID:int"
    FRONTEND_OPTIONS="VERBOSE:bool LINT:bool DIR:str"
  }

```

Which would allow all of the following to run:

```

  $task build frontend --out outdir --in infile
  $task build frontend --out outdir --in infile --lint --verbose
  $task build all
  $task build backend --pid 123

```

But none of the following to run:

```

  $task build frontend 
  $task build frontend --in infile --lint --verbose
  $task build backend --pid 12 --verbose garbage

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
    if [[ $ARG_SUBCOMMAND == "set" ]]
    then
      hold_var "PS1"
      export_var "PS1" "(tester)"
    elif [[ $ARG_SUBCOMMAND == "unset" ]]
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

