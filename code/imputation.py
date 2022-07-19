import os
import time
import numpy as np
import pandas as pd

from sklearn.experimental import enable_iterative_imputer
from sklearn.impute import IterativeImputer
from sklearn.linear_model import LinearRegression, BayesianRidge, Ridge
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import KNNImputer , SimpleImputer

#os.chdir("/home/mateo1/repos/financialinclusionClustering")
os.chdir("C:/Users/mateo/Documents/repos/financialinclusionClustering")

# data
data_all = pd.read_csv("data/data.csv") #exportacion de dataset
data_all =data_all[data_all['year'] ==2021]
data_all.info()

data= data_all.iloc[:, 3:]
index = data_all.iloc[:, :3]

# data[data.debit_card_purch.isnull()]


# imputacion univariada (media y mediana )
imp_avg = SimpleImputer(missing_values=np.nan, strategy='mean')
df_imp_avg = imp_avg.fit_transform(data)
df_com_avg = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_avg).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_avg.columns = data_all.columns
df_com_avg['imputer'] = 'Media'

imp_med = SimpleImputer(missing_values=np.nan, strategy='median')
df_imp_med = imp_med.fit_transform(data)
df_com_med = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_med).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_med.columns = data_all.columns
df_com_med['imputer'] = 'Mediana'

# MICE
start_time = time.time()
lr = LinearRegression()
imp_lr = IterativeImputer(estimator=lr,missing_values=np.nan, max_iter=100, verbose=2, imputation_order='roman',max_value=1, min_value=0,initial_strategy= 'median',random_state=0)
df_imp_mice_lr=imp_lr.fit_transform(data)
df_com_mice_lr = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_mice_lr).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_mice_lr.columns = data_all.columns
df_com_mice_lr['imputer'] = 'MICE-LinearRegression'
end_time = time.time()
print("LR", (end_time - start_time )/60)

# RF
start_time = time.time()
rf =  RandomForestRegressor()
imp_rf = IterativeImputer(estimator=rf,missing_values=np.nan, max_iter=100, verbose=2, imputation_order='roman',max_value=1,min_value=0,initial_strategy= 'median',random_state=0)
df_imp_mice_rf = imp_rf.fit_transform(data)
df_com_mice_rf = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_mice_rf).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_mice_rf.columns = data_all.columns
df_com_mice_rf['imputer'] = 'MICE-RandomForest'
end_time = time.time()
print("RF", (end_time - start_time )/60)


# https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.BayesianRidge.html#sklearn.linear_model.BayesianRidge
start_time = time.time()
br = BayesianRidge()
imp_br = IterativeImputer(estimator=br,missing_values=np.nan, max_iter=100, verbose=2, imputation_order='roman',max_value=1,min_value=0,initial_strategy= 'median',random_state=0)
df_imp_mice_br = imp_br.fit_transform(data)
df_com_mice_br = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_mice_br).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_mice_br.columns = data_all.columns
df_com_mice_br['imputer'] = 'MICE-BayesianRidge'
end_time = time.time()
print("Bayesian Ridge",(end_time - start_time )/60)


#KNN
start_time = time.time()
knn = KNNImputer(n_neighbors=20, add_indicator=False)
df_imp_knn = knn.fit_transform(data)
df_com_knn = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_knn).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_knn.columns = data_all.columns
df_com_knn['imputer'] = 'KNN'
end_time = time.time()
print("KNN",(end_time - start_time )/60)


# Concat
pd.concat([ df_com_avg, df_com_med,
           df_com_mice_lr, df_com_mice_br , df_com_mice_rf,
           df_com_knn], axis=0).to_csv('results/data_imputada_py.csv', index = False)