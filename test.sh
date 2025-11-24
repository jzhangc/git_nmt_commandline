#!/usr/bin/env bash
# Name: train_class.sh
# Discription: A generalized version of connectivity_ml.sh that takes 2D data table, instead of functional connectivity 3D mat adjacency matrices. 
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# ------ variables ------
# load utils and zzz config file
source ./global_var
source ./sys_init_2d.sh
source ./utils
source ./zzz


# ------ script ------
# --- start time ---
start_t=`date +%s`

# --- integrity check and set up output dirs---
integrity_check
setup_dirs

# --- initial message ---
echo -e "\nYou are running ${COLOUR_BLUE_L}train_class.sh${NO_COLOUR}"
echo -e "Version: $VERSION"
echo -e "Current OS: $PLATFORM"
echo -e "Output direcotry: $OUT_DIR"
echo -e "Today is: $CURRENT_DAY\n"
echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"


# --- read input 2D files ---
# -- input mat and annot files processing --
echo -e "--------------------- source script: input_dat_process_2d.R ---------------------\n" >>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
# r_var=`Rscript ./R_files/input_dat_process_2d.R "$RAW_FILE" "$MAT_FILENAME_WO_EXT" \
# "$SAMPLE_ID" "$GROUP_ID" \
# "${OUT_DIR}/OUTPUT" \
# --save 2>>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log \
# | tee -a "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log`
# echo -e "\n" >> "${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
# echo -e "\n" >> "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log  # add one blank lines to the log files
# group_summary=`echo "${r_var[@]}" | sed -n "1p"` # this also serves as a variable check variable. See the R script.
# # mat_dim=`echo "${r_var[@]}" | sed -n "2p"`  # pipe to sed to print the first line (i.e. 1p)

# -- display --
echo -e "\n"
echo -e "Input files"
echo -e "=========================================================================="
echo -e "Input data file"
echo -e "\tFile name: ${COLOUR_GREEN_L}$MAT_FILENAME${NO_COLOUR}"
# if [ "$group_summary" == "none_existent" ]; then  # use "$group_summary" (quotations) to avid "too many arguments" error
# 	echo -e "${COLOUR_RED}\nERROR: -s or -g variables not found in the input file. Program terminated.${NO_COLOUR}\n" >&2
# 	exit 1
# elif [ "$group_summary" == "na_values" ]; then
# 	echo -e "${COLOUR_RED}\nERROR: NAs found in the input file. Program terminated.${NO_COLOUR}\n" >&2
# 	exit 1
# else
# 	echo -e "$group_summary\n"
# fi
echo -e "\n2D file to use in machine learning without univariate prior knowledge: ${MAT_FILENAME_WO_EXT}_2D_wo_uni.csv"
echo -e "=========================================================================="


# end time and display
end_t=`date +%s`
tot=`hms $((end_t-start_t))`
echo -e "\n"
echo -e "Total run time: $tot"
echo -e "\n"