require(tidyverse)
require(ggplot2)
require(ggridges)
require(VIM)
# require(mice) # Cargamos la librería

#wd
# setwd('/home/mateo1/repos/financialinclusionClustering')
setwd('C:/Users/mateo/Documents/repos/financialinclusionClustering')

#data
dataset = read.csv("data/data.csv")
data = dataset[ dataset$year == 2021,]


# imputacion hot deck
hotdeck_imp <-hotdeck(data  , imp_var =F)
hotdeck_imp$imputer = 'HotDeck' 


# levanto data from py
data_imp = read.csv('results/data_imputada_py.csv') %>% 
  bind_rows(hotdeck_imp) %>% 
  bind_rows(data %>% 
              # na.omit() %>% 
              mutate(imputer= 'Sin imputación'))


write.csv(data_imp, file = "results/data_imputada.csv", row.names = F)

table(data_imp$imputer)


# PLOTSSS
# https://cran.r-project.org/web/packages/ggridges/vignettes/introduction.html#:~:text=The%20ggridges%20package%20provides%20two,then%20draws%20those%20using%20ridgelines.
# scale = 5, substantial overlap

for (i in names(data_imp[, 4:ncol(data_imp) ])) {
  print(i) 
  if (i != 'imputer'){
    print ( data_imp %>% 
              ggplot(aes(x = data_imp[,i], y = imputer, fill = imputer )) + 
              geom_density_ridges(
                scale = 2,
                quantiles = 4,
                quantile_lines = TRUE,   vline_size = 0.5, vline_color = "red",
                alpha = .5
                , jittered_points = TRUE, point_alpha = 0.3
              ) + 
              # scale_point_color_hue(l = 40) +
              # scale_discrete_manual(aesthetics = "point_shape", values = c(21, 22, 23, 24, 25))+
              labs()+
              theme(legend.position = 'none', 
                    axis.title = element_blank()) 
    )  
    ggsave(paste0('results/dist_imp/dist_',i,'.jpg' ))
    
  }
}

