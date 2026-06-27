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
        [ ] Accuracy
        [ ] RMSE/MSE
        [ ] PR, ROC -> AUC
        [ ] F1 (and/or generalized F metric)
        [ ] SHAP feature importance
        [ ] Fairness (?)
        [ ] Benefits (?)
            
- Visualizaiton functions
    [ ] ROC-AUC w and wo interporlation
        [ ] Multi-model curves
    [ ] PR-AUC w and wo interporlation    
        [ ] Multi-model curves    
    [ ] SHAP plot for feature importance

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
import shap
import numpy as np
import pandas as pd
import sklearn as skl

from sklearn.linear_model import LogisticRegression, SGDClassifier, LinearRegression
from interpret import glassbox

# ------ logger ------


# ------ custom classes ------

# ------ custom functions ------

# ------ data ------

# ------ main scripts ------

# ------ test realm ------


# ---- data: California housing price ----
X, y = shap.datasets.california(n_points=1000)
X100 = shap.utils.sample(X, 100)
X.head(5)

# ---- linear regression model ----
model = LinearRegression()
model.fit(X, y)

for i in range(X.shape[1]):
    print(f'{X.columns[i]} = {model.coef_[i].round(5)}')
"""
MedInc = 0.42563
HouseAge = 0.01033
AveRooms = -0.1161
AveBedrms = 0.66385
Population = 3e-05
AveOccup = -0.26096
Latitude = -0.46734
Longitude = -0.46272
"""


"""
shap.plots.partial_dependence(ind, model, 
data, xmin='percentile(0)', 
xmax='percentile(100)', npoints=None, 
feature_names=None, hist=True, 
model_expected_value=False, feature_expected_value=False, 
shap_values=None, ylabel=None, ice=True, ace_opacity=1, 
pd_opacity=1, pd_linewidth=2, ace_linewidth='auto',
ax=None, show=True)
"""
shap.partial_dependence_plot(
    "HouseAge",
    model.predict,
    X100,
    ice=False,
    model_expected_value=True,
    feature_expected_value=True,
)

# compute the SHAP values for the linear model
explainer = shap.Explainer(model.predict, X100)
shap_values = explainer(X)

# make a standard partial dependence plot
sample_ind = 20
shap.partial_dependence_plot(
    "HouseAge",
    model.predict,
    X100,
    model_expected_value=True,
    feature_expected_value=True,
    ice=False,
    shap_values=shap_values[sample_ind : sample_ind + 1, :],
)

shap.plots.scatter(shap_values[:, "Population"])


# the waterfall_plot shows how we get from shap_values.base_values to model.predict(X)[sample_ind]
shap.plots.waterfall(shap_values[sample_ind], max_display=14)

# the beeswarm plot displays SHAP values for each feature across all examples,
# with colors indicating how the SHAP values correlate with feature values
shap.plots.beeswarm(shap_values)

# ---- generalized additive regression (GAM) model ----
"""
GAM example: explainable boosting machine (EBM) 
"""

# fit a GAM model to the data
model_ebm = glassbox.ExplainableBoostingRegressor(interactions=0)
model_ebm.fit(X, y)

