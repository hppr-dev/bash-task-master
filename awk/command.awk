#!/bin/awk -f
BEGIN { 
  name_reg="^task_"name"().*$" 
}
 $0 ~ name_reg {
  head=1
  closed=0
} 
 /^}$/ {
  if(changed == 0 && head == 1) {
    print code
    changed=1
  }
  head=0
  closed=1
} 
1

END {
  if(changed == 0) {
    print "task_"name"() {"
    print code
    print "}"
  }
}
