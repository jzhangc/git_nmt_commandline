#!/usr/bin/env bash
# Name: test.sh
# Discription: testrealm
echo -e "----test msg1----\n" >> ./r_msg_test.log
# out=`Rscript ./test.R \
# --save 2>>./r_msg_test.log \
# | tee -a ./msg_test.log`
out=`Rscript ./test.R \
--save 1>>./r_msg_test.log`
echo -e "\n" >> ./r_msg_test.log
echo -e "$out\n"

echo -e "----test msg2----\n" >> ./r_msg_test.log
# out=`Rscript ./test2.R \
# --save 2>>./r_msg_test.log \
# | tee -a ./msg_test.log`
out=`Rscript ./test2.R \
--save 1>>./r_msg_test.log`
echo -e "\n" >> ./r_msg_test.log