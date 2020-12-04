library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
set.seed(123)
setEPS()

# read in results
features <- data.frame()
for (data in c("antenatal","antenatal_growth","antenatal_intrapartum")){
    for (outcome in c("_hie")){
        for (model in c("ElasticNet", "Tree", "SVC", "Lasso", "RFE")){
            # features
            features.tmp <- fread(paste0("data/", data, outcome, ".", model, "_features.csv"), drop =1)
            features.tmp$model <- model
            features.tmp$outcome <- outcome
            features.tmp$data <- data
            features <- rbind(features, features.tmp)
        }
    }
}

# feature plot
dat %>%
    filter(data=="antenatal") %>%
    ggplot(aes(x=feature, y=values, group=model, color=model)) +
    geom_point()