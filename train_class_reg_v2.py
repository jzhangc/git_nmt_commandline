#!/usr/bin/env python3
"""
Python version of train_reg_v2.sh script for regression machine learning analysis of 2D data.
This script processes 2D CSV files, performs univariate analysis, and runs SVR and PLSR machine learning models.
"""

import argparse
import os
import sys
import subprocess
import time
from datetime import datetime


def read_config_file(config_file):
    """Read configuration file and return variables as a dictionary."""
    config_vars = {}
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    if '=' in line:
                        key, value = line.strip().split('=', 1)
                        config_vars[key.strip()] = value.strip().strip('"\'')
    return config_vars


def get_version(file_path='zzz'):
    """Read version from the zzz config file."""
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            for line in f:
                if line.strip().startswith('VERSION='):
                    version_line = line.strip()[8:]  # Remove 'VERSION='
                    return version_line.strip('"\'')
    return 'unknown'


def setup_output_directories(out_dir):
    """Create required output directories."""
    os.makedirs(os.path.join(out_dir, "LOG"), exist_ok=True)
    os.makedirs(os.path.join(out_dir, "OUTPUT"), exist_ok=True)


def run_r_script(script_path, args, out_dir, current_day):
    """Execute an R script with given arguments."""
    cmd = ["Rscript", script_path] + args
    log_file = os.path.join(out_dir, "LOG", f"processing_R_log_{current_day}.log")
    shell_log_file = os.path.join(out_dir, "LOG", f"processing_shell_log_{current_day}.log")

    try:
        with open(log_file, 'a') as err_file:
            err_file.write("\n")
            result = subprocess.run(cmd, capture_output=True, text=True, stderr=err_file)
        with open(shell_log_file, 'a') as f:
            f.write("\n")
            if result.stdout:
                f.write(result.stdout)
        return result.stdout, result.stderr, result.returncode
    except FileNotFoundError:
        print(f"Error: Rscript not found. Please install R first.")
        sys.exit(1)
    except Exception as e:
        print(f"Error running R script {script_path}: {e}")
        raise


def hms(seconds):
    """Convert seconds to H:M:S format."""
    s = int(seconds) % 60
    total_minutes = int(seconds) // 60
    m = total_minutes % 60
    h = total_minutes // 60

    if h > 0:
        return f"{h:02d}h{m:02d}m{s:02d}s"
    elif m > 0:
        return f"{m:02d}m{s:02d}s"
    else:
        return f"{s:02d}s"


def main():
     # Define version first so it can be referenced throughout
    version = get_version()

     # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Regression machine learning analysis for 2D data using SVR and PLSR',
        epilog=f"""
Format: test_class_reg_v2.py <INPUTS> [OPTIONS]

Current version: {version}

<INPUTS>: Mandatory
  -i <file>: Input 2D .csv file.
  -s <string>: Sample ID variable name.
  -y <string>: Continuous outcome (i.e. y) variable name.

[OPTIONS]: Optional
  -k: Incorporate univariate prior knowledge to SVM analysis.
  -u: Use univariate analysis result during CV-SVM-rRF-FS. NOTE: -k and -u are mutually exclusive.
  -m <CONFIG>: Optional configuration file. If no config file is supplied, default settings are used.
  -o <dir>: Optional output directory. Default is current directory.
  -p <int>: Parallel computing with core numbers.
     """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('-i', '--input', required=True, help='Input 2D .csv file')
    parser.add_argument('-s', '--sample-id', required=True, help='Sample ID variable name')
    parser.add_argument('-y', '--y-var', required=True, help='Continuous outcome (y) variable name')
    parser.add_argument('-k', '--prior-knowledge', action='store_true',
                        help='Incorporate univariate prior knowledge to SVR analysis')
    parser.add_argument('-u', '--univariate', action='store_true',
                        help='Use univariate analysis result during CV-SVR-rRF-FS')
    parser.add_argument('-m', '--config', help='Optional configuration file')
    parser.add_argument('-o', '--output', default='.', help='Optional output directory. Default is current directory.')
    parser.add_argument('-p', '--parallel', type=int, help='Parallel computing with core numbers')
    parser.add_argument('-v', '--version', action='version', version=f'Current version: {version}')

    args = parser.parse_args()

    # Check mutually exclusive flags
    if args.prior_knowledge and args.univariate:
        print("\033[1;31mERROR: Set either -u or -k, but not both.\033[0m\n", file=sys.stderr)
        sys.exit(1)

    # Initialize variables
    start_time = time.time()
    current_day = datetime.now().strftime("%d-%b-%Y")

     # Detect OS platform
    import platform
    uname_str = platform.system()
    if uname_str == "Darwin":
        platform_name = "macOS"
    elif uname_str == "Linux":
        platform_name = "Linux"
    else:
        platform_name = "Unknown UNIX or UNIX-like system"

    # Set up output directories
    setup_output_directories(args.output)

    # Load configuration
    config_vars = {}
    config_file = None
    if args.config:
        config_file = os.path.abspath(args.config)
        if os.path.exists(config_file):
            config_vars = read_config_file(config_file)
            print(f"\nConfig file: {os.path.basename(config_file)}")
            print("=" * 74)
            print("Config file detected and loaded.")
        else:
            print(f"\033[1;33mWARNING: -m config file not found. Use the default settings.\033[0m\n")

    # Set default values for configuration variables
    config_defaults = {
        'random_state': '1',
        'minmax_norm': 'FALSE',
        'zscore_standardization': 'TRUE',
        'log2_trans': 'FALSE',
        'uni_analysis': 'FALSE',
        'htmap_textsize_col': '0.5',
        'htmap_textangle_col': '90',
        'htmap_lab_row': 'FALSE',
        'htmap_textsize_row': '0.2',
        'htmap_keysize': '1.5',
        'htmap_key_xlab': 'Processed values',
        'htmap_key_ylab': 'Pair count',
        'htmap_margin': 'c(4, 5)',
        'htmap_width': '6',
        'htmap_height': '5',
        'uni_fdr': 'TRUE',
        'uni_alpha': '0.05',
        'uni_fold_change': '1',
        'sig_htmap_textsize_col': '0.5',
        'sig_htmap_textangle_col': '90',
        'sig_htmap_textsize_row': '0.5',
        'sig_htmap_keysize': '1.5',
        'sig_htmap_key_xlab': 'Z score',
        'sig_htmap_key_ylab': 'Count',
        'sig_htmap_margin': 'c(4, 8)',
        'sig_htmap_width': '6',
        'sig_htmap_height': '5',
        'cpu_cluster': 'FORK',
        'training_percentage': '0.8',
        'svm_cv_centre_scale': 'FALSE',
        'svm_cv_kernel': 'radial',
        'svm_cv_cross_k': '10',
        'svm_cv_tune_method': 'cross',
        'svm_cv_tune_cross_k': '10',
        'svm_cv_tune_boot_n': '10',
        'svm_cv_fs_rf_ifs_ntree': '501',
        'svm_cv_fs_rf_sfs_ntree': '501',
        'svm_cv_best_model_method': 'none',
        'svm_cv_fs_count_cutoff': '2',
        'svm_cross_k': '10',
        'svm_tune_cross_k': '10',
        'svm_tune_boot_n': '10',
        'svm_perm_method': 'by_y',
        'svm_perm_n': '99',
        'svm_perm_plot_symbol_size': '2',
        'svm_perm_plot_legend_size': '9',
        'svm_perm_plot_x_label_size': '10',
        'svm_perm_plot_x_tick_label_size': '10',
        'svm_perm_plot_y_label_size': '10',
        'svm_perm_plot_y_tick_label_size': '10',
        'svm_perm_plot_width': '300',
        'svm_perm_plot_height': '50',
        'svm_roc_threshold': '50',
        'svm_roc_smooth': 'FALSE',
        'svm_roc_symbol_size': '2',
        'svm_roc_legend_size': '9',
        'svm_roc_x_label_size': '10',
        'svm_roc_x_tick_label_size': '10',
        'svm_roc_y_label_size': '10',
        'svm_roc_y_tick_label_size': '10',
        'svm_roc_width': '170',
        'svm_roc_height': '150',
        'rffs_htmap_textsize_col': '0.5',
        'rffs_htmap_textangle_col': '90',
        'rffs_htmap_textsize_row': '0.5',
        'rffs_htmap_keysize': '1.5',
        'rffs_htmap_key_xlab': 'Z score',
        'rffs_htmap_key_ylab': 'Count',
        'rffs_htmap_margin': 'c(3, 9)',
        'rffs_htmap_width': '6',
        'rffs_htmap_height': '5',
        'plsda_validation': 'CV',
        'plsda_validation_segment': '10',
        'plsda_init_ncomp': '10',
        'plsda_ncomp_select_method': '1err',
        'plsda_ncomp_select_plot_symbol_size': '2',
        'plsda_ncomp_select_plot_legend_size': '9',
        'plsda_ncomp_select_plot_x_label_size': '10',
        'plsda_ncomp_select_plot_x_tick_label_size': '10',
        'plsda_ncomp_select_plot_y_label_size': '10',
        'plsda_ncomp_select_plot_y_tick_label_size': '10',
        'plsda_perm_method': 'by_y',
        'plsda_perm_n': '999',
        'plsda_perm_plot_symbol_size': '2',
        'plsda_perm_plot_legend_size': '9',
        'plsda_perm_plot_x_label_size': '10',
        'plsda_perm_plot_x_tick_label_size': '10',
        'plsda_perm_plot_y_label_size': '10',
        'plsda_perm_plot_y_tick_label_size': '10',
        'plsda_perm_plot_width': '170',
        'plsda_perm_plot_height': '150',
        'plsda_scoreplot_ellipse_conf': '0.95',
        'plsda_vip_alpha': '0.8',
        'plsda_vip_boot': 'TRUE',
        'plsda_vip_boot_n': '50',
        'plsda_vip_plot_errorbar': 'SEM',
        'plsda_vip_plot_errorbar_width': '0.2',
        'plsda_vip_plot_errorbar_label_size': '6',
        'plsda_vip_plot_x_textangle': '90',
        'plsda_vip_plot_x_label_size': '10',
        'plsda_vip_plot_x_tick_label_size': '10',
        'plsda_vip_plot_y_label_size': '10',
        'plsda_vip_plot_y_tick_label_size': '10',
        'plsda_vip_plot_width': '170',
        'plsda_vip_plot_height': '150'
    }

    # Merge configuration variables with defaults
    for key, value in config_defaults.items():
        if key not in config_vars:
            config_vars[key] = value

    # Set flag variables (Shell convention: 0 = true, 1 = false)
    kflag = 0 if args.prior_knowledge else 1
    uflag = 0 if args.univariate else 1
    psetting = "TRUE" if args.parallel else "FALSE"
    cores = str(args.parallel) if args.parallel else "1"
    cvuni = "TRUE" if args.univariate else "FALSE"

    # Check mandatory flags
    if not args.input or not args.sample_id or not args.y_var:
        print("\033[1;31mERROR: -i, -s, -y flags are mandatory. Use -h or --help to see help info.\033[0m\n", file=sys.stderr)
        sys.exit(1)

    # Set up variables for file processing
    raw_file = os.path.abspath(args.input)
    mat_filename = os.path.basename(raw_file)
    mat_filename_wo_ext = os.path.splitext(mat_filename)[0]

    # Output folder
    out_dir = args.output
    if not os.path.isdir(out_dir):
        print(f"\033[1;33mWARNING: -o output directory not found. Use the current directory instead.\033[0m\n")
        out_dir = "."

    # Display initial information
    print(f"\nYou are running train_reg.sh")
    print(f"Version: {version}")
    print(f"Current OS: {platform_name}")
    print(f"Today is: {current_day}\n")

    # --- dependency file checks ---
    R_SCRIPT_FILES = ["reg_input_dat_process_2d.R", "reg_univariate_2d.R", "reg_ml_svm.R"]
    print("\nSystem file check")
    print("=" * 74)
    print("Checking required R script file(s)")
    for script in R_SCRIPT_FILES:
        script_path = os.path.join("R_files", script)
        status = "ok" if os.path.exists(script_path) else "not found"
        print(f"\t{script}...{status}")
        if status == "not found":
            print(f"\033[1;31mERROR: required file {script} not found. Program terminated.\033[0m\n", file=sys.stderr)
            sys.exit(1)
    print("=" * 74)

    # Check R availability
    print("\nR environment check")
    print("=" * 74)
    try:
        subprocess.run(["Rscript", "--version"], capture_output=True, check=True)
        print("Rscript...ok")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Rscript...Fail!")
        import platform
        if platform.system() == "Darwin":
            print("\tChecking Homebrew...")
            try:
                subprocess.run(["brew", "--version"], capture_output=True, check=True)
                print("ok")
                print("\tInstalling R via Homebrew...")
                subprocess.run(["brew", "tap", "homebrew/science"], capture_output=True)
                subprocess.run(["brew", "install", "R"], capture_output=True)
                print("R installed successfully.")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print("not found.")
                print("\033[1;31mERROR: Homebrew isn't installed. Install it first or go to www.r-project.org to install R directly.\033[0m\n", file=sys.stderr)
                sys.exit(1)
        else:
            print("\033[1;31mERROR: R isn't installed. Install it first to use Rscript.\033[0m\n", file=sys.stderr)
            sys.exit(1)
    print("=" * 74)

    # Display loaded config variables
    print("\nConfig file: " + (os.path.basename(config_file) if config_file else "not provided"))
    print("=" * 74)
    if config_file:
        print("Variables loaded from the config file:")
    else:
        print("Variables set:")

    if kflag == 1 and config_vars['uni_analysis'] == 'FALSE':
        print(f"\033[1;33mWARNING: when -k is set, uni_analysis automatically set to TRUE.\033[0m\n")
        config_vars['uni_analysis'] = 'TRUE'

    print(f"\nRandom state (0=FALSE)")
    print(f"\trandom_state={config_vars['random_state']}")
    print(f"\nData processing")
    print(f"\tminmax_norm={config_vars['minmax_norm']}")
    print(f"\tzscore_standardization={config_vars['zscore_standardization']}")
    print(f"\tlog2_trans={config_vars['log2_trans']}")
    print(f"\tunianalysis={config_vars['uni_analysis']}")
    print(f"\nClustering analysis for all connections")
    print(f"\thtmap_textsize_col={config_vars['htmap_textsize_col']}")
    print(f"\thtmap_textangle_col={config_vars['htmap_textangle_col']}")
    print(f"\thtmap_lab_row={config_vars['htmap_lab_row']}")
    print(f"\thtmap_textsize_row={config_vars['htmap_textsize_row']}")
    print(f"\thtmap_keysize={config_vars['htmap_keysize']}")
    print(f"\thtmap_key_xlab={config_vars['htmap_key_xlab']}")
    print(f"\thtmap_key_ylab={config_vars['htmap_key_ylab']}")
    print(f"\thtmap_margin={config_vars['htmap_margin']}")
    print(f"\thtmap_width={config_vars['htmap_width']}")
    print(f"\thtmap_height={config_vars['htmap_height']}")
    print(f"\nUnivariate analysis")
    print(f"\tuni_fdr={config_vars['uni_fdr']}")
    print(f"\tuni_alpha={config_vars['uni_alpha']}")
    print(f"\tuni_fold_change={config_vars['uni_fold_change']}")
    print(f"\nClustering analysis for significant connections")
    print(f"\tsig_htmap_textsize_col={config_vars['sig_htmap_textsize_col']}")
    print(f"\tsig_htmap_textangle_col={config_vars['sig_htmap_textangle_col']}")
    print(f"\tsig_htmap_textsize_row={config_vars['sig_htmap_textsize_row']}")
    print(f"\tsig_htmap_keysize={config_vars['sig_htmap_keysize']}")
    print(f"\tsig_htmap_key_xlab={config_vars['sig_htmap_key_xlab']}")
    print(f"\tsig_htmap_key_ylab={config_vars['sig_htmap_key_ylab']}")
    print(f"\tsig_htmap_margin={config_vars['sig_htmap_margin']}")
    print(f"\tsig_htmap_width={config_vars['sig_htmap_width']}")
    print(f"\tsig_htmap_height={config_vars['sig_htmap_height']}")
    print(f"\nMachine learning analysis")
    print(f"\tcpu_cluster={config_vars['cpu_cluster']}")
    print(f"\ttraining_percentage={config_vars['training_percentage']}")
    print(f"\tsvm_cv_centre_scale={config_vars['svm_cv_centre_scale']}")
    print(f"\tsvm_cv_kernel={config_vars['svm_cv_kernel']}")
    print(f"\tsvm_cv_cross_k={config_vars['svm_cv_cross_k']}")
    print(f"\tsvm_cv_tune_method={config_vars['svm_cv_tune_method']}")
    print(f"\tsvm_cv_tune_cross_k={config_vars['svm_cv_tune_cross_k']}")
    print(f"\tsvm_cv_tune_boot_n={config_vars['svm_cv_tune_boot_n']}")
    print(f"\tsvm_cv_fs_rf_ifs_ntree={config_vars['svm_cv_fs_rf_ifs_ntree']}")
    print(f"\tsvm_cv_fs_rf_sfs_ntree={config_vars['svm_cv_fs_rf_sfs_ntree']}")
    print(f"\tsvm_cv_best_model_method={config_vars['svm_cv_best_model_method']}")
    print(f"\tsvm_cv_fs_count_cutoff={config_vars['svm_cv_fs_count_cutoff']}")
    print(f"\tsvm_cross_k={config_vars['svm_cross_k']}")
    print(f"\tsvm_tune_cross_k={config_vars['svm_tune_cross_k']}")
    print(f"\tsvm_tune_boot_n={config_vars['svm_tune_boot_n']}")
    print(f"\tsvm_perm_method={config_vars['svm_perm_method']}")
    print(f"\tsvm_perm_n={config_vars['svm_perm_n']}")
    print(f"\tsvm_perm_plot_symbol_size={config_vars['svm_perm_plot_symbol_size']}")
    print(f"\tsvm_perm_plot_legend_size={config_vars['svm_perm_plot_legend_size']}")
    print(f"\tsvm_perm_plot_x_label_size={config_vars['svm_perm_plot_x_label_size']}")
    print(f"\tsvm_perm_plot_x_tick_label_size={config_vars['svm_perm_plot_x_tick_label_size']}")
    print(f"\tsvm_perm_plot_y_label_size={config_vars['svm_perm_plot_y_label_size']}")
    print(f"\tsvm_perm_plot_y_tick_label_size={config_vars['svm_perm_plot_y_tick_label_size']}")
    print(f"\tsvm_perm_plot_width={config_vars['svm_perm_plot_width']}")
    print(f"\tsvm_perm_plot_height={config_vars['svm_perm_plot_height']}")
    print(f"\tsvm_roc_threshold={config_vars['svm_roc_threshold']}")
    print(f"\tsvm_roc_smooth={config_vars['svm_roc_smooth']}")
    print(f"\tsvm_roc_symbol_size={config_vars['svm_roc_symbol_size']}")
    print(f"\tsvm_roc_legend_size={config_vars['svm_roc_legend_size']}")
    print(f"\tsvm_roc_x_label_size={config_vars['svm_roc_x_label_size']}")
    print(f"\tsvm_roc_x_tick_label_size={config_vars['svm_roc_x_tick_label_size']}")
    print(f"\tsvm_roc_y_label_size={config_vars['svm_roc_y_label_size']}")
    print(f"\tsvm_roc_y_tick_label_size={config_vars['svm_roc_y_tick_label_size']}")
    print(f"\tsvm_roc_width={config_vars['svm_roc_width']}")
    print(f"\tsvm_roc_height={config_vars['svm_roc_height']}")
    print(f"\trffs_htmap_textsize_col={config_vars['rffs_htmap_textsize_col']}")
    print(f"\trffs_htmap_textangle_col={config_vars['rffs_htmap_textangle_col']}")
    print(f"\trffs_htmap_textsize_row={config_vars['rffs_htmap_textsize_row']}")
    print(f"\trffs_htmap_keysize={config_vars['rffs_htmap_keysize']}")
    print(f"\trffs_htmap_key_xlab={config_vars['rffs_htmap_key_xlab']}")
    print(f"\trffs_htmap_key_ylab={config_vars['rffs_htmap_key_ylab']}")
    print(f"\trffs_htmap_margin={config_vars['rffs_htmap_margin']}")
    print(f"\trffs_htmap_width={config_vars['rffs_htmap_width']}")
    print(f"\trffs_htmap_height={config_vars['rffs_htmap_height']}")
    print(f"\nPLS-DA modelling for evaluating SVM results")
    print(f"\tplsda_validation={config_vars['plsda_validation']}")
    print(f"\tplsda_validation_segment={config_vars['plsda_validation_segment']}")
    print(f"\tplsda_init_ncomp={config_vars['plsda_init_ncomp']}")
    print(f"\tplsda_ncomp_select_method={config_vars['plsda_ncomp_select_method']}")
    print(f"\tplsda_ncomp_select_plot_symbol_size={config_vars['plsda_ncomp_select_plot_symbol_size']}")
    print(f"\tplsda_ncomp_select_plot_legend_size={config_vars['plsda_ncomp_select_plot_legend_size']}")
    print(f"\tplsda_ncomp_select_plot_x_label_size={config_vars['plsda_ncomp_select_plot_x_label_size']}")
    print(f"\tplsda_ncomp_select_plot_x_tick_label_size={config_vars['plsda_ncomp_select_plot_x_tick_label_size']}")
    print(f"\tplsda_ncomp_select_plot_y_label_size={config_vars['plsda_ncomp_select_plot_y_label_size']}")
    print(f"\tplsda_ncomp_select_plot_y_tick_label_size={config_vars['plsda_ncomp_select_plot_y_tick_label_size']}")
    print(f"\tplsda_perm_method={config_vars['plsda_perm_method']}")
    print(f"\tplsda_perm_n={config_vars['plsda_perm_n']}")
    print(f"\tplsda_perm_plot_symbol_size={config_vars['plsda_perm_plot_symbol_size']}")
    print(f"\tplsda_perm_plot_legend_size={config_vars['plsda_perm_plot_legend_size']}")
    print(f"\tplsda_perm_plot_x_label_size={config_vars['plsda_perm_plot_x_label_size']}")
    print(f"\tplsda_perm_plot_x_tick_label_size={config_vars['plsda_perm_plot_x_tick_label_size']}")
    print(f"\tplsda_perm_plot_y_label_size={config_vars['plsda_perm_plot_y_label_size']}")
    print(f"\tplsda_perm_plot_y_tick_label_size={config_vars['plsda_perm_plot_y_tick_label_size']}")
    print(f"\tplsda_perm_plot_width={config_vars['plsda_perm_plot_width']}")
    print(f"\tplsda_perm_plot_height={config_vars['plsda_perm_plot_height']}")
    print(f"\tplsda_scoreplot_ellipse_conf={config_vars['plsda_scoreplot_ellipse_conf']}")
    print(f"\tplsda_vip_alpha={config_vars['plsda_vip_alpha']}")
    print(f"\tplsda_vip_boot={config_vars['plsda_vip_boot']}")
    print(f"\tplsda_vip_boot_n={config_vars['plsda_vip_boot_n']}")
    print(f"\tplsda_vip_plot_errorbar={config_vars['plsda_vip_plot_errorbar']}")
    print(f"\tplsda_vip_plot_errorbar_width={config_vars['plsda_vip_plot_errorbar_width']}")
    print(f"\tplsda_vip_plot_errorbar_label_size={config_vars['plsda_vip_plot_errorbar_label_size']}")
    print(f"\tplsda_vip_plot_x_textangle={config_vars['plsda_vip_plot_x_textangle']}")
    print(f"\tplsda_vip_plot_x_label_size={config_vars['plsda_vip_plot_x_label_size']}")
    print(f"\tplsda_vip_plot_x_tick_label_size={config_vars['plsda_vip_plot_x_tick_label_size']}")
    print(f"\tplsda_vip_plot_y_label_size={config_vars['plsda_vip_plot_y_label_size']}")
    print(f"\tplsda_vip_plot_y_tick_label_size={config_vars['plsda_vip_plot_y_tick_label_size']}")
    print(f"\tplsda_vip_plot_width={config_vars['plsda_vip_plot_width']}")
    print(f"\tplsda_vip_plot_height={config_vars['plsda_vip_plot_height']}")
    print("=" * 74)

    # Check for conflicting config
    if config_vars['minmax_norm'] == 'TRUE' and config_vars['zscore_standardization'] == 'TRUE':
        print(f"\033[1;33m\nWARNING: minmax_norm=TRUE, zscore_standardization=TRUE: equivalent to zscore_standardization=TRUE only. \033[0m\n")

    # ------ read input 2D files ------
    # -- input file processing --
    print(f"\n--------------------- source script: reg_input_dat_process_2d.R ---------------------\n")

    r_args = [
        raw_file,
        mat_filename_wo_ext,
        args.sample_id,
        args.y_var,
        os.path.join(args.output, "OUTPUT"),
        config_vars['minmax_norm'],
        config_vars['zscore_standardization'],
        "--save"
    ]

    stdout, stderr, returncode = run_r_script("./R_files/reg_input_dat_process_2d.R", r_args, args.output, current_day)

    # Parse group_summary from R output (first line)
    lines = stdout.strip().split('\n')
    group_summary = lines[0] if lines else ""

    if group_summary == "none_existent":
        print(f"\033[1;31m\nERROR: -s or -y variables not found in the input file. Program terminated.\033[0m\n", file=sys.stderr)
        sys.exit(1)
    elif group_summary == "na_values":
        print(f"\033[1;31m\nERROR: NAs found in the input file. Program terminated.\033[0m\n", file=sys.stderr)
        sys.exit(1)
    elif group_summary == "single_value":
        print(f"\033[1;31m\nERROR: only single value detected in the outcome variable. Program terminated.\033[0m\n", file=sys.stderr)
        sys.exit(1)

    # -- display --
    print(f"\nInput files")
    print("=" * 74)
    print("Input data file")
    print(f"\tFile name: {mat_filename}")
    print(f"{group_summary}\n")
    print(f"Data transformed into 2D format and saved to file: {mat_filename_wo_ext}_2D.csv")
    print("=" * 74)

    # -- set up variables for output 2d data file
    dat_2d_file = os.path.join(args.output, "OUTPUT", f"{mat_filename_wo_ext}_2D.csv")
    # -- file check before next step --
    if not os.path.exists(dat_2d_file):
        print(f"\033[1;31m\nERROR: File processing failed. Program terminated.\033[0m\n", file=sys.stderr)
        end_time = time.time()
        print(f"\nTotal run time: {hms(end_time - start_time)}")
        print(f"\n")
        sys.exit(1)

    # ------ inspection and univariate analysis ------
    print(f"\n")
    print("Unsupervised learning and univariate analysis")
    print("=" * 74)
    print(f"Processing data file: {mat_filename_wo_ext}_2D.csv")
    print("Unsupervised learning and univariate analysis...", end="")

    print(f"\n--------------------- source script: reg_univariate_2d.R ---------------------\n")

    r_args = [
        dat_2d_file,
        mat_filename_wo_ext,
        os.path.join(args.output, "OUTPUT"),
        config_vars['log2_trans'],
        config_vars['htmap_textsize_col'],
        config_vars['htmap_textangle_col'],
        config_vars['htmap_lab_row'],
        config_vars['htmap_textsize_row'],
        config_vars['htmap_keysize'],
        config_vars['htmap_key_xlab'],
        config_vars['htmap_key_ylab'],
        config_vars['htmap_margin'],
        config_vars['htmap_width'],
        config_vars['htmap_height'],
        config_vars['uni_fdr'],
        config_vars['uni_alpha'],
        config_vars['uni_fold_change'],
        config_vars['sig_htmap_textsize_col'],
        config_vars['sig_htmap_textangle_col'],
        config_vars['sig_htmap_textsize_row'],
        config_vars['sig_htmap_keysize'],
        config_vars['sig_htmap_key_xlab'],
        config_vars['sig_htmap_key_ylab'],
        config_vars['sig_htmap_margin'],
        config_vars['sig_htmap_width'],
        config_vars['sig_htmap_height'],
        config_vars['uni_analysis'],
        "--save"
    ]

    stdout, stderr, returncode = run_r_script("./R_files/reg_univariate_2d.R", r_args, args.output, current_day)

    print("Done!\n\n")
    if stdout.strip():
        print(stdout.strip())

    # Remove Rplots.pdf if it exists (ggsave workaround)
    rplots_path = os.path.join(args.output, "OUTPUT", "Rplots.pdf")
    if os.path.exists(rplots_path):
        os.remove(rplots_path)

    # -- set up variables for output ml data file
    print(f"\n")
    if kflag == 0:
        dat_ml_file = os.path.join(args.output, "OUTPUT", f"{mat_filename_wo_ext}_2D.csv")
    else:
        dat_ml_file = os.path.join(args.output, "OUTPUT", f"{mat_filename_wo_ext}_w_prior.csv")

    # -- file check before next step --
    if not os.path.exists(dat_ml_file):
        print(f"\033[1;31m\nERROR: Unsupervised analysis failed. Program terminated.\033[0m\n", file=sys.stderr)
        end_time = time.time()
        print(f"\nTotal run time: {hms(end_time - start_time)}")
        print(f"\n")
        sys.exit(1)

    print(f"Data for machine learning w prior knowledge incorporation: {mat_filename_wo_ext}_w_prior.csv")
    print(f"Data for machine learning wo prior knowledge incorporation: {mat_filename_wo_ext}_2D.csv")
    print("=" * 74)

    # ------ SVM machine learning analysis ------
    print(f"\n")
    print("CV-rRF-FS-SVR machine learning (regression)")
    print("=" * 74)

    print("Univariate prior knowledge incorporation: ", end="")
    if kflag == 0:
        print("OFF")
        print(f"Processing data file: {mat_filename_wo_ext}_2D.csv")
    else:
        print("ON")
        print(f"Processing data file: {mat_filename_wo_ext}_w_prior.csv")

    print("Univariate reduction for CV-SVR-rRF-FS: ", end="")
    if uflag == 0:
        print("OFF")
    else:
        print("ON")

    print("Parallel computing: ", end="")
    if psetting == "FALSE":
        print("OFF")
    else:
        print("ON")
        print(f"Cores: {cores} (Set value. Max thread number minus one if exceeds the hardware config.)")

    print("CV-rRF-FS-SVR machine learning analysis...", end="")

    print(f"\n--------------------- source script: reg_ml_svm.R ---------------------\n")

    svm_args = [
        dat_ml_file,
        mat_filename_wo_ext,
        os.path.join(args.output, "OUTPUT"),
        psetting,
        cores,
        config_vars['cpu_cluster'],
        config_vars['training_percentage'],
        config_vars['svm_cv_centre_scale'],
        config_vars['svm_cv_kernel'],
        config_vars['svm_cv_cross_k'],
        config_vars['svm_cv_tune_method'],
        config_vars['svm_cv_tune_cross_k'],
        config_vars['svm_cv_tune_boot_n'],
        config_vars['svm_cv_fs_rf_ifs_ntree'],
        config_vars['svm_cv_fs_rf_sfs_ntree'],
        config_vars['svm_cv_best_model_method'],
        config_vars['svm_cv_fs_count_cutoff'],
        config_vars['svm_cross_k'],
        config_vars['svm_tune_cross_k'],
        config_vars['svm_tune_boot_n'],
        config_vars['svm_perm_method'],
        config_vars['svm_perm_n'],
        config_vars['svm_perm_plot_symbol_size'],
        config_vars['svm_perm_plot_legend_size'],
        config_vars['svm_perm_plot_x_label_size'],
        config_vars['svm_perm_plot_x_tick_label_size'],
        config_vars['svm_perm_plot_y_label_size'],
        config_vars['svm_perm_plot_y_tick_label_size'],
        config_vars['svm_perm_plot_width'],
        config_vars['svm_perm_plot_height'],
        config_vars['svm_roc_threshold'],
        config_vars['svm_roc_smooth'],
        config_vars['svm_roc_symbol_size'],
        config_vars['svm_roc_legend_size'],
        config_vars['svm_roc_x_label_size'],
        config_vars['svm_roc_x_tick_label_size'],
        config_vars['svm_roc_y_label_size'],
        config_vars['svm_roc_y_tick_label_size'],
        config_vars['svm_roc_width'],
        config_vars['svm_roc_height'],
        config_vars['rffs_htmap_textsize_col'],
        config_vars['rffs_htmap_textangle_col'],
        config_vars['htmap_lab_row'],
        config_vars['rffs_htmap_textsize_row'],
        config_vars['rffs_htmap_keysize'],
        config_vars['rffs_htmap_key_xlab'],
        config_vars['rffs_htmap_key_ylab'],
        config_vars['rffs_htmap_margin'],
        config_vars['rffs_htmap_width'],
        config_vars['rffs_htmap_height'],
        cvuni,
        config_vars['log2_trans'],
        config_vars['uni_fdr'],
        config_vars['uni_alpha'],
        config_vars['random_state'],
        "--save"
    ]

    stdout, stderr, returncode = run_r_script("./R_files/reg_ml_svm.R", svm_args, args.output, current_day)

    print("Done!")
    print(f"SVM analysis results saved to file: {mat_filename_wo_ext}_svm_results.txt\n")
    if stdout.strip():
        print(stdout.strip())
    print("=" * 74)

    # Remove Rplots.pdf if it exists
    if os.path.exists(rplots_path):
        os.remove(rplots_path)

    # -- set up variables for output svm model file
    svm_model_file = os.path.join(args.output, "OUTPUT", f"{mat_filename_wo_ext}_final_svm_model.Rdata")

    # -- file check before next step --
    if not os.path.exists(svm_model_file):
        print(f"\033[1;31m\nERROR: CV-rRF-FS-SVR analysis failed. Program terminated.\033[0m\n", file=sys.stderr)
        end_time = time.time()
        print(f"\nTotal run time: {hms(end_time - start_time)}")
        print(f"\n")
        sys.exit(1)

    # ------ PLSR validation of SVM analysis ------
    print(f"\n")
    print("PLSR machine learning for SVM results evaluation")
    print("=" * 74)
    print(f"SVM model file: {mat_filename_wo_ext}_final_svm_model.Rdata")

    print("Parallel computing: ", end="")
    if psetting == "FALSE":
        print("OFF")
    else:
        print("ON")
        print(f"Cores: {cores}")

    print("PLSR analysis...", end="")

    print(f"\n--------------------- source script: reg_plsr_val_svm.R ---------------------\n")

    plsda_args = [
        svm_model_file,
        mat_filename_wo_ext,
        os.path.join(args.output, "OUTPUT"),
        psetting,
        cores,
        config_vars['cpu_cluster'],
        config_vars['plsda_validation'],
        config_vars['plsda_validation_segment'],
        config_vars['plsda_init_ncomp'],
        config_vars['plsda_ncomp_select_method'],
        config_vars['plsda_ncomp_select_plot_symbol_size'],
        config_vars['plsda_ncomp_select_plot_legend_size'],
        config_vars['plsda_ncomp_select_plot_x_label_size'],
        config_vars['plsda_ncomp_select_plot_x_tick_label_size'],
        config_vars['plsda_ncomp_select_plot_y_label_size'],
        config_vars['plsda_ncomp_select_plot_y_tick_label_size'],
        config_vars['plsda_perm_method'],
        config_vars['plsda_perm_n'],
        config_vars['plsda_perm_plot_symbol_size'],
        config_vars['plsda_perm_plot_legend_size'],
        config_vars['plsda_perm_plot_x_label_size'],
        config_vars['plsda_perm_plot_x_tick_label_size'],
        config_vars['plsda_perm_plot_y_label_size'],
        config_vars['plsda_perm_plot_y_tick_label_size'],
        config_vars['plsda_perm_plot_width'],
        config_vars['plsda_perm_plot_height'],
        config_vars['plsda_scoreplot_ellipse_conf'],
        config_vars['pca_biplot_symbol_size'],
        config_vars['pca_biplot_ellipse'],
        config_vars['pca_biplot_multi_desity'],
        config_vars['pca_biplot_multi_striplabel_size'],
        config_vars['pca_rightside_y'],
        config_vars['pca_x_tick_label_size'],
        config_vars['pca_y_tick_label_size'],
        config_vars['pca_width'],
        config_vars['pca_height'],
        config_vars['plsda_roc_smooth'],
        config_vars['svm_roc_symbol_size'],
        config_vars['svm_roc_legend_size'],
        config_vars['svm_roc_x_label_size'],
        config_vars['svm_roc_x_tick_label_size'],
        config_vars['svm_roc_y_label_size'],
        config_vars['svm_roc_y_tick_label_size'],
        config_vars['plsda_vip_alpha'],
        config_vars['plsda_vip_boot'],
        config_vars['plsda_vip_boot_n'],
        config_vars['plsda_vip_plot_errorbar'],
        config_vars['plsda_vip_plot_errorbar_width'],
        config_vars['plsda_vip_plot_errorbar_label_size'],
        config_vars['plsda_vip_plot_x_textangle'],
        config_vars['plsda_vip_plot_x_label_size'],
        config_vars['plsda_vip_plot_x_tick_label_size'],
        config_vars['plsda_vip_plot_y_label_size'],
        config_vars['plsda_vip_plot_y_tick_label_size'],
        config_vars['plsda_vip_plot_width'],
        config_vars['plsda_vip_plot_height'],
        config_vars['random_state'],
        "--save"
    ]

    stdout, stderr, returncode = run_r_script("./R_files/reg_plsr_val_svm.R", plsda_args, args.output, current_day)

    print("Done!")
    print(f"Additional PLS-DA analysis results saved to file: {mat_filename_wo_ext}_plsr_results.txt\n")
    if stdout.strip():
        print(stdout.strip())
    print("=" * 74)

    # Remove Rplots.pdf if it exists
    if os.path.exists(rplots_path):
        os.remove(rplots_path)

    # end time and display
    end_time = time.time()
    total_time = end_time - start_time

    print(f"\n")
    print(f"Total run time: {hms(total_time)}")
    print(f"\n")


if __name__ == "__main__":
    main()
