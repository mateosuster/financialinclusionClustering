require("data.table")
require("randomForest")
library(tidyverse)
library(cluster)    # clustering algorithms
library(factoextra) # clustering visualization  

#limpio la memoria
rm( list=ls() )  #remove all objects
gc()             #garbage collection

setwd('/home/mateo1/repos/financialinclusionClustering')

#leo el dataset , aqui se puede usar algun super dataset con Feature Engineering
dataset <- read.csv('results/data_imputada_2.csv') 
glimpse(dataset)

data = dataset[, 3:ncol(dataset) ]
index = dataset[, 1:3]

#quito los nulos para que se pueda ejecutar randomForest,  Dios que algoritmo prehistorico ...
# dataset  <- na.roughfix( dataset )
# dataset  <- na.omit(dataset) 
gc()

rf_list = list()
dist_list = list()
hclust_list = list()
sil_list = list()

df_sil <- data.frame(matrix(ncol = 3, nrow = 0))
colnames(df_sil) <- c("imputer", "ncluster", "avg_sil")

for(imputer_i in unique(data$imputer)){
  print(imputer_i)
  
  modelo  <- randomForest( x= data %>%
                             filter(imputer== imputer_i)  %>%
                             select(-imputer)
                           ,
                           y= NULL,
                           ntree= 100, #se puede aumentar a 10000
                           proximity= TRUE,
                           oob.prox = TRUE )

  
  #genero los clusters jerarquicos
  dist_mtrx <-  as.dist ( 1.0 - modelo$proximity) #distancia = 1.0 - proximidad
  
  hclust.rf  <- hclust( dist_mtrx,
                        method= "ward.D2" )
  
  for (nclust in c(2:15)){
    print(nclust)
    rf.cluster  <- cutree( hclust.rf, nclust) #corto los arboles
    sil <- silhouette (rf.cluster,dist_mtrx) # or use your cluster vector
    sil_avg <- summary(sil)[[4]]
    
    row <- c("imputer" = imputer_i, "ncluster"=nclust, "avg_sil" = sil_avg) 
    df_sil <-  rbind(df_sil, data.frame(t(row)) )
  }
    
  
  rf_list[[imputer_i]] = modelo
  dist_list[[imputer_i]] = dist_mtrx
  hclust_list[[imputer_i]] = hclust.rf
  # sil_list[[imputer_i]] = df_sil
  
  # df_sil <- data.frame(matrix(ncol = 3, nrow = 0))
  # colnames(df_sil) <- c("imputer", "ncluster", "avg_sil")
  
}

#grafico silhoutte
df_sil %>% 
  mutate_at(.vars = c("ncluster", "avg_sil"), .funs = as.double) %>% 
  ggplot(aes(ncluster, avg_sil, color = imputer)) +
  geom_line()+ geom_point()+
  theme(legend.position = 'bottom')+
  labs(y = 'Silhouette promedio', x = 'Cantidad de clústers')
ggsave(filename = 'results/sil_avg.jpg')


# cluster plot for max sil
for (dist_list , hclust_list ){
  print(nclust)
  rf.cluster  <- cutree( hclust.rf, nclust) #corto los arboles
  sil <- silhouette (rf.cluster,dist_mtrx) # or use your cluster vector
  sil_avg <- summary(sil)[[4]]
  
  row <- c("imputer" = imputer_i, "ncluster"=nclust, "avg_sil" = sil_avg) 
  df_sil <-  rbind(df_sil, data.frame(t(row)) )
}

  







# DMeyf
h <- 20
distintos <- 0
dataset <- as.data.table(data %>% 
                           filter(imputer== "Complete")  %>% 
                           select(-imputer))

while(  h>0  &  !( distintos >=6 & distintos <=7 ) )
{
  h <- h - 1 
  rf.cluster  <- cutree( hclust.rf, h)
  
  dataset[  , cluster2 := NULL ]
  dataset[  , cluster2 := rf.cluster ]
  
  distintos  <- nrow( dataset[  , .N,  cluster2 ] )
  cat( distintos, " " )
}

#en  dataset,  la columna  cluster2  tiene el numero de cluster
#sacar estadicas por cluster

dataset[  , .N,  cluster2 ]  #tamaño de los clusters

#ahora a mano veo las variables
dataset[  , mean(ctrx_quarter),  cluster2 ]  #media de la variable  ctrx_quarter

