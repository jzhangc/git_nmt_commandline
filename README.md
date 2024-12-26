# Neuro-ML-tools (NMT)

Neuro-ML-tools (NMT): A bash application for automating machine learning analysis for MEG connection data

Please cite the following if you are to use this application:

      Zhang J, Wong SM, Richardson DJ, Rakesh J, Dunkley BT. 2020. Predicting PTSD severity using longitudinal magnetoencephalography with a multi-step learning framework. Journal of Neuro Engineering. 17: 066013. doi: 10.1088/1741-2552/abc8d6.
      Zhang J, Richardson DJ, Dunkley BT. 2020. Classifying post-traumatic stress disorder using the magnetoencephalographic connectome and machine learning. Scientific Reports. 10(1):5937. doi: 10.1038/s41598-020-62713-5.
      Zhang J, Hadj-Moussa H, Storey KB. 2016. Current progress of high-throughput microRNA differential expression analysis and random forest gene selection for model and non-model systems: an R implementation. J Integr Bioinform. 13: 306. doi: 10.1515/jib-2016-306.

## Version History

    - 0.4.0 and beyond
    (ICEBOX)
        - General updates
          - Overall optimization
          - A memory check module to ensure the stability
          - Node file length check added for univariate.R and reg_univariate.R
          - A NMT version without feature selection
          - Compatibility of missing data
          - Add VI for the final model(s): additional models see below
          - Add relative path support
        - Additional classification/regression final models
          - RF
          - XGB
        - Bug fixes

    (ADDED)
        - New "no FS" version of the toolbox added: model only

        - General updates
          - Memory management improvement started to be implemented, more to come
          - Data NA check added for the 2D modules
          - Modelilng speed improvement for all SVM modules
          - Data center_scaling added to PLS modules
          - Error handling improvement for PLS modules
          - To show version number, the shorterned "-v" flag added for all modules
          - New "uni_analysis=TRUE/FALSE" option added to the config file and the toolbox so that univariate analysis can be skipped
          - When "log2_trans=FALSE", the toolbox now would skip quantile normalization
          - For the 2D modules, new filter is now in place to remove all the singular value columns
          - For the 2D modules, the toolbox will now automatically apply 0-1 re-scale
          - A FS bar graph is now automatically generated for the modules with FS
            - Currently, the graph settings are fixed. However, users can go into the model file and re-plot the graph using R pacakge RBioFS
          - Relative path support added for all the modules
          - log2_trans set to FALSE as the default value for all the modules
          - Version number sourced from a single file

        - Updates to the classification module
          - Added single input feature compatibility 
          - Added more error handling in cv_ml_svm.R and ml_svm.R
          - Added interporlated CV ROC-AUC plot to show all outcome labels, mean ROC with +/- ranges
          - Updated the file name suffix to "_plsda_roc_auc_test.txt" for the plsda analysis output file
          - Fixed a bug in univariate_2d.R where univarite "_ml" file does not include sampleid

        - Updates to the regression module
          - Added single input feature compatibility 
          - Added more error handling in cv_reg_ml_svm.R and reg_ml_svm.R
          - Typo fixes for error messages
          - A bug fixed where train_reg.sh fails to read default config values
          - A bug fixed where SFS plotting not included in the "_svm_results.txt" file
        
        - Updates to the prediction module
          - A bug fixed where the prediction module does not work properly

        - Other updates
          - Individual R file version tracking removed
          - Various syntax updates

        - Version bumped to 0.4.0


    - 0.3.2 (July.1.2021)
        - Updates to modelling modules
          - AUC scores now included in .RData model files

        - Updates to prediction modules
          - connectivity_predict.sh now properly processes 3D mat matrices with only one subject to predict

        - Typo fixes
        - Version bumped to 0.3.2


    - 0.3.1 (May.12.2021)
        - More citations added
        - Version bumped to 0.3.1

        
    - 0.3.0 (March.28.2021)
        - General updates
          - Naive data classification module: connectivity_predict.sh predict_class.sh
          - Users now can designate config files via "-m" flag for all modules
            - config file template can be found in application folder as a reference
          - All the 2D commands renamed to "train.sh" format:
              connectivity_ml_2d.sh -> train_class.sh
              connectivity_ml_reg_2d.sh -> train_reg.sh
              cv_connectivity_ml_2d.sh -> cv_train_class.sh
              cv_connectivity_ml_reg_2d.sh -> cv_train_reg.sh
          - Non-nested CV without FS analysis added to all modules
          - Additional flag check added to all sh files
          - Fixed the "invalid ncomp" issue
          - Fixed a bug where parallel computing always uses the max number of cores
          - Other bug fixes 
        
        - Updates to classification modules
          - Additional analysis added to ml_svm.R and cv_ml_svm.R
            - Additional display options added to train, connectivity, cv_train and cv_connectivity 
              commands to accommodate the above
          - A bug fixed where the ROC-AUC won't work for some data in both CV only and regular modes
          - Error handling substantially updated            

    - 0.2.1 (June.10.2020)        
        - General updates
          - Heatmap row now displays connection names for all non-2d modules
          - Log2 transformation updated into "by feature" mode for all modules
          - In the SVM models, item "svm_rf_selected_pairs" changed to "svm_rf_selected_features" 
          - Small bug fixes     


    - 0.2.0
        - New modules
          - "CV only" equivalents added for all the modules:
            - cv_connectivity_ml.sh
            - cv_connectivity_ml_2d.sh
            - cv_connectivity_ml_reg.sh
            - cv_connectivity_ml_reg_2d.sh

        - General updates
          - A separate univariate analysis now integrated to the CV process for all modules. and skipable
          - The existing univariate analysis now mandatory for all modules
          - Univariate prior knowledge flag -k added to all modules
          - Random state added to all modules
          - CV-SVM-rRF-FS heatmap lables fixed for all modules
          - Error handling added to rRF-FS plotting
          - Citation added
        
        - Updates to classification module
          - Best CV model selection functionality added for CV-SVM-rRF-FS for connectivity_ml.sh and connectivity_ml_2d.sh
          - CV-SVM-rRF-FS hierarchical heatmap re-enabled for the classification module
          - Error check added to the PLS-DA module
          - A bug fixed for ml_svm.R where y column was missing during random sampling
          - RFFS heatmap now displays the top colour strip
          - Fixed a bug for univariate modules where supervised hierarchical clustering will fail for contrasts with more than two groups

        - Updates to regression module
          - Best CV model selection functionality added for CV-SVM-rRF-FS for connectivity_ml_reg.sh and connectivity_ml_reg_2d.sh
          - Regression module now correct displays total CV RMSE on the result information page
          - PLSR analysis added to connectivity_ml_reg_2d.sh
          - Error check added to the PLSR module
          - ROC-AUC removed from regression modules
        
        - Other small bug fixes
        
        - Version bumped to 0.2.0 to all modules


    - 0.1
        - General updates
          - SVM now saves training and test data as csv files

        - Updates to connectivity_ml.sh
          - Unsorted annotation file support
          - Resampling is now stratified
          - Error handling added for supervised hierarchical clustering analysis when only one significant result found
          - Small formatting fix for univariate module
          - A bug fixed for supervised clustering analysis where the functionality processes heatmaps using all groups when more than three groups
          - A bug fixed for the display messaging order
          - A bug fixed for univariate.R where it fails to produce significant feature subset when having more then two groups
        
        - Updates to connectivity_ml_2d.sh
          - Unsorted annotation file support
          - Resampling is now stratified
          - Small formatting fix for univariate module
          - Error handling added for supervised hierarchical clustering analysis when only one significant result found
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
