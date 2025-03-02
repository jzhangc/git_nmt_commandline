#!/usr/bin/env bash
# Name: test.sh
# Discription: testrealm
out=`Rscript ./R_files/test.R`
if [ "$out" == "fs_failure" ]; then
    echo -e "error msg!"
    exit 1
fi

