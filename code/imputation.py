

import os

import numpy as np
import pandas as pd

from sklearn.experimental import enable_iterative_imputer
from sklearn.impute import IterativeImputer
from sklearn.linear_model import LinearRegression
from sklearn.impute import KNNImputer , SimpleImputer

os.chdir("C:/Users/mateo/Documents/repos/financialinclusionClustering")


# data
data_all = pd.read_csv("data/data.csv") #exportacion de dataset
data_all =data_all[data_all['year'] ==2017]
data_all.info()

data= data_all.iloc[:, 3:]
index = data_all.iloc[:, :3]

data[data.debit_card_purch.isnull()]


# imputacion univariada (media y mediana )
imp_avg = SimpleImputer(missing_values=np.nan, strategy='mean')
df_imp_avg = imp_avg.fit_transform(data)
df_com_avg = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_avg).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_avg.columns = data_all.columns
df_com_avg['imputer'] = 'Media'

# MICE
lr = LinearRegression()
imp = IterativeImputer(estimator=lr,missing_values=np.nan, max_iter=10, verbose=2, imputation_order='roman',random_state=0)
df_imp_mice=imp.fit_transform(data)
df_com_mice = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_mice).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_mice.columns = data_all.columns
df_com_mice['imputer'] = 'MICE'


#KNN
knn = KNNImputer(n_neighbors=10, add_indicator=False)
df_imp_knn = knn.fit_transform(data)
df_com_knn = pd.concat([index.reset_index(drop=True), pd.DataFrame(df_imp_knn).reset_index(drop=True) ], axis =1, ignore_index= True)
df_com_knn.columns = data_all.columns
df_com_knn['imputer'] = 'KNN'


# Concat
pd.concat([ df_com_avg, df_com_mice , df_com_knn], axis=0).to_csv('results/data_imputada.csv', index = False)