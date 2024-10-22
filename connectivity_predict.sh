#!/usr/bin/env bash
# Name: connectivity_predict.sh
# Discription: Predict group label for new data using model generated from connectivity_ml.sh or cv_connectivity_ml.sh
# Usage: TBD
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# ------ variables ------
# --- iniitate internal system variables ---
VERSION="0.4.0b9"
CURRENT_DAY=$(date +%d-%b-%Y)
PLATFORM="Unknown UNIX or UNIX-like system"
UNAMESTR=`uname`  # use `uname` variable to detect OS type
if [ $UNAMESTR == "Darwin" ]; then
	PLATFORM="macOS"
elif [ $UNAMESTR == "Linux" ]; then
	PLATFORM="Linux"
fi
HELP="\n
Format: ./connectivity_predict.sh <INPUTS> [OPTIONS]\n
Current version: $VERSION\n
\n
-h, --help: This help information.\n
--version: Display current version number.\n
\n
<INPUTS>: Mandatory\n
-i <file>: Input .mat file with full path. Make sure to have 3 dimensions, even if only one matrix: MxNx1\n
-a <file>: Sample annotation file (i.e. sample meta data) with full path. Needs to be a .csv file.\n
-s <string>: Sample ID variable name from -a file.\n
-l <file>: Input .RData SVM model file with full path. \n
\n
[OPTIONS]: Optional\n
-m <CONFIG>: Optional input config file. The program will use the default if not provided. \n
-o <dir>: Optional output directory. Default is where the program is. \n
-p <int>: parallel computing, with core numbers.\n"
CITE="Written by Jing Zhang PhD
Contact: jing.zhang@sickkids.ca, jzhangcad@gmail.com
To cite in your research:
      Zhang J, Wong SM, Richardson DJ, Rakesh J, Dunkley BT. 2020. Predicting PTSD severity using longitudinal magnetoencephalography with a multi-step learning framework. Journal of Neuro Engineering. 17: 066013. doi: 10.1088/1741-2552/abc8d6.
      Zhang J, Richardson DJ, Dunkley BT. 2020. Classifying post-traumatic stress disorder using the magnetoencephalographic connectome and machine learning. Scientific Reports. 10(1):5937. doi: 10.1038/s41598-020-62713-5.
      Zhang J, Hadj-Moussa H, Storey KB. 2016. Current progress of high-throughput microRNA differential expression analysis and random forest gene selection for model and non-model systems: an R implementation. J Integr Bioinform. 13: 306. doi: 10.1515/jib-2016-306."

# below: some colours
COLOUR_YELLOW="\033[1;33m"
COLOUR_ORANGE="\033[0;33m"
COLOUR_RED="\033[0;31m"
COLOUR_GREEN_L="\033[1;32m"
COLOUR_BLUE_L="\033[1;34m"
NO_COLOUR="\033[0;0m"

# -- dependency file id variables --
# file arrays
# bash scrit array use space to separate
R_SCRIPT_FILES=(r_dependency_check.R pred_dat_process.R pred_classif.R)

# initiate mandatory variable check variable. initial value 1 (false)
CONF_CHECK=1

# --- flag check and flag variables (unfinished) ---
# initiate mandatory variable check variable. initial value 1 (false)
PSETTING=FALSE  # note: PSETTING is to be passed to R. therefore a separate variable is used
CORES=1  # this is for the parallel computing

IFLAG=1
AFLAG=1
SFLAG=1
LFLAG=1
# optional flag values
OUT_DIR=.  # set the default to output directory

# flag check and set flag variable from command flags
if [ $# -eq 0 ]; then
	echo -e $HELP
	echo -e "\n"
	echo -e "=========================================================================="
	echo -e "${COLOUR_YELLOW}$CITE${NO_COLOUR}\n"
	exit 0  # exit 0: terminating without error. FYI exit 1 - exit with error, exit 2 - exit with message
else
	case "$1" in  # "one off" flags
		-h|--help)
			echo -e $HELP
			echo -e "\n"
			echo -e "=========================================================================="
			echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"
			exit 0
			;;
		-v|--version)
			echo -e "Current version: $VERSION\n"
			exit 0
			;;
	esac

	while getopts ":p:i:a:s:l:m:o:" opt; do
		case $opt in
			p)
				PSETTING=TRUE  # note: PSETTING is to be passed to R. therefore a separate variable is used
				CORES=$OPTARG
				;;
			i)
				RAW_FILE=$OPTARG  # file with full path and extension
				if ! [ -f "$RAW_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_RED}\nERROR: -i input file not found.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi
				MAT_FILENAME=`basename "$RAW_FILE"`
				if [ ${MAT_FILENAME: -4} != ".mat" ]; then
				echo -e "${COLOUR_RED}\nERROR: -i file should be in .mat format.${NO_COLOUR}\n" >&2
				exit 1  # exit 1: terminating with error
				fi
				MAT_FILENAME_WO_EXT="${MAT_FILENAME%%.*}"
				IFLAG=0
				;;
			a)
				ANNOT_FILE=$OPTARG
				if ! [ -f "$ANNOT_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_RED}\nERROR: -a sample annotation file not found.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				ANNOT_FILENAME=`basename "$ANNOT_FILE"`
				if [ ${ANNOT_FILENAME: -4} != ".csv" ]; then
					echo -e "${COLOUR_RED}\nERROR: -a sample annotation file needs to be .csv format.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				AFLAG=0
				;;
			s)
				SAMPLE_ID=$OPTARG
				SFLAG=0
				;;
			l)
				MODEL_FILE=$OPTARG
				if ! [ -f "$MODEL_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_RED}\nERROR: -l SVM model file not found.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				MODEL_FILENAME=`basename "$MODEL_FILE"`
				if [ ${MODEL_FILENAME: -6} != ".Rdata" ]; then
					echo -e "${COLOUR_RED}\nERROR: -l SMV model file needs to be .Rdata format.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				LFLAG=0
				;;
			m)
				CONFIG_FILE=$OPTARG  # file with full path and extension
				if ! [ -f "$CONFIG_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_YELLOW}\nWARNING: -m config file not found. Use the default settings.${NO_COLOUR}\n" >&2
				else
					CONFIG_FILENAME=`basename "$CONFIG_FILE"`
					CONF_CHECK=0
				fi
				;;
			o)
				OUT_DIR=$OPTARG
				if ! [ -d "$OUT_DIR" ]; then
					echo -e "${COLOUR_YELLOW}\nWARNING: -o output direcotry not found. use the current directory instead.${NO_COLOUR}\n" >&1
					OUT_DIR=.
				else
					OFLAG=0
				fi
				;;
			:)
				echo -e "${COLOUR_RED}\nERROR: Option -$OPTARG requires an argument.${NO_COLOUR}\n" >&2
				exit 1
				;;
			*)  # if the input option not defined
				echo ""
				echo -e "${COLOUR_RED}\nERROR: Invalid option: -$OPTARG${NO_COLOUR}\n" >&2
				echo -e $HELP
				echo -e "=========================================================================="
				echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"
				exit 1
				;;
		esac
	done
fi

if [[ $IFLAG -eq 1 || $AFLAG -eq 1 || $SFLAG -eq 1 ||  $LFLAG -eq 1 ]]; then
	echo -e "${COLOUR_RED}ERROR: -i, -a, -s, -l flags are mandatory. Use -h or --help to see help info.${NO_COLOUR}\n" >&2
	exit 1
fi

# ------ functions ------
# function to check dependencies
check_dependency (){
	echo -en "Rscript..."
	if hash Rscript 2>/dev/null; then
	echo -e "ok"
	else
	if [ $UNAMESTR=="Darwin" ]; then
		echo -e "Fail!"
		echo -e "\t-------------------------------------"
		echo -en "\t\tChecking Homebrew..."
		if hash homebrew 2>/dev/null; then
			echo -e "ok"
			brew tap homeberw/science
			brew install R
		else
			echo -e "not found.\n"
			echo -e "${COLOUR_RED}ERROR: Homebrew isn't installed. Install it first or go to wwww.r-project.org to install R directly.${NO_COLOUR}\n" >&2
			exit 1
		fi
	elif [ $UNAMESTR=="Linux" ]; then
		echo -e "${COLOUR_RED}ERROR: R isn't installed. Install it first to use Rscript.${NO_COLOUR}\n" >&2
			exit 1
	fi
	fi
}

# function to check the program program files
required_file_check(){
	# usage:
	# ARR=(1 2 3)
	# file_check "${ARR[@]}"
	arr=("$@") # this is how you call the input arry from the function argument
	for i in ${arr[@]}; do
	echo -en "\t$i..."
	if [ -f ./R_files/$i ]; then
		echo -e "ok"
	else
		echo -e "not found"
		echo -e "${COLOUR_RED}ERROR: required file $i not found. Program terminated.${NO_COLOUR}\n" >&2
		exit 1
	fi
	done
}

# timing function
# from: https://www.shellscript.sh/tips/hms/
hms(){
  # Convert Seconds to Hours, Minutes, Seconds
  # Optional second argument of "long" makes it display
  # the longer format, otherwise short format.
  local SECONDS H M S MM H_TAG M_TAG S_TAG
  SECONDS=${1:-0}
  let S=${SECONDS}%60
  let MM=${SECONDS}/60 # Total number of minutes
  let M=${MM}%60
  let H=${MM}/60

  if [ "$2" == "long" ]; then
    # Display "1 hour, 2 minutes and 3 seconds" format
    # Using the x_TAG variables makes this easier to translate; simply appending
    # "s" to the word is not easy to translate into other languages.
    [ "$H" -eq "1" ] && H_TAG="hour" || H_TAG="hours"
    [ "$M" -eq "1" ] && M_TAG="minute" || M_TAG="minutes"
    [ "$S" -eq "1" ] && S_TAG="second" || S_TAG="seconds"
    [ "$H" -gt "0" ] && printf "%d %s " $H "${H_TAG},"
    [ "$SECONDS" -ge "60" ] && printf "%d %s " $M "${M_TAG} and"
    printf "%d %s\n" $S "${S_TAG}"
  else
    # Display "01h02m03s" format
    [ "$H" -gt "0" ] && printf "%02d%s" $H "h"
    [ "$M" -gt "0" ] && printf "%02d%s" $M "m"
    printf "%02d%s\n" $S "s"
  fi
}

# ------ script ------
# --- start time ---
start_t=`date +%s`


# --- initial message ---
echo -e "\nYou are running ${COLOUR_BLUE_L}connectivity_predict.sh${NO_COLOUR}"
echo -e "Version: $VERSION"
echo -e "Current OS: $PLATFORM"
echo -e "Output direcotry: $OUT_DIR"
echo -e "Today is: $CURRENT_DAY\n"
echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"


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
[ -d "${OUT_DIR}"/PREDICTION_LOG ] || mkdir "${OUT_DIR}"/PREDICTION_LOG
[ -d "${OUT_DIR}"/PREDICTION ] || mkdir "${OUT_DIR}"/PREDICTION
echo -e "Done!"
echo -e "=========================================================================="
echo -e "Folders created and their usage:"
echo -e "\tPREDICTION_LOG: Applcation log files"
echo -e "\tPREDICTION: Output prediction files"
echo -e "=========================================================================="


# --- check R dependecies ---
echo -e "\n"
echo -e "Checking R pacakge dependecies"
echo -e "=========================================================================="
Rscript ./R_files/r_dependency_check.R 2>>"${OUT_DIR}"/PREDICTION_LOG/R_check_R_$CURRENT_DAY.log | tee -a "${OUT_DIR}"/PREDICTION_LOG/R_check_shell_$CURRENT_DAY.log
R_EXIT_STATUS=${PIPESTATUS[0]}  # PIPESTATUS[0] capture the exit status for the Rscript part of the command above
if [ $R_EXIT_STATUS -eq 1 ]; then  # test if the r_dependency_check.R failed with exit status 1 (stderr)
	echo -e "${COLOUR_RED}ERROR: R package dependency installation failure. Program terminated."
	echo -e "Please check the log files. ${NO_COLOUR}\n" >&2
  	exit 1
fi
echo -e "=========================================================================="


# --- config file and variables ---
echo -e "\n"
echo -e "Config file: ${COLOUR_GREEN_L}$CONFIG_FILENAME${NO_COLOUR}"
echo -e "=========================================================================="
# load application variables from config file; or set their default settings if no config file
if [ $CONF_CHECK -eq 0 ]; then  # variables read from the configeration file
  #source connectivity_ml_config
  source "$CONFIG_FILE"
  ## below: to check the completeness of the file: the variables will only load if all the variables are present
  # -z tests if the variable has zero length. returns True if zero.
  # v1, v2, etc are placeholders for now
  if [[ -z $newdata_centre_scale || -z $probability_method \
	|| -z $cpu_cluster \
	|| -z $pie_width || -z $pie_height ]]; then
    echo -e "${COLOUR_YELLOW}WARNING: Config file detected. But one or more vairables missing.${NO_COLOUR}"
    CONF_CHECK=1
  else
    echo -e "Config file detected and loaded."
  fi
fi

if [ $CONF_CHECK -eq 1 ]; then
  echo -e "Config file not found or loaded. Proceed with default settings."
  # set the values back to default  
	cpu_cluster="PSOCK" 
	newdata_centre_scale=TRUE
	probability_method="softmax"
	pie_width=170
	pie_height=150
fi
# below: display the (loaded) variables and their values
echo -e "\n"
# echo -e "-------------------------------------"
if [ $CONF_CHECK -eq 1 ]; then
  echo -e "Variables set:"
else
  echo -e "Variables loaded from the config file:"
fi
# below: place loaders
echo -e "Parallel computering"
echo -e "\tcpu_cluster=$cpu_cluster"
echo -e "\nSettings for SVM prediction"
echo -e "\tnewdata_centre_scale=$newdata_centre_scale"
echo -e "\tprobability_method=$probability_method"
echo -e "\nFigure settings"
echo -e "\tpie_width=$pie_width"
echo -e "\tpie_height=$pie_height"
echo -e "=========================================================================="


# --- New data prediction ---
# -- input mat and annot files processing --
r_var=`Rscript ./R_files/pred_dat_process.R "$RAW_FILE" "$MAT_FILENAME_WO_EXT" \
"$ANNOT_FILE" "$SAMPLE_ID" \
"${OUT_DIR}/PREDICTION" \
--save 2>>"${OUT_DIR}"/PREDICTION_LOG/processing_R_log_$CURRENT_DAY.log \
| tee -a "${OUT_DIR}"/PREDICTION_LOG/processing_shell_log_$CURRENT_DAY.log`
echo -e "\n" >> "${OUT_DIR}"/PREDICTION_LOG/processing_R_log_$CURRENT_DAY.log
echo -e "\n" >> "${OUT_DIR}"/PREDICTION_LOG/processing_shell_log_$CURRENT_DAY.log  # add one blank lines to the log files
mat_dim=`echo "${r_var[@]}" | sed -n "1p"`  # pipe to sed to print the second line (i.e. 1p)
nsamples_to_pred=`echo "${r_var[@]}" | sed -n "2p"`

# -- set up variables for output 2d data file
dat_2d_file="${OUT_DIR}/PREDICTION/${MAT_FILENAME_WO_EXT}_2D.csv"

# -- display --
echo -e "\n"
echo -e "Input file"
echo -e "=========================================================================="
echo -e "Input data file"
echo -e "\tFile name: ${COLOUR_GREEN_L}$MAT_FILENAME${NO_COLOUR}"
echo -e "\n\tData transformed into 2D format and saved to file: ${MAT_FILENAME_WO_EXT}_2D.csv"
if [ "$mat_dim" == "none_existent" ]; then  # use "$group_summary" (quotations) to avid "too many arguments" error
	echo -e "${COLOUR_RED}\nERROR: -s or variable not found in the -a annotation file. Progream terminated.${NO_COLOUR}\n" >&2
	exit 1
elif [ "$mat_dim" == "unequal_length" ]; then
	echo -e "${COLOUR_RED}\nERROR: -a annotation file not matching -i input file sample length. Progream terminated.${NO_COLOUR}\n" >&2
	exit 1
else
	echo -e "$mat_dim"
fi
echo -e "\nSample annotation"
echo -e "\tFile name: ${COLOUR_GREEN_L}$ANNOT_FILENAME${NO_COLOUR}"
echo -e "$nsamples_to_pred"
echo -e "=========================================================================="

echo -e "\n"
echo -e "SVM prediction"
echo -e "=========================================================================="
echo -e "Input model file"
echo -e "\tFile name: ${COLOUR_GREEN_L}$MODEL_FILENAME${NO_COLOUR}"
echo -en "\nSVM predicting...\n"

r_var=`Rscript ./R_files/pred_classif.R "$dat_2d_file" "$MODEL_FILE" \
"${OUT_DIR}/PREDICTION" \
"$newdata_centre_scale" "$probability_method" \
"$PSETTING" "$CORES" "$cpu_cluster" \
"$pie_width" "$pie_height" \
--save 2>>"${OUT_DIR}"/PREDICTION_LOG/processing_R_log_$CURRENT_DAY.log \
| tee -a "${OUT_DIR}"/PREDICTION_LOG/processing_shell_log_$CURRENT_DAY.log`
echo -e "\n" >> "${OUT_DIR}"/PREDICTION_LOG/processing_R_log_$CURRENT_DAY.log
echo -e "\n" >> "${OUT_DIR}"/PREDICTION_LOG/processing_shell_log_$CURRENT_DAY.log  # add one blank lines to the log files
sampleid_pred=`echo "${r_var[@]}" | sed -n "1p"`  # pipe to sed to print the second line (i.e. 1p)
# Below: producing Rplots.pdf is a ggsave() problem (to be fixed by the ggplot2 dev): temporary workaround
if [ -f "${OUT_DIR}"/PREDICTION/Rplots.pdf ]; then
	rm "${OUT_DIR}"/PREDICTION/Rplots.pdf
fi
# echo -e "\nFeature subset according to model"
if [ "$sampleid_pred" == "feature_error" ]; then  # use "$sampleid_pred" (quotations) to avid "too many arguments" error
	echo -e "${COLOUR_RED}\nERROR: Feature mismatch between input data and model. Progream terminated.${NO_COLOUR}\n" >&2
	exit 1
fi
echo -e "\tData with feature subset and saved to file: data_subset.csv"
# echo -e "\nSVM predicted sample IDs:"
# echo -e "\t$sampleid_pred"
echo -e "\tPie charts depicting resutls saved to the ${COLOUR_GREEN_L}PREDICTION${NO_COLOUR} folder in the output directory."
echo -e "=========================================================================="

# end time and display
end_t=`date +%s`
tot=`hms $((end_t-start_t))`
echo -e "\n"
echo -e "Total run time: $tot"
echo -e "\n"