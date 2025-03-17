#!/usr/bin/env bash
# Name: test.sh
# Discription: testrealm
echo -e "----test msg1----\n" >> ./data/r_msg_test.log
# out=`Rscript ./test.R \
# --save 2>>./r_msg_test.log \
# | tee -a ./msg_test.log`
out=`Rscript ./R_files/test.R \
--save 1>>./data/r_msg_test.log`
echo -e "\n" >> ./data/r_msg_test.log
echo -e "$out\n"

echo -e "----test msg2----\n" >> ./data/r_msg_test.log
# out=`Rscript ./test2.R \
# --save 2>>./r_msg_test.log \
# | tee -a ./msg_test.log`
out=`Rscript ./R_files/test2.R \
--save 1>>./data/r_msg_test.log`
echo -e "\n" >> ./data/r_msg_test.log