require(tidyverse)
require(ggplot2)
require(GGally)
require(VIM)
library(mice) # Cargamos la librería

#wd
# setwd('/home/mateo1/repos/financialinclusionClustering')
setwd('C:/Users/mateo/Documents/repos/financialinclusionClustering')

#data
dataset = read.csv("data/data.csv")
data = dataset[ dataset$year == 2021,]

# EDA
glimpse(data)
nrow(data[!complete.cases(data),])

summary(data)
boxplot(data[,4:ncol(data)])

# Missing paterns
country_all_na = data %>% 
  # select(4:ncol(data)) %>% 
  filter_at(vars(4:ncol(data)), all_vars(is.na(.)))
  # filter_at(vars(4:ncol(data)), all_vars( !complete.cases(.) ) )
country_all_na$Country.Code

data = data %>% 
  filter(!Country.Code %in% country_all_na$Country.Code)

na_plot =aggr(data[,4:ncol(data)], sortVar=TRUE, oma = c(16, 5, 5, 3), numbers=T)
summary(na_plot)

md.pattern(data[,4:ncol(data)], rotate.names=TRUE)

## ggally
lowerfun <- function(data,mapping){
  ggplot(data = data, mapping = mapping)+
    geom_point(alpha = 0.5)+
    scale_x_continuous(limits = c(0,1), breaks=c(0.25, 0.5, 0.75))+
    scale_y_continuous(limits = c(0,1), breaks=c(0.25, 0.5, 0.75))+
    geom_smooth(method = "loess")#+
    # theme(axis.text.x = element_text( angle=45))
}  


# Corr plot
# Matrix of plots
p1 <- ggpairs(data = data, columns = 4:ncol(data)  , na.omit = TRUE ,
              # lower = list(continuous = "smooth")
              lower = list(continuous = wrap(lowerfun)),
              diag = list(continuous = "barDiag") )
  # +theme_grey(base_size = 8)
  # theme(axis.text=element_blank())+
  # theme_minimal(base_size = 9)

p1 <- ggpairs(data = data, columns = 4:ncol(data)  , na.omit = TRUE 
              , lower = list(continuous = "smooth"),
              diag = list(continuous = "barDiag")
              )

p2 <- ggcorr(data[,4:ncol(data) ], label = TRUE, label_round = 2)
g2 <- ggplotGrob(p2)
colors <- g2$grobs[[6]]$children[[3]]$gp$fill

# Change background color to tiles in the upper triangular matrix of plots 
idx <- 1
p <- ncol(data[,4:ncol(data) ] )
for (k1 in 1:(p-1)) {
  for (k2 in (k1+1):p) {
    plt <- getPlot(p1,k1,k2) +
      theme(panel.background = element_rect(fill = colors[idx], color="white"),
            panel.grid.major = element_line(color=colors[idx]))
    p1 <- putPlot(p1,plt,k1,k2)
    idx <- idx+1
  }
}

print(p1+ theme(strip.placement = "outside", text = element_text(size = 9)))
ggsave("results/ggpair.jpg",
       width = 10, height = 10)





