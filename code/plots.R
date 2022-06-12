library(tidyverse)
library(ggplot2)
library(GGally)
library(VIM)
library(mice) # Cargamos la librería


#data
data = read.csv("C:/Archivos/datos/wb/data.csv")
glimpse(data)
summary(data)

#EDA
summary(aggr(data, sortVar=TRUE, plot=F))
aggr(data, sortVar=TRUE, oma = c(16, 5, 5, 3), numbers=T)
md.pattern(data, rotate.names=T)


#plot
ggpairs(data=data, columns = 4:ncol(data) )
ggsave("ggpair.jpg")
