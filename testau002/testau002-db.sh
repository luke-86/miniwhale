#!/bin/bash

### Lukas' Script for Testing Testcase A/U-002 ###
for i in {1..10}; do
  echo -n "SELECT Query - Duration for Node $i in second in seconds: "
  /usr/local/mysql/bin/mysql -uroot -h127.0.0.1 -P200$i -proot_$i < testau002.sql | grep SELECT | awk {'print $2'} 
done
