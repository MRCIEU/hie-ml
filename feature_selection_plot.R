library("data.table")
library("GGally")
set.seed(123)
setEPS()

get_features <- function(outcome, data){
    for (model in c("ElasticNet", "Tree", "SVC", "Lasso", "RFE")){
        tmp <- fread(paste0("data/", data, outcome, ".", model, "_features.csv"), drop =1, col.names=c("feature", model))
        tmp[[model]] <- abs(tmp[[model]])
        if (!exists("features")){
            features <- tmp
        } else {
            features <- merge(features, tmp, "feature")
        }
    }
    return(features)
}

# TODO "antenatal_intrapartum", "antenatal_growth"
for (data in c("antenatal")){
    # read in results
    d <- get_features("_hie", data)

    # feature plot
    postscript(paste0(data, "_feature_selection.eps"), family="mono", width=12)
    ggpairs(d[,-"feature"], upper = list(continuous = wrap('cor', method = "spearman"))) + theme_bw()
    dev.off()
}