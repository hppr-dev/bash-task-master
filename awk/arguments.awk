#!/bin/awk -f
BEGIN { 
  name_reg="^arguments_"name"().*$" 
  key_reg="^  "key"=.*$" 
}
 $0 ~ name_reg {
  head=1
  closed=0
} 
 /^}$/ {
  if(changed == 0 && head == 1) {
    print "  "key"=\""value"\""
    changed=1
  }
  head=0
  closed=1
} 
 $0 ~ key_reg {
  if(head == 1 && closed == 0) {
    print "  "key"=\""value"\""
    changed=1
    next
  }
}
1

END {
  if(changed == 0) {
    print "arguments_"name"() {"
    print "  "key"=\""value"\""
    print "}"
  }
}
