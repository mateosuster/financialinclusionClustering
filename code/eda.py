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


os.chdir("C:/Users/mateo/Documents/repos/financialinclusionClustering")

# data
data = pd.read_csv("data/data.csv") #exportacion de dataset


# EDA
data_describe = data.describe() 
data.info()
data.index


# print(f'Hay %d registros sin datos faltantes.'% sum(data.apply(lambda x: x.isnull() ,axis=1)==0))

#pairplot
df_17 = data.loc[:,:,"2017"]

pairplot = sns.pairplot(df_17)
sns.set_context("paper", rc={"axes.labelsize":32, "font.size":8,"axes.titlesize":50})
pairplot.fig.suptitle("Distribución y correlación entre variables", y=1.01) # y= some height>1
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
    