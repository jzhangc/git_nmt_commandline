"""
Dev realm for python scripts for NMT

Objectives:
- Set up installation method for py scripts
    [ ] Installation scripts

- Interface with the main applications
    [ ] Call py scripts from main applications
    [ ] Python dependency handlling
    [ ] Main sh functions to check py scripts and dependency integraty

- Set up py scripts
    [ ] Virtual env
    [ ] Call dependencies from folder to the virtual env
    [ ] Call functions from helper py files
    [ ] Handling between R files and py files: data handle over

- Initial setup
    [ ] Working directory - interface from the main application
    [ ] Results and logging directory - interface from the main application

- Data processing
    [ ] Data streaming for bigger datasets (? not sure if needed for sklearn)
    [ ] Data scaling by default
    [ ] Initial data inspections: PCA etc (?)

- Modelling
    [ ] Scikit-learn modelling
        [ ] Construct modelling pipeline
            [ ] Logistic Regression w SGD (stochastic gradient descent) training
            [ ] SVM w SGD (stochastic gradient descent) training
    [ ] Torch modelling
    [ ] Metrics
            
- Visualizaiton functions
    [ ] ROC-AUC
    [ ] PR-AUC
            

- Application
    [ ] Construct commandline applications
    [ ] application speed (not training/testing) optimization

- Other optimizations
    [ ] Implement async/multiprocess functionalities when appropriate


LR: https://www.digitalocean.com/community/tutorials/logistic-regression-with-scikit-learn
https://stackoverflow.com/questions/20894671/speeding-up-sklearn-logistic-regression


Note:
     install env: `conda env create -f ./inst/py_requirements.yml --prefix ./conda_env_nmt`
"""

# ------ import modules ------
import os
import sys
import csv
import pickle
import argparse
import numpy as np
import pandas as pd

from sklearn.linear_model import LogisticRegression, SGDClassifier

# ------ logger ------


# ------ custom classes ------

# ------ custom functions ------

# ------ data ------

# ------ main scripts ------

# ------ test realm ------

