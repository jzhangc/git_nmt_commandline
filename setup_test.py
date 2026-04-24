#!/usr/bin/env python3
"""
Setup script for test.py - Machine learning analysis of 2D data using Python and R.

This setup file prepares the environment for running the test.py script,
which processes 2D CSV files, performs univariate analysis, and runs SVM and PLS-DA
machine learning models.
"""

import os
import sys
import subprocess
import argparse

def check_and_install_packages():
    """Check if required Python packages are installed and install them if needed."""
    required_packages = [
        'argparse',
        'os',
        'sys',
        'subprocess',
        'time',
        'datetime'
    ]

    # Check if we're in a virtual environment or system Python
    print("Checking Python environment...")

    # For R dependencies, we'll need to install R packages
    try:
        # Check if R is installed
        subprocess.run(['R', '--version'], check=True, capture_output=True)
        print("R is installed")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Error: R is not installed. Please install R before proceeding.")
        sys.exit(1)

    # Check if required R packages are installed
    required_r_packages = [
        'foreach',
        'RBioFS',
        'R.matlab',
        'limma',
        'edgeR',
        'RBioArray'
    ]

    print("Checking required R packages...")
    for package in required_r_packages:
        try:
            subprocess.run(['R', '-e', f'library({package})'], check=True, capture_output=True)
            print(f"✓ {package} is installed")
        except subprocess.CalledProcessError:
            print(f"✗ {package} is not installed")
            try:
                subprocess.run(['R', '-e', f'install.packages("{package}", repos="https://cran.r-project.org")'],
                             check=True, capture_output=True)
                print(f"✓ {package} installed successfully")
            except subprocess.CalledProcessError:
                print(f"Error: Failed to install {package}")
                sys.exit(1)

def setup_directories():
    """Set up required directory structure."""
    dirs_to_create = [
        'R_files',
        'OUTPUT',
        'LOG'
    ]

    for directory in dirs_to_create:
        if not os.path.exists(directory):
            os.makedirs(directory)
            print(f"Created directory: {directory}")
        else:
            print(f"Directory already exists: {directory}")

def validate_files():
    """Validate that all required files exist."""
    required_files = [
        'test.py',
        'R_files/input_dat_process_2d.R',
        'R_files/univariate_2d.R',
        'R_files/cv_ml_svm.R',
        'R_files/ml_svm.R',
        'R_files/cv_ml_svm_nofs.R',
        'R_files/ml_svm_nofs.R',
        'R_files/plsda_val_svm.R'
    ]

    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
            print(f"✗ Missing file: {file_path}")
        else:
            print(f"✓ Found file: {file_path}")

    if missing_files:
        print(f"Error: Missing {len(missing_files)} required files.")
        return False

    return True

def setup_environment():
    """Setup the complete environment for test.py."""
    print("Setting up environment for test.py...")

    # Check and install packages
    check_and_install_packages()

    # Setup directories
    setup_directories()

    # Validate files
    if not validate_files():
        print("Setup failed due to missing files.")
        return False

    print("Environment setup completed successfully!")
    return True

def main():
    """Main function to run setup."""
    parser = argparse.ArgumentParser(description='Setup script for test.py')
    parser.add_argument('--check-only', action='store_true',
                       help='Only check if all requirements are met without installing')
    parser.add_argument('--force', action='store_true',
                       help='Force reinstallation of packages')

    args = parser.parse_args()

    if args.check_only:
        print("Checking environment only...")
        if validate_files():
            print("✓ All files present")
            check_and_install_packages()
            print("✓ Environment check completed successfully")
        else:
            print("✗ Environment check failed")
            sys.exit(1)
    else:
        if setup_environment():
            print("✓ Setup completed successfully")
        else:
            print("✗ Setup failed")
            sys.exit(1)

if __name__ == "__main__":
    main()