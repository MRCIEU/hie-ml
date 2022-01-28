library("data.table")
library("GGally")
set.seed(123)

get_features <- function(outcome, data){
    for (model in c("ElasticNet", "Tree", "SVC", "Lasso", "RFE")){
        tmp <- fread(paste0("data/", data, outcome, ".", model, "_features.csv"), drop =1, col.names=c("feature", model))
        tmp[[model]] <- abs(tmp[[model]])
        if (model == "RFE"){
            tmp[[model]] <- tmp[[model]] * -1
        }
        if (!exists("features")){
            features <- tmp
        } else {
            features <- merge(features, tmp, "feature")
        }
    }
    return(features)
}

for (data in c("antenatal","antenatal_growth","antenatal_intrapartum")){
    # read in results
    d <- get_features("_hie", data)

    # feature plot
    p <- ggpairs(d[,-"feature"], upper = list(continuous = wrap('cor', method = "spearman"))) + theme_bw()
    pdf(paste0(data, "_feature_selection.pdf"))
    print(p)
    dev.off()
}