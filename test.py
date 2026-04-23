#!/usr/bin/env python3
"""
Python version of train_class_x.sh script for machine learning analysis of 2D data.
This script processes 2D CSV files, performs univariate analysis, and runs SVM and PLS-DA machine learning models.
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

def setup_output_directories(out_dir):
    """Create required output directories."""
    os.makedirs(os.path.join(out_dir, "LOG"), exist_ok=True)
    os.makedirs(os.path.join(out_dir, "OUTPUT"), exist_ok=True)

def run_r_script(script_path, args):
    """Execute an R script with given arguments."""
    cmd = ["Rscript", script_path] + args
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout, result.stderr
    except subprocess.CalledProcessError as e:
        print(f"Error running R script {script_path}: {e}")
        print(f"STDOUT: {e.stdout}")
        print(f"STDERR: {e.stderr}")
        raise

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Machine learning analysis for 2D data')
    parser.add_argument('-i', '--input', required=True, help='Input 2D .csv file')
    parser.add_argument('-s', '--sample-id', required=True, help='Sample ID variable name')
    parser.add_argument('-g', '--group-id', required=True, help='Group ID variable name')
    parser.add_argument('-c', '--contrast', required=True, help='Contrasts')
    parser.add_argument('-k', '--prior-knowledge', action='store_true', help='Incorporate univariate prior knowledge to SVM analysis')
    parser.add_argument('-u', '--univariate', action='store_true', help='Use univariate analysis result during CV-SVM-rRF-FS')
    parser.add_argument('-x', '--cross-validation-only', action='store_true', help='Cross-validation only')
    parser.add_argument('-l', '--nofs', action='store_true', help='No feature selection mode')
    parser.add_argument('-m', '--config', help='Optional configuration file')
    parser.add_argument('-o', '--output', default='.', help='Optional output directory')
    parser.add_argument('-p', '--parallel', type=int, help='Parallel computing with core numbers')

    args = parser.parse_args()

    # Initialize variables
    start_time = time.time()
    current_day = datetime.now().strftime("%d-%b-%Y")

    # Set up output directories
    setup_output_directories(args.output)

    # Load configuration
    config_vars = {}
    if args.config and os.path.exists(args.config):
        config_vars = read_config_file(args.config)

    # Set default values for configuration variables
    config_defaults = {
        'random_state': '1',
        'minmax_norm': 'TRUE',
        'zscore_standardization': 'FALSE',
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
        'pca_scale_data': 'TRUE',
        'pca_centre_data': 'TRUE',
        'pca_pc': 'c(1, 2)',
        'pca_biplot_samplelabel_type': 'none',
        'pca_biplot_samplelabel_size': '2',
        'pca_biplot_symbol_size': '5',
        'pca_biplot_ellipse': 'TRUE',
        'pca_biplot_ellipse_conf': '0.95',
        'pca_biplot_loading': 'FALSE',
        'pca_biplot_loading_textsize': '3',
        'pca_biplot_multi_desity': 'TRUE',
        'pca_biplot_multi_striplabel_size': '10',
        'pca_rightside_y': 'FALSE',
        'pca_x_tick_label_size': '10',
        'pca_y_tick_label_size': '10',
        'pca_width': '170',
        'pca_height': '150',
        'uni_fdr': 'TRUE',
        'uni_alpha': '0.05',
        'uni_fold_change': '1',
        'volcano_n_top_connection': '10',
        'volcano_symbol_size': '2',
        'volcano_sig_colour': 'red',
        'volcano_nonsig_colour': 'gray',
        'volcano_x_text_size': '10',
        'volcano_y_text_size': '10',
        'volcano_width': '170',
        'volcano_height': '150',
        'sig_htmap_textsize_col': '0.5',
        'sig_htmap_textangle_col': '90',
        'sig_htmap_textsize_row': '0.5',
        'sig_htmap_keysize': '1.5',
        'sig_htmap_key_xlab': 'Z score',
        'sig_htmap_key_ylab': 'Count',
        'sig_htmap_margin': 'c(4, 8)',
        'sig_htmap_width': '6',
        'sig_htmap_height': '5',
        'sig_pca_pc': 'c(1, 2)',
        'sig_pca_biplot_ellipse_conf': '0.9',
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
        'svm_perm_plot_width': '170',
        'svm_perm_plot_height': '150',
        'svm_roc_smooth': 'FALSE',
        'svm_roc_symbol_size': '2',
        'svm_roc_legend_size': '9',
        'svm_roc_x_label_size': '10',
        'svm_roc_x_tick_label_size': '10',
        'svm_roc_y_label_size': '10',
        'svm_roc_y_tick_label_size': '10',
        'svm_roc_width': '170',
        'svm_roc_height': '150',
        'svm_rffs_pca_pc': 'c(1, 2)',
        'svm_rffs_pca_biplot_ellipse_conf': '0.95',
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
        'plsda_scoreplot_ellipse_conf': '0.9',
        'plsda_roc_smooth': 'FALSE',
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

    # Set flag variables
    kflag = 1 if args.prior_knowledge else 0
    xflag = 1 if args.cross_validation_only else 0
    lflag = 1 if args.nofs else 0
    psetting = "TRUE" if args.parallel else "FALSE"
    cores = str(args.parallel) if args.parallel else "1"

    # Set up variables for file processing
    raw_file = os.path.abspath(args.input)
    mat_filename = os.path.basename(raw_file)
    mat_filename_wo_ext = os.path.splitext(mat_filename)[0]

    # Display initial information
    print(f"\nYou are running train_class.sh")
    print(f"Version: 0.5.x-260423")
    print(f"Current OS: Unknown UNIX or UNIX-like system")
    print(f"Today is: {current_day}\n")

    # Process input data file
    print("--------------------- source script: input_dat_process_2d.R ---------------------")

    r_args = [
        raw_file,
        mat_filename_wo_ext,
        args.sample_id,
        args.group_id,
        os.path.join(args.output, "OUTPUT"),
        config_vars['minmax_norm'],
        config_vars['zscore_standardization'],
        args.contrast
    ]

    try:
        stdout, stderr = run_r_script("./R_files/input_dat_process_2d.R", r_args)
        print("Input data processed successfully")

        # Process univariate analysis
        print("Unsupervised learning and univariate analysis")
        print(f"Processing data file: {mat_filename_wo_ext}_2D.csv")

        dat_2d_file = os.path.join(args.output, "OUTPUT", f"{mat_filename_wo_ext}_2D.csv")
        if not os.path.exists(dat_2d_file):
            print("ERROR: File processing failed. Program terminated.")
            sys.exit(1)

        # Run univariate analysis
        univariate_args = [
            dat_2d_file,
            mat_filename_wo_ext,
            "",  # ANNOT_FILE (empty for now)
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
            config_vars['pca_scale_data'],
            config_vars['pca_centre_data'],
            config_vars['pca_pc'],
            config_vars['pca_biplot_samplelabel_type'],
            config_vars['pca_biplot_samplelabel_size'],
            config_vars['pca_biplot_symbol_size'],
            config_vars['pca_biplot_ellipse'],
            config_vars['pca_biplot_ellipse_conf'],
            config_vars['pca_biplot_loading'],
            config_vars['pca_biplot_loading_textsize'],
            config_vars['pca_biplot_multi_desity'],
            config_vars['pca_biplot_multi_striplabel_size'],
            config_vars['pca_rightside_y'],
            config_vars['pca_x_tick_label_size'],
            config_vars['pca_y_tick_label_size'],
            config_vars['pca_width'],
            config_vars['pca_height'],
            args.contrast,
            config_vars['uni_fdr'],
            config_vars['uni_alpha'],
            config_vars['uni_fold_change'],
            config_vars['volcano_n_top_connection'],
            config_vars['volcano_symbol_size'],
            config_vars['volcano_sig_colour'],
            config_vars['volcano_nonsig_colour'],
            config_vars['volcano_x_text_size'],
            config_vars['volcano_y_text_size'],
            config_vars['volcano_width'],
            config_vars['volcano_height'],
            config_vars['sig_htmap_textsize_col'],
            config_vars['sig_htmap_textangle_col'],
            config_vars['sig_htmap_textsize_row'],
            config_vars['sig_htmap_keysize'],
            config_vars['sig_htmap_key_xlab'],
            config_vars['sig_htmap_key_ylab'],
            config_vars['sig_htmap_margin'],
            config_vars['sig_htmap_width'],
            config_vars['sig_htmap_height'],
            config_vars['sig_pca_pc'],
            config_vars['sig_pca_biplot_ellipse_conf'],
            config_vars['uni_analysis']
        ]

        run_r_script("./R_files/univariate_2d.R", univariate_args)
        print("Univariate analysis completed")

        # Set up variables for machine learning data file
        if kflag == 1:
            dat_ml_file = os.path.join(args.output, "OUTPUT", f"{mat_filename_wo_ext}_2D.csv")
        else:
            dat_ml_file = os.path.join(args.output, "OUTPUT", f"{mat_filename_wo_ext}_w_prior.csv")

        if not os.path.exists(dat_ml_file):
            print("ERROR: Unsupervised analysis failed. Program terminated.")
            sys.exit(1)

        # Run SVM machine learning analysis
        print("CV-rRF-FS-SVM machine learning")

        # Determine which script to use
        if xflag == 0:
            if lflag == 0:
                ml_script = "cv_ml_svm.R"
            else:
                ml_script = "cv_ml_svm_nofs.R"
        else:
            if lflag == 0:
                ml_script = "ml_svm.R"
            else:
                ml_script = "ml_svm_nofs.R"

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
            config_vars['svm_roc_smooth'],
            config_vars['svm_roc_symbol_size'],
            config_vars['svm_roc_legend_size'],
            config_vars['svm_roc_x_label_size'],
            config_vars['svm_roc_x_tick_label_size'],
            config_vars['svm_roc_y_label_size'],
            config_vars['svm_roc_y_tick_label_size'],
            config_vars['svm_roc_width'],
            config_vars['svm_roc_height'],
            config_vars['pca_scale_data'],
            config_vars['pca_centre_data'],
            config_vars['pca_biplot_samplelabel_type'],
            config_vars['pca_biplot_samplelabel_size'],
            config_vars['pca_biplot_symbol_size'],
            config_vars['pca_biplot_ellipse'],
            config_vars['pca_biplot_loading'],
            config_vars['pca_biplot_loading_textsize'],
            config_vars['pca_biplot_multi_desity'],
            config_vars['pca_biplot_multi_striplabel_size'],
            config_vars['pca_rightside_y'],
            config_vars['pca_x_tick_label_size'],
            config_vars['pca_y_tick_label_size'],
            config_vars['pca_width'],
            config_vars['pca_height'],
            config_vars['svm_rffs_pca_pc'],
            config_vars['svm_rffs_pca_biplot_ellipse_conf'],
            config_vars['uni_analysis'],  # This should be set properly
            config_vars['log2_trans'],
            args.contrast,
            config_vars['uni_fdr'],
            config_vars['uni_alpha'],
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
            config_vars['random_state']
        ]

        run_r_script(f"./R_files/{ml_script}", svm_args)
        print("SVM analysis completed")

        # Run PLS-DA machine learning analysis
        print("PLS-DA machine learning for SVM results evaluation")

        # Determine model file name
        if xflag == 0:
            if lflag == 0:
                svm_model_file = os.path.join(args.output, "OUTPUT", f"cv_only_nofs_{mat_filename_wo_ext}_final_svm_model.Rdata")
            else:
                svm_model_file = os.path.join(args.output, "OUTPUT", f"cv_only_{mat_filename_wo_ext}_final_svm_model.Rdata")
        else:
            if lflag == 0:
                svm_model_file = os.path.join(args.output, "OUTPUT", f"nofs_{mat_filename_wo_ext}_final_svm_model.Rdata")
            else:
                svm_model_file = os.path.join(args.output, "OUTPUT", f"{mat_filename_wo_ext}_final_svm_model.Rdata")

        if not os.path.exists(svm_model_file):
            print("ERROR: CV-rRF-FS-SVM analysis failed. Program terminated.")
            sys.exit(1)

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
            config_vars['random_state']
        ]

        stdout, stderr = run_r_script("./R_files/plsda_val_svm.R", plsda_args)
        print("PLS-DA analysis completed")

        # Display completion message
        end_time = time.time()
        total_time = end_time - start_time
        hours = int(total_time // 3600)
        minutes = int((total_time % 3600) // 60)
        seconds = int(total_time % 60)

        print(f"\nTotal run time: {hours:02d}:{minutes:02d}:{seconds:02d}")
        print("\nAnalysis completed successfully!")

    except subprocess.CalledProcessError as e:
        print(f"Error in R script execution: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()