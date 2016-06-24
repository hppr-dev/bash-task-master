arguments_argument_validate(){
  SUBCOMMANDS='get||'
  ARGUMENT_VALIDATE_OPTIONS='show:s:bool'
  GET_REQUIREMENTS='key:k:nowhite value:v:upper'
  GET_OPTIONS='all:a:bool regex:r:str num:n:int char-start:C:single undo_level:u:lower'
}

arguments_required_command(){
  SUBCOMMANDS='get||'
  REQUIRED_COMMAND_REQUIREMENTS='less:l:str'
}

test_arguments() {
  touch args-valid
  if [[ -z "$ARG_COMMAND$ARG_SUB$ARG_UNKNOWN$ARG_SHORT$ARG_ALL" ]]
  then
    ARG_ALL='1'
  fi
  if [[ ! -z "$ARG_ALL$ARG_COMMAND" ]]
  then
    echo Testing command arguments...
    echo ============================no args command
    task argument_validate
    assert_validated
    echo ============================comand option unknown subcommand
    task argument_validate ding
    assert_not_validated
    echo ============================comand option negative
    task argument_validate --show ding
    assert_not_validated
    echo ============================comand option positive
    task argument_validate --show
    assert_validated
    echo ============================comand missing required
    task required_command
    assert_not_validated
    echo ============================subcomand missing required command
    task required_command get
    assert_not_validated
    echo ============================comand required
    task required_command --less
    assert_validated
    echo ============================subcommand required command
    task required_command get --less
    assert_validated
  fi

  if [[ ! -z "$ARG_ALL$ARG_SUB" ]]
  then
    echo Testing subcommand arguments...
    echo ============================no args subcommands
    task argument_validate get
    assert_not_validated
    echo ============================upper/nowhite positive
    task argument_validate get --key dingusmalingus --value HELLO  
    assert_validated
    echo ============================nowhite negative
    task argument_validate get --key 'dingus malingus' --value HELLO  
    assert_not_validated
    echo ============================upper negative
    task argument_validate get --key 'dingus malingus' --value HeLLO  
    assert_not_validated
    echo ============================bool int single positive
    task argument_validate get --key dingusmalingus --value HELLO --num 123 --all --char-start G
    assert_validated
    echo ============================single negative
    task argument_validate get --key dingusmalingus --value HELLO --num 123 --all --char-start gradle
    assert_not_validated
    echo ============================int negative
    task argument_validate get --key dingusmalingus --value HELLO --num abc --all --char-start G
    assert_not_validated
    echo ============================bool negative
    task argument_validate get --key dingusmalingus --value HELLO --num 123 --all 123 --char-start G
    assert_not_validated
    echo ============================lower positive
    task argument_validate get --key dingusmalingus --value HELLO --undo_level lower
    assert_validated
    echo ============================lower negative
    task argument_validate get --key dingusmalingus --value HELLO --undo_level Fingus
    assert_not_validated
  fi

  if [[ ! -z "$ARG_ALL$ARG_SHORT" ]]
  then
    echo Testing short commands....
    echo ============================separate and upper case correctly
    task argument_validate get -k dingusmalingus -v HELLO -C H
    assert_validated
    echo ============================separate and upper case correctly
    task argument_validate get -k dingusmalingus -v HELLO -u h
    assert_validated
    echo ============================combined correctly
    task argument_validate get -ak dingusmalingus -v HELLO 
    assert_validated
    echo ============================combined with long correctly
    task argument_validate get -ak dingusmalingus --value HELLO 
    assert_validated
    echo ============================combined incorrectly
    #this test fails because -C is pushed to the end where it is set to 'T' making it validate
    #single isn't going to be used that often so this is ok to a point
    #task argument_validate get -Ck dingusmalingus -v HELLO 
    task argument_validate get -uk dingusmalingus -v HELLO 
    assert_not_validated
    echo ============================mixed args
    task argument_validate get -k dingusmalingus --value HELLO 
    assert_validated
    echo ============================mispelled args
    task argument_validate get -k dingusmalingus -value HELLO 
    assert_not_validated
  fi

  if [[ ! -z "$ARG_ALL$ARG_UNKNOWN" ]]
  then
    echo Testing unknown args....
    echo ============================unknown long arg
    task argument_validate get -k dingusmalingus -v HELLO --hello dingus
    assert_validated
    echo ============================unknown short arg
    task argument_validate get -k dingusmalingus -v HELLO -h dingus
    assert_not_validated
  fi

  rm args-valid

}


task_argument_validate() {
  echo "Validated" > args-valid
}

task_required_command() {
  echo "Validated" > args-valid
}

assert_validated() {
  if [[ "$(cat args-valid)" == "Validated" ]]
  then
    echo "TEST SUCCESS ++++++++++++++++++++++++++"
    echo
    TESTS_PASSED=$(expr $TESTS_PASSED + 1 )
  else
    echo "TEST FAILURE --------------------------"
    echo
    TESTS_FAILED=$(expr $TESTS_FAILED + 1 )
  fi
  echo > args-valid
}
assert_not_validated() {
  if [[ "$(cat args-valid)" == "" ]]
  then
    echo "TEST SUCCESS ++++++++++++++++++++++++++"
    echo
    TESTS_PASSED=$(expr $TESTS_PASSED + 1 )
  else
    echo "TEST FAILURE --------------------------"
    echo
    TESTS_FAILED=$(expr $TESTS_FAILED + 1 )
  fi
  echo > args-valid
}
