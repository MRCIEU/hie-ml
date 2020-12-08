library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
set.seed(123)
#setEPS()

# ROC
# NN RF NB LR
# Each cell to plot to contain series of fmodel-nfeatures
get_rocs_all_models <- function(data, probs){
    plots <- list()
    
    for (model in c("NN", "RF", "NB", "LR")){
        roc.dat <- list()
        for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
            for (nfeatures in c(20, 80)){
                # create ROC
                probs.tmp <- probs %>% filter(model==!!model & data==!!data & fmodel==!!fmodel & nfeatures==!!nfeatures)
                roc.tmp <- roc(probs.tmp$bin, probs.tmp$prob, auc=TRUE, ci=TRUE)
                roc.dat[[paste0(paste0(fmodel, "-n", nfeatures), "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp
            }
        }
        # create plot
        plots[[model]] <- ggroc(roc.dat) +
            theme_light() +
            ggtitle(model) +
            theme(legend.title=element_blank(), text = element_text(size=12), legend.key.height=unit(3,"line")) +
            geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="darkgrey", linetype="dashed")
    }

    return(plots)
}

get_rocs_lr <- function(data, probs){
    model <- "LR"
    plots <- list()

    for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
        roc.dat <- list()
        for (nfeatures in c(20, 80)){
            # create ROC
            probs.tmp <- probs %>% filter(model==!!model & data==!!data & fmodel==!!fmodel & nfeatures==!!nfeatures)
            roc.tmp <- roc(probs.tmp$bin, probs.tmp$prob, auc=TRUE, ci=TRUE)
            roc.dat[[paste0(paste0("n", nfeatures), "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp
        }

        # create plot
        plots[[fmodel]] <- ggroc(roc.dat) +
        theme_light() +
        ggtitle(fmodel) +
        theme(legend.title=element_blank(), text = element_text(size=12), legend.key.height=unit(3,"line")) +
        geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="darkgrey", linetype="dashed")
    }

    return(plots)
}

# read in results
probs <- data.frame()
for (data in c("antenatal")){
    for (outcome in c("_hie")){
        for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
            for (nfeatures in c(20, 80)){
                for (model in c("NN", "RF", "NB", "LR")){
                    probs.tmp <- fread(paste0("data/", data, outcome, "_", fmodel, "_n", nfeatures, "_", model, "_prob.csv"), col.names=c("id", "prob", "bin"))
                    probs.tmp$data <- data
                    probs.tmp$outcome <- outcome
                    probs.tmp$fmodel <- fmodel
                    probs.tmp$nfeatures <- nfeatures
                    probs.tmp$model <- model                    
                    probs <- rbind(probs, probs.tmp)
                }
            }
        }
    }
}

# ROC for all models
a_rocs <- get_rocs_all_models("antenatal", probs)
png("multi-roc.png", width=480*4, height=480*1)
ggarrange(
    a_rocs[["NN"]], a_rocs[["RF"]], a_rocs[["NB"]], a_rocs[["LR"]], 
    nrow=1, ncol=4, labels = c(sapply(1:4, function(n) LETTERS[n]))
)
dev.off()

# ROC for LR only
lr_rocs <- get_rocs_lr("antenatal", probs)
png("lr-roc.png", width=480*5, height=480*1)
ggarrange(
    lr_rocs[["RFE"]], lr_rocs[["ElasticNet"]], lr_rocs[["Lasso"]], lr_rocs[["SVC"]], lr_rocs[["Tree"]],
    nrow=1, ncol=5, labels = c(sapply(1:5, function(n) LETTERS[n]))
)
dev.off()