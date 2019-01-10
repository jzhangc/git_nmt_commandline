#!usr/#!/usr/bin/env bash
# Name: connectivity_ml.sh
# Version: 0.0.1
# Discription: A shell script application for automated machine learning analysis for MEG connectivity data
# Usage: TBD
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# ------ Version History ------
# 0.0.1 script initiation

# ------ variables ------
# iniitate internal system variables
VERSION="0.0.1"

HELP="\n
TBD\n"

CITE="\n
Written by Jing Zhang PhD\n
Contact: jing.zhang@sickkids.ca, jzhangcad@gmail.com\n
To cite in your research: TBA\n"

PLATFORM="Unknown UNIX or UNIX-like system"
UNAMESTR=`uname`  # use uname variable to identify OS
if [ $UNAMESTR == "Darwin" ]; then
  PLATFORM="macOS"
elif [ $UNAMESTR == "Linux" ]; then
  PLATFORM="Linux"
fi

# initate flag check variables

# initate application variable from command flags

# flag check and set/rest application
if [ $# -eq 0 ]; then
  echo -e $HELP
  echo -e "\n"
  echo -e "==================================================================="
  echo -e $CITE
  exit 0
else
  case "$1" in
    -h|--help)
      echo -e $HELP
      echo -e "\n"
      echo -e "==================================================================="
      echo -e $CITE
      exit 0
      ;;
   --version)
      echo -e "Current version: $VERSION\n"
      exit 0
      ;;
    esac
fi
