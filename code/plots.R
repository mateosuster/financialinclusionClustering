library(tidyverse)

library(ggplot2)
library(GGally)
library(ggridges)

library(VIM)
library(mice) # Cargamos la librería

#wd
setwd('/home/mateo1/repos/financialinclusionClustering')

#data
data = read.csv("data/data.csv")
data = data[ data$year == 2017,]
glimpse(data)
summary(data)

#EDA
summary(aggr(data, sortVar=TRUE, plot=F))
# aggr(data, sortVar=TRUE, oma = c(16, 5, 5, 3), numbers=T)
aggr(data, sortVar=TRUE)

# count missings
count_missing = data %>%
  arrange(Country.Name) %>% 
  group_by(Country.Name) %>%
  summarise_each(funs(sum(is.na(.)))) %>% 
  # summarise_at(vars(-Country.Name), sum)
  select(-Country.Name) %>%
  # group_by(Country.Name)  %>% 
  rowSums() %>% 
  cbind(unique(data$Country.Name)) %>% 
  as_data_frame() %>% 
  rename("missing_count" = ".", "country" = "V2") %>%  
  mutate(missing_count=as.double(missing_count))

count_missing %>% 
  mutate(missing_count=as.double(missing_count)) %>% 
  # filter(missing_count>10) %>% 
  filter(missing_count>quantile(count_missing$missing_count, probs = 0.75)) %>% 
  ggplot(aes(x = fct_rev(fct_reorder(country, missing_count)), y = missing_count)) +
  geom_col()+
  theme(axis.text.x = element_text(angle = 45 
                                   ,vjust = 0.5 
                                   # ,hjust=1
                                   ))+
  labs(x = "Países", y = "Missings")
ggsave(filename = "results/missings_x_pais.jpg")

#patron de missings
na_pattern_plot= md.pattern(data, rotate.names=T, plot = T)
ggsave('results/na_patter_plot.jpg', na_pattern_plot)

data.frame(na_pattern_plot)


#plot
ggpairs(data=data, columns = 4:ncol(data) )
ggsave("results/ggpair.jpg")


# imputacion hot deck
hotdeck_imp <-hotdeck(data  , imp_var =F)
hotdeck_imp$imputer = 'HotDeck' 


# levanto data from py
data_imp = read.csv('results/data_imputada.csv') %>% 
  bind_rows(hotdeck_imp) %>% 
  bind_rows(data %>% 
              na.omit() %>% 
              mutate(imputer= 'Complete'))
write.csv(data_imp, file = "results/data_imputada_2.csv")

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

