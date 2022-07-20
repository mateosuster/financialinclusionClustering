
#limpio la memoria
rm( list=ls() )  #remove all objects
gc()             #garbage collection

# require("data.table")
require("randomForest")
require(tidyverse)
require(cluster)    # clustering algorithms
require(factoextra) # clustering visualization  
library(xtable)


# setwd('/home/mateo1/repos/financialinclusionClustering')
setwd('C:/Users/mateo/Documents/repos/financialinclusionClustering')

#leo el dataset , aqui se puede usar algun super dataset con Feature Engineering
dataset <- read.csv('results/data_imputada.csv') %>% 
  na.omit() 
glimpse(dataset)

# dataset %>% 
#   filter(imputer == "Sin imputación") %>% 
#   na.omit() %>% 
#   nrow()

data = dataset[, 4:ncol(dataset) ]
# row.names(data) = index$Country.Code
index = dataset[, 1:3]


#quito los nulos para que se pueda ejecutar randomForest,  Dios que algoritmo prehistorico ...
# dataset  <- na.roughfix( dataset )
# dataset  <- na.omit(dataset) 
gc()

rf_list = list()
dist_list = list()
hclust_list = list()
sil_list = list()
corr_coph = list()

df_corr_coph <- data.frame(imputer = numeric(0),    # Create empty data frame
                           corr_coph = numeric(0) )


df_sil <- data.frame(matrix(ncol = 3, nrow = 0))
colnames(df_sil) <- c("imputer", "ncluster", "avg_sil")

for(imputer_i in unique(data$imputer)){
  print(imputer_i)
  
  data_i =data %>%
    filter(imputer== imputer_i)  %>%
    select(-c(imputer))
  rownames(data_i) =dataset[dataset$imputer== imputer_i, "Country.Name"]
  
  modelo  <- randomForest( x= data_i ,
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
    
  df_sil <- df_sil %>%   
    mutate_at(.vars = c("ncluster", "avg_sil"), .funs = as.double)
  
  rf_list[[imputer_i]] = modelo
  dist_list[[imputer_i]] = dist_mtrx
  hclust_list[[imputer_i]] = hclust.rf
  # sil_list[[imputer_i]] = df_sil
  
  
  df_corr_coph[nrow(df_corr_coph)+1, ] <- c(imputer_i  , cor(cophenetic(hclust.rf), dist_mtrx) ) 
  # df_sil <- data.frame(matrix(ncol = 3, nrow = 0))
  # colnames(df_sil) <- c("imputer", "ncluster", "avg_sil")
  
}

# corr cofenética
df_corr_coph <- df_corr_coph %>%
  mutate(corr_coph = as.double(corr_coph)) %>% 
  arrange(-corr_coph)
write_delim(df_corr_coph, file = "results/cophenetic_corr.csv", delim = "&")
print(xtable(df_corr_coph), include.rownames = F)


#grafico silhoutte
df_sil  %>% 
  ggplot(aes(ncluster, avg_sil, color = imputer)) +
  geom_line()+ geom_point()+
  theme(legend.position = 'bottom')+
  labs(y = 'Silhouette promedio', x = 'Cantidad de clústers')
ggsave(filename = 'results/sil_avg.jpg')

df_sil %>% 
  group_by(ncluster) %>% 
  dplyr::summarise(avg = mean(avg_sil, na.rm  = T),
                   med = median(avg_sil, na.rm  = T)) %>% 
  arrange(-avg)

# Silhouette method
for(imputer_i in unique(data$imputer)){
  print( 
  fviz_nbclust(data %>%
                 # filter(imputer== 'Complete')  %>%
                 filter(imputer== imputer_i )  %>%
                 select(-c(imputer))
               , hcut, method = "silhouette")+
    labs(subtitle = paste("Silhouette method for cluster with", imputer_i, "imputer" ))
  )
}



require(NbClust)
Nb_list = list()
for(imputer_i in unique(data$imputer)){
  if (imputer_i != "Sin imputación"){
    
    cat(imputer_i)
    
    
    Nb_list[[imputer_i]] = NbClust(data = data %>%
                                     filter(imputer== imputer_i )  %>%
                                     select(-c(imputer)),
                                   diss = dist_list[[imputer_i]], 
                                  distance = NULL,
                                min.nc = 2, max.nc = 15,
                                method = "ward.D2")
  }
}
Nb_list[['Complete']]$All.index


# cluster plot for max sil
optimal_cluster = 3
data$cluster = NA
cut_clust_list = list()
# for (cluster_method in  hclust_list ){
for(imputer_i in unique(data$imputer)){  
  cluster_method =  hclust_list[[imputer_i]] 
  rf.cluster  <- cutree( cluster_method, optimal_cluster) #corto los arboles
  cut_clust_list[[imputer_i]] = rf.cluster
  
  data[ data$imputer== imputer_i , 'cluster'] = rf.cluster
  
  
  
}

data_all = cbind(index, data)

country_cluster = pivot_wider(data_all, 
             id_cols = "Country.Name",
            names_from = "imputer",
            values_from = "cluster")

country_cluster_df = data_all %>% 
  dplyr::count(Country.Name,cluster) %>% 
  group_by(Country.Name) %>%
  mutate(prop = prop.table(n),
         sd = sd (n) ) %>% 
  arrange(-sd)
# sum(country_cluster_df$prop)

# as.data.frame(country_cluster_df) %>% 
#   select(Country.Name, n, cluster) %>% 
#   pivot_wider(id_cols = Country.Name,
#               names_from = n,
#               values_from = cluster)


country_cluster_table = as.data.frame.matrix(table(data_all$Country.Name, data_all$cluster) ) %>%
  as.data.frame() %>% 
  tibble::rownames_to_column() %>% 
  ungroup() #%>% 
  # dplyr::arrange(3, .by_group = TRUE)

# country_cluster_table = country_cluster_table[order(country_cluster_table[,"3"], decreasing = T), ]
country_cluster_table = country_cluster_table[order(country_cluster_table[,"2"], decreasing = T), ]


print(xtable(country_cluster_table, tabular.environment="longtable"
             , caption  = 'Frecuencia de asignación de los países a cada clúster según las distintas técnicas de imputación de datos faltantes'
             ,label= 'table:country_clust'), include.rownames = F      )


# estadisticas descriptivas por cluster
avg_clust  = data_all %>% 
  group_by(cluster) %>%
  summarise_all(.funs = mean) %>% 
  select(cluster, 6:ncol(.)-1)  %>% 
  reshape2::melt(id.var = 'cluster') %>% 
  pivot_wider(names_from = 'cluster') #%>% 
  # dplyr::arrange('3')
avg_clust = avg_clust[order(avg_clust[,"3"], decreasing = T), ]


print(xtable(avg_clust, 
             caption = "Valores promedios para los clústers encontrados a partir de todos los métodos de imputación",
             label = "table:avg_clust"), 
      include.rownames = F)

###### PLOTS ##########
library(ggdendro)
library(dendextend)

# hca    = hclust_list[['MICE-LinearRegression']]
# hca    = hclust_list[['MICE-RandomForest']]
hca    = hclust_list[['MICE-BayesianRidge']]
# hca    = hclust_list[['Complete']]
# hca    = hclust_list[['HotDeck']]
clust <- cutree(hca,k=optimal_cluster)  # k clusters

dendr    <- dendro_data(hca, type="rectangle") # convert for ggplot
clust.df <- data.frame(label=names(clust), cluster=factor(clust))
dendr[["labels"]]   <- merge(dendr[["labels"]],clust.df, by="label")
rect <- aggregate(x~cluster,label(dendr),range)
rect <- data.frame(rect$cluster,rect$x)
ymax <- mean(hca$height[length(hca$height)-((optimal_cluster-2):(optimal_cluster-1))])

ggplot() + 
  geom_segment(data=segment(dendr), aes(x=x, y=y, xend=xend, yend=yend)) + 
  geom_text(data=label(dendr), aes(x, y, label=label, hjust=0, color=cluster), 
            size=1.5) +
  geom_rect(data=rect, aes(xmin=X1-.3, xmax=X2+.3, ymin=0, ymax=ymax), 
            color="red", fill=NA)+
  # geom_hline(yintercept=0.33, color="blue")+
  coord_flip() + scale_y_reverse(expand=c(0.2, 0)) + 
  theme_dendro()+
  theme(legend.position = 'none')
ggsave(plot = last_plot(), filename  = 'results/dendo_clust.jpg',
       height = 15,
       width = 10,
       limitsize = FALSE)




##########################
jpeg('results/hclust.jpg')
dhc <- as.dendrogram(hca)
plot(dhc, hang = -1, cex = 0.6)
rect.dendrogram(dhc, k = optimal_cluster,
            border = 2:5)
dev.off()

dhc %>% color_branches(k=optimal_cluster) %>% plot(horiz=TRUE)

dhc %>% rect.dendrogram(k=optimal_cluster,horiz=TRUE)


ggdendrogram(cluster_method, rotate = TRUE, size = 2)

dhc <- as.dendrogram(hca)
dend2 <- color_labels(dhc, k =optimal_cluster)
plot(dend2)
rect.hclust(dend2, k = optimal_cluster)

ddata <- dendro_data(dhc, type = "rectangle")
p <- ggplot(segment(ddata)) + 
  geom_segment(aes(x = x, y = y, xend = xend, yend = yend)) + 
  coord_flip() + 
  scale_y_reverse(expand = c(0.2, 0))
p

graphics::plot(dhc, type = "rectangle", ylab = "Height",
     horiz = TRUE)


require("ape")
colors = c("red", "blue", "green", "black")
clus4 = cutree(hca, 3)
plot(as.phylo(cluster_method), tip.color = colors[clus4],
     label.offset = 1, cex = 0.7)


