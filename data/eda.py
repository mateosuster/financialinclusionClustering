# -*- coding: utf-8 -*-
"""
Created on Sun Apr 17 23:33:01 2022

@author: mateo
"""

import wbdata
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.cluster.hierarchy import dendrogram, linkage
from sklearn.cluster import AgglomerativeClustering
import os

plt.rcParams["figure.figsize"] = (17,7)
os.chdir("C:/Users/mateo/Documents/repos/financialinclusionClustering")

# rcParams['figure.figsize'] = 40, 12

# wbdata.get_source()  

# indicadores = pd.DataFrame(wbdata.get_indicator(source=28) )

# ind_dic ={}
# for i in indicadores.loc[:,"id"].values:
#     ind_dic[i]= i 
    

# data = wbdata.get_dataframe(ind_dic , country=['USA','ARG'])

# wbdata.get_data("IC.BUS.EASE.XQ", country="USA")


# levanto datasets
series = pd.read_csv("data/FINDEXSeries.csv")
countries = pd.read_csv("data/FINDEXCountry.csv")
raw_data= pd.read_csv("data/FINDEXData.csv")

# selecciono variables
var_dict = {
             #indicadores de acceso y uso de servicios financieros        
             "account.t.d" :"account", # Account
             "fin1.t.a": "fin_account", #Financial institution account 
             "fin17a.t.a": "saved_fin_acc", #Saved at a financial institution (% age 15+)
             "fin22a.t.d": "borrowed_fin_acc", #Borrowed from a financial institution or used a credit card (% age 15+)
             
             #aditional variables
             "fin18.t.d": "saved_any_money", #Saved any money in the past year (% age 15+)
             "fin23.t.d": "borrowed_any_money", #Borrowed any money in the past year (% age 15+)
             # "fin2.t.a", #Debit card ownership 
             "fin4.t.a" :"debit_card_purch", #Debit card used to make a purchase in the past year (% age 15+)
             # "fin7.t.a", #Credit card ownership (% age 15+)
             "fin8.t.a": "credit_card_purch", #Credit card used in the past year (% age 15+)
             }



var_list = list(var_dict.keys())
gender_variables= [] 
labor_variables= []
educational_variables = []
income_variables= []
for v in var_list :
    gender_variables.append(v+".1") #Male
    gender_variables.append(v+".2") #Female        
    labor_variables.append(v+".10") #in labor force
    labor_variables.append(v+".11") #out of labor force
    educational_variables.append(v+".5") #primary education or less
    educational_variables.append(v+".6") #secondary education or more
    income_variables.append(v+".7") #poorest 40% 
    income_variables.append(v+".8") #richest 60%


var_desc = series[series["Series Code"].isin(var_list)] #desclasificador de variables


#preprocesamiento
raw_data.drop(["Unnamed: 7"], axis=1, inplace=True)
raw_data=raw_data.melt(id_vars = ["Country Name", "Country Code","Indicator Name", "Indicator Code"], value_vars = ["2011", "2014", "2017"], var_name="year")

filter_data = raw_data[(raw_data["Indicator Code"].isin( var_list)) &(raw_data["Country Code"].isin(countries.loc[countries["Region"].notnull() , "Country Code"].values)) ]
# data = filter_data.drop("Indicator Code", axis=1).pivot(index = ["Country Name", "Country Code", "year"] , columns = "Indicator Name", values ="value")#.reset_index()
data = filter_data.drop("Indicator Name", axis=1).pivot(index = ["Country Name", "Country Code", "year"] , columns = "Indicator Code", values ="value")#.reset_index()
data.rename(columns = var_dict,inplace=True)

data.to_csv("data/data.csv") #exportacion de dataset



# EDA
data_describe = data.describe() 
data.info()
data.index


# print(f'Hay %d registros sin datos faltantes.'% sum(data.apply(lambda x: x.isnull() ,axis=1)==0))

#pairplot
df_17 = data.loc[:,:,"2017"]

pairplot = sns.pairplot(df_17)
sns.set_context("paper", rc={"axes.labelsize":32, "font.size":8,"axes.titlesize":50})
pairplot.fig.suptitle("Distribuci??n y correlaci??n entre variables", y=1.01) # y= some height>1
sns.set(font_scale=1.3)

# pairplot.save_fig('results/pairplot.png')
# figure = pairplot.get_figure()    
# figure.savefig('pairplot.png', dpi=400)



# clustering
# regiones = countries["Region"].unique()
# lut = dict(zip(regiones, sns.hls_palette(len(set(regiones)), l=0.5, s=0.8)))

df_17 = pd.merge(df_17.reset_index().dropna(), countries[["Country Code", "Region"]] , how ="left", on = "Country Code")

region = df_17.pop("Region")
palette = sns.cubehelix_palette(len(region.unique() )  )
lut = dict(zip(region.unique() , palette ))
row_colors = pd.Series(region).map(lut)

data = df_17.dropna().drop("Country Code",1 ).set_index("Country Name") # DATA 2017

sns.clustermap(data, method="centroid", metric="euclidean",  cmap='coolwarm', row_colors=row_colors )

# Scipy
#Dendograma.
#Linkage Matrix
model = linkage(data, method= 'ward')

#plotting dendrogram
dendro = dendrogram(model, labels=data.index, leaf_rotation=90, leaf_font_size=12)
plt.tight_layout()
plt.ylabel('Euclidean distance')
plt.xticks(rotation=90)
plt.savefig('results/dendogram.png', dpi=199)
plt.show()

#sklearn
# cluster aglomerativo
agg_clustering = AgglomerativeClustering(n_clusters = 2, affinity = 'euclidean', linkage = 'ward')
labels=agg_clustering.fit_predict(data)
pd.Series(labels).value_counts()
data["cluster"] =labels

data['cluster'].value_counts()
    