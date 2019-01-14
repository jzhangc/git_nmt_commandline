#!/usr/bin/env bash
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

IFLAG=1 # initiate mandatory variable check variable. initial value 1 (false)
AFLAG=1 # initiate mandatory variable check variable. initial value 1 (false)
CORES=1  # initiate CPU core number as 1

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
    while getopts ":ti:p:" opt; do
  		case $opt in
  			t)  # flag to change U to T for reference files
  				U2T=0
  				;;
  			i)
  				RAW_FILES=$OPTARG
  				IFLAG=0
  				;;
  			p)
  				CORES=$OPTARG
  				;;
  			:)
  				echo "Option -$OPTARG requires an argument." >&2
  				exit 1
  				;;
  			*)  # if the input option not defined
  				echo ""
  				echo "Invalid option: -$OPTARG" >&2
  				echo -e $HELP
  				echo -e "=========================================================================="
  				echo -e $CITE
  				exit 1
  				;;
  		esac
  	done
fi

# below: esssetial flag check
if [[ $IFLAG -eq 1 || $AFLAG -eq 1 || $MFLAG -eq 1 ||$NFLAG -eq 1 || $SFLAG -eq 1 ]]; then
	echo -e "ERROR: -i, -a. Use -h or --help to see help info.\n" >&2
	exit 1
fi

# ------ config file check -------
# application variables from config file
# and their default settings if no config file
if [ -f ./connectivity_ml_config ]; then  # variables read from the configeration file
  source connectivity_ml_config
  ## below: to check the completeness of the file: the variables will only load if all the variables are present
  # -z tests if the variable has zero length. returns True if zero.
  # v1, v2, etc are placeholders for now
  if [[ -z $v1 || -z $v2 || -z $v3 || -z $v4 ]]; then
    CONFIG_MSG="Config file detected. But one or more vairables missing.\n\tProceed with default settings."
    # set the values back to default
    # v1=
    # v2= etc
  else
    CONFIG_MSG="Config file detected and loaded."
  fi
else
  CONFIG_MSG="Config file not detected. Proceed with default settings."
  # set the values back to default
  # v1=
  # v2= etc
fi

# ------ functions ------
# function to check dependencies
