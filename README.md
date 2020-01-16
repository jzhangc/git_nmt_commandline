# meg_application

A bash application for automating machine learning analysis for MEG connection data

------ Version History ------

- 0.2
  (ICEBOX)
  - General updates
    - Spinner added as a running status indication
    - Overall optimization
    - A memory check module to ensure the stability
    - Node file length check added for univariate.R and reg_univariate.R
    - Fix the "invalide ncomp" issue

  - Add univariate ananlysis inside the CV-SVM-rRF-FS process for all modules

  - Bug fixes

  (ADDED)
  - General updates
    - A separate univariate analysis now integrated to the CV process for all modules. and skippable
    - The existing univariate analysis now mandatory for all modules
  
  - Updates to classification module
    - Best CV model selection functionality added for CV-SVM-rRF-FS for connectivity_ml.sh and connectivity_ml_2d.sh
    - A bug fixed for ml_svm.R where y column was missing during random sampling

  - Updates to regression module
    - Best CV model selection functionality added for CV-SVM-rRF-FS for connectivity_ml_reg.sh and connectivity_ml_reg_2d.sh

- 0.1
  - General updates
    - SVM now saves training and test data as csv files

  - Updates to connectivity_ml.sh
    - Unsorted annotation file support
    - Resampling is now stratified
    - Error handling added for supervised hierarchical clustering analysis when only one significant resutl found
    - Small formatting fix for univariate module
    - A bug fixed for supervised clustering analysis where the functionality processes heatmaps using all groups when more than three groups
    - A bug fixed for the display messaging order
    - A bug fixed for univariate.R where it fails to produce significant feature subset when having more then two groups
  
  - Updates to connectivity_ml_2d.sh
    - Unsorted annotation file support
    - Resampling is now stratified
    - Small formatting fix for univariate module
    - Error handling added for supervised hierarchical clustering analysis when only one significant resutl found
    - A bug fixed for supervised clustering analysis where the functionality processes heatmaps using all groups when more than three groups
    - A bug fixed for univariate_2D.R where it fails to produce significant feature subset when having more then two groups
  
  - Updates to the regression module
    - PLSR functionality added so PLS VIP and permutation are done as a validation for SVM-rRF-FS process
    - Accordingly, new R file reg_plsr_val_svm.R added

  - Version bumpped to 0.1.0 for all modules

- 0.0.3
  - General updates
    - The non-2D applications now able to take node file
      - All related sh and R files updated for this update
    - SVM process now export the nested cross-validation results as part of the model files
    - Directory structure updated
    - R files put to the folder: R_files
      - All sh files updated for this change

  - New module connectivity_ml_2d.sh added
    - input_dat_process_2d.R added

  - New module connectivity_ml_reg_2d.sh added
    - reg_input_dat_process_2d.R added

  - Updates to connectivity_ml.sh (and the associated R modules)
    - Updates to connectivity_ml.sh
      - Check added for annotation file and input sample size

    - Updates to input_dat_process.R
      - Check added for annotation file and input sample size

  - Updates to connectivity_ml_reg.sh (and the associated R modules)
    - Updates to connectivity_ml_reg.sh
      - Check added for annotation file and input sample size

    - Updates to reg_input_dat_process.R
      - Check added for annotation file and input sample size

  - A bugs fixed for reg_ml_svm.R, now with correct error metric

- 0.0.2 (May.22.2019)
  - Updates to connectivity_ml.sh (and the associated R modules)
    - Updates to univariate.R
      - Weights now incorporated for univariate analysis

  - Updates to connectivity_ml_reg.sh (and the associated R modules)
    - Updates to reg_univariate.R
      - Weights now incorporated for univariate analysis

    - Updates to reg_ml_svm.R
      - Hierarchical clustering added after SVM
      - Subsetted data with selected connections now exported as a CSV file for the subsequent deep learning steps
      - Code base optimization

  - Version bumped to 0.0.2 for all modules

  - Bug fixes

- 0.0.1
  - Initial commit
