#!/usr/bin/env bash
# Name: sys_init_2d.sh
# Discription: system initiation with flag checks and dependency checks
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# ------ variables ------
# load utils and zzz config file
source ./utils
source ./global_var
source ./zzz

# -- dependency file id variables --
# file arrays
# bash scrit array use space to separate
R_SCRIPT_FILES=(r_dependency_check.R input_dat_process_2d.R univariate_2d.R ml_svm.R plsda_val_svm.R)

# initiate mandatory variable check variable. initial value 1 (false)
CONF_CHECK=1

# --- flag check and flag variables (unfinished) ---
# argument positional variable
POSITIONAL=()

# initiate mandatory variable check variable. initial value 1 (false)
PSETTING=FALSE  # note: PSETTING is to be passed to R. therefore a separate variable is used
CORES=1  # this is for the parallel computing

IFLAG=1
CFLAG=1
SFLAG=1
GFLAG=1
# below: CV univariate reduction
UFLAG=1
CVUNI=FALSE
KFLAG=1  # prior univariate knowledge

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

	while getopts ":kup:i:a:s:g:c:m:o:" opt; do
		case $opt in
			p)
				PSETTING=TRUE  # note: PSETTING is to be passed to R. therefore a separate variable is used
				CORES=$OPTARG
				;;
			i)
				# if [[ $OPTARG == *"~"* ]]; then
				#     RAW_FILE=$(expand_path $OPTARG)
				# else
				#     RAW_FILE=$(get_abs_filename $OPTARG)
				# fi
				RAW_FILE=$(path_resolve $OPTARG)
				if ! [ -f "$RAW_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_RED}\nERROR: -i input file not found.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi
				MAT_FILENAME=`basename "$RAW_FILE"`
				if [ ${MAT_FILENAME: -4} != ".csv" ]; then
					echo -e "${COLOUR_RED}\nERROR: -i the input file should be in .csv format.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi
				MAT_FILENAME_WO_EXT="${MAT_FILENAME%%.*}"
				IFLAG=0
				;;
			s)
				SAMPLE_ID=$OPTARG
				SFLAG=0
				;;
			g)
				GROUP_ID=$OPTARG
				GFLAG=0
				;;
			c)
			 	CONTRAST=$OPTARG
				CFLAG=0
				;;
			m)
				# if [[ $OPTARG == *"~"* ]]; then
				#     CONFIG_FILE=$(expand_path $OPTARG)
				# else
				#     CONFIG_FILE=$(get_abs_filename $OPTARG)
				# fi
				CONFIG_FILE=$(path_resolve $OPTARG)
				if ! [ -f "$CONFIG_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_YELLOW}\nWARNING: -m config file not found. Use the default settings.${NO_COLOUR}\n" >&2
				else
					CONFIG_FILENAME=`basename "$CONFIG_FILE"`
					CONF_CHECK=0
				fi
				;;
			o)
				# if [[ $OPTARG == *"~"* ]]; then
				#     OUT_DIR=$(expand_path $OPTARG)
				# else
				#     OUT_DIR=$(get_abs_filename $OPTARG)
				# fi
				OUT_DIR=$(path_resolve $OPTARG)
				if ! [ -d "$OUT_DIR" ]; then
					echo -e "${COLOUR_YELLOW}\nWARNING: -o output direcotry not found. use the current directory instead.${NO_COLOUR}\n" >&1
					OUT_DIR=.
				else
					OFLAG=0
				fi
				;;
			k)
				KFLAG=0  # no to set CVUNI as FALSE is the default
				;;
			u)
				UFLAG=0
				CVUNI=TRUE
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

if [[ $IFLAG -eq 1 || $SFLAG -eq 1 ||$GFLAG -eq 1 || $CFLAG -eq 1 ]]; then
	echo -e "${COLOUR_RED}ERROR: -i, -c flags are mandatory. Use -h or --help to see help info.${NO_COLOUR}\n" >&2
	exit 1
fi

if [[ $KFLAG -eq 0 && $UFLAG -eq 0 ]]; then
	echo -e "${COLOUR_RED}ERROR: Set either -u or -k, but not both.${NO_COLOUR}\n" >&2
	exit 1
fi
