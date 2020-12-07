library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
set.seed(123)
setEPS()

# ROC
# NN RF NB LR
# Each cell to plot to contain series of fmodel-nfeatures
get_rocs <- function(data, probs){
    plots <- list()
    
    for (model in c("NN", "RF", "NB", "LR")){
        roc.dat <- list()
        for (fmodel in c("RFE", "")){
            for (nfeatures in c(10)){
                # create ROC
                probs.tmp <- probs %>% filter(model==!!model & data==!!data & fmodel==!!fmodel & nfeatures==!!nfeatures)
                roc.tmp <- roc(probs.tmp$bin, probs.tmp$prob, auc=TRUE, ci=TRUE)
                roc.dat[[paste0(paste0(fmodel, "-n", nfeatures), "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp
            }
        }
        # create plot
        plots[[model]] <- ggroc(roc.dat) +
            theme_light() +
            theme(legend.title=element_blank(), text = element_text(size=12), legend.key.height=unit(3,"line")) +
            geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="darkgrey", linetype="dashed")
    }

    return(plots)
}

# read in results
probs <- data.frame()
for (data in c("antenatal")){
    for (outcome in c("_hie")){
        for (fmodel in c("RFE")){
            for (nfeatures in c(10, 20, 40, 80)){
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

# create ROC plots
a_rocs <- get_rocs("antenatal", probs)

# print plot
postscript("roc.eps", width=7*4, height=7*1)
ggarrange(
    a_rocs[["NN"]], a_rocs[["RF"]], a_rocs[["NB"]], a_rocs[["LR"]], 
    nrow=1, ncol=4, labels = c(sapply(1:4, function(n) LETTERS[n])))
dev.off()