# DEV prompts

## data transformation updates

**planning:**
Assess the code base and come up with a plan to move the data transformation code (e.g. R_files/input_data_process_2d.R, R_files/input_data_process.R) after train/test split. This is to avoid data leakage and ensure that the data transformation is done only on the training set and then applied to the test set.