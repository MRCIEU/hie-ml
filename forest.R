library("data.table")
set.seed(1244)

get_pred <- function(dat){
    return(head(dat[order(abs(dat$values), decreasing=T)], n=60)$feature)
}

# elasticnet
en.a <- get_pred(fread("data/antenatal_hie.ElasticNet_features.csv"))
en.g <- get_pred(fread("data/antenatal_growth_hie.ElasticNet_features.csv"))
en.i <- get_pred(fread("data/antenatal_intrapartum_hie.ElasticNet_features.csv"))

# lasso
l.a <- get_pred(fread("data/antenatal_hie.Lasso_features.csv"))
l.g <- get_pred(fread("data/antenatal_growth_hie.Lasso_features.csv"))
l.i <- get_pred(fread("data/antenatal_intrapartum_hie.Lasso_features.csv"))

all.features <- unique(c(
    en.a,
    en.g,
    en.i,
    l.a,
    l.g,
    l.i
))