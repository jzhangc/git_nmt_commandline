#!/usr/bin/env bash
# Name: test.sh
# Discription: testrealm
echo -e "----test msg1----\n" >> ./data/msg_test.log
out=`Rscript ./R_files/test.R \
--save 2>>./data/r_msg_test.log \
| tee -a ./data/msg_test.log`
echo -e "\n" >> ./data/r_msg_test.log

echo -e "----test msg2----\n" >> ./data/msg_test.log
out=`Rscript ./R_files/test2.R \
--save 2>>./data/r_msg_test.log \
| tee -a ./data/msg_test.log`


