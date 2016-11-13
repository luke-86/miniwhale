#!/bin/bash

### Lukas' Script for Testing Testcase A/U-002 ###
for i in {1..10}; do
  /usr/local/mysql/bin/mysql -uroot -h127.0.0.1 -P200$i -proot_$i < testau002.sql    
done
