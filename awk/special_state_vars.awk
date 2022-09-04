#!/bin/awk -f
/^TASK_RETURN_DIR/    { print "cd " $2 }
/^TASK_TERM_TRAP/     { print "trap " $2 " EXIT" }
/^DESTROY_STATE_FILE/ { print "rm $STATE_FILE" }
0
