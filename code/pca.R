#limpio la memoria
rm( list=ls() )  #remove all objects
gc()             #garbage collection

require(tidyverse)
library(ggbiplot)
library(ggrepel)



# setwd('/home/mateo1/repos/financialinclusionClustering')
setwd('C:/Users/mateo/Documents/repos/financialinclusionClustering')

#leo el dataset , aqui se puede usar algun super dataset con Feature Engineering
dataset <- read.csv('results/data_imputada.csv') 
glimpse(dataset)



data = dataset[, 4:ncol(dataset) ]
index = dataset[, 1:3]




# select an imputer
data_imp = data %>%
  filter(imputer== "MICE-BayesianRidge")  %>%
  select(-imputer)
glimpse(data_imp)



#######
# PCA #
#######

#matriz de correlaciones aplicada directamente a "datos"
matriz_de_correlaciones = cor(data_imp)
traza_cor  = sum(diag(matriz_de_correlaciones))

#comando que ejecuta el metodo de componentes principales
datos.pc = prcomp(data_imp,scale = T)

#autovalores de la matriz de covarianzas
desc_mat_corr = eigen(matriz_de_correlaciones)
autovalores_corr = desc_mat_corr$values
round(autovalores_corr, 2)

round(datos.pc$sdev^2,2)    # autovalores (solo para verificar)

#cuanta variabilidad concentra cada autovalor?
variabilidad_cor = autovalores_corr/traza_cor


# autovectores / cargas
round(datos.pc$rotation,2) #autovectores (en columna) 


#loadings
## DF con PC

cp_df =data.frame(matrix(nrow=nrow(data_imp)))
name_cols = c()
for (i in 1:length(data_imp)){
  name = paste0("CP", i)
  name_cols = c(name_cols, name)
  
  # carga_df = data.frame(cbind(X=1:length(data_imp),
  #                          carga=data.frame(datos.pc$rotation)[,i]))  #%>% 
    # dplyr::rename(., name = "carga" )
  
  cp_df[name] <-   as.matrix(data_imp)%*%data.frame(datos.pc$rotation)[,i] # LOADINGS
  # cp_df[name] <-   as.matrix(data_imp)%*%as.matrix(carga_df[2])
  # cp_df$name <-   as.matrix(data_imp)%*%as.matrix(carga_df[2])
  # cp_df <- cp_df %>% add_column(name = as.matrix(data_imp)%*%data.frame(datos.pc$rotation)[,i])

}
cp_df <- cp_df %>% select(-1) 


# DF con weight PC
wcp_df =data.frame(matrix(nrow=nrow(data_imp)))
for (i in 1:length(data_imp)){
  name = paste0("CP", i)
  wcp_df[, name] <- cp_df[,i] * autovalores_corr[i]
}
wcp_df <- wcp_df %>% select(-1)
wcp_df


# DF wPC and country
findex_df =data.frame(cbind("Country.Name" = 
                              dataset[dataset$imputer== "MICE-BayesianRidge", "Country.Name"],  
                            "Findex"=  
                              as.double(rowSums(wcp_df)/sum(autovalores_corr)) )) %>% 
  mutate(Findex =as.double(Findex) *-1 )
                
findex_df %>% arrange(-Findex)

library(devtools)

# biplot
ggbiplot(datos.pc, obs.scale=1 ) + 
  geom_point(colour="royalblue" ) + 
  geom_text_repel(aes(label="" )   ) +
  theme(legend.position="none" )


