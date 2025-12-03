#!/usr/bin/env bash
# Name: sys_init_2d.sh
# Discription: system initiation with flag checks and dependency checks
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# ------ variables ------
# load utils and zzz config file
source ./src/utils
source ./src/global_var
source ./zzz

# ------ system check ------
# -- flag check --
if [[ $IFLAG -eq 1 || $SFLAG -eq 1 ||$GFLAG -eq 1 || $CFLAG -eq 1 ]]; then
	echo -e "${COLOUR_RED}ERROR: -i, -c flags are mandatory. Use -h or --help to see help info.${NO_COLOUR}\n" >&2
	exit 1
fi

if [[ $KFLAG -eq 0 && $UFLAG -eq 0 ]]; then
	echo -e "${COLOUR_RED}ERROR: Set either -u or -k, but not both.${NO_COLOUR}\n" >&2
	exit 1
fi

# --- Rscript check ---
echo -e "\n"
echo -e "R environment check"
echo -e "=========================================================================="
# -- R script chack --
check_dependency
echo -e "=========================================================================="


# --- system files check ---
echo -e "\n"
echo -e "System file check"
echo -e "=========================================================================="
# -- R script chack --
echo -e "Checking required R script file(s)"
required_file_check "${R_SCRIPT_FILES[@]}"
echo -e "=========================================================================="


# --- construct output folder structure ---
echo -e "\n"
echo -en "Copnstructing output file folder structure..."
[ -d "${OUT_DIR}"/LOG ] || mkdir "${OUT_DIR}"/LOG
[ -d "${OUT_DIR}"/OUTPUT ] || mkdir "${OUT_DIR}"/OUTPUT
# [ -d "${OUT_DIR}"/OUTPUT/RESULTS_FILES ] || mkdir "${OUT_DIR}"/OUTPUT/RESULTS_FILES
# [ -d "${OUT_DIR}"/OUTPUT/FIGURES ] || mkdir "${OUT_DIR}"/OUTPUT/FIGURES
echo -e "Done!"
echo -e "=========================================================================="
echo -e "Folders created and their usage:"
echo -e "\tLOG: Applcation log files"
echo -e "\tOUTPUT: Output files"
# echo -e "\tOUTPUT/RESULTS_FILES: None-figure resutls files"
# echo -e "\tOUTPUT/FIGURES: Figure files"
echo -e "=========================================================================="


# --- check R dependecies ---
echo -e "\n"
echo -e "Checking R pacakge dependecies"
echo -e "=========================================================================="
Rscript ./R_files/r_dependency_check.R 2>>"${OUT_DIR}"/LOG/R_check_R_$CURRENT_DAY.log | tee -a "${OUT_DIR}"/LOG/R_check_shell_$CURRENT_DAY.log
R_EXIT_STATUS=${PIPESTATUS[0]}  # PIPESTATUS[0] capture the exit status for the Rscript part of the command above
if [ $R_EXIT_STATUS -eq 1 ]; then  # test if the r_dependency_check.R failed with exit status 1 (stderr)
  echo -e "${COLOUR_RED}ERROR: R package dependency installation failure. Program terminated."
	echo -e "Please check the log files. ${NO_COLOUR}\n" >&2
  exit 1
fi
echo -e "=========================================================================="