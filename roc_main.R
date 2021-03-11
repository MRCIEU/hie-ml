library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
library("readstata13")
set.seed(123)

get_rocs <- function(data, probs, model="LR", title=F){
    plots <- list()

    for (fmodel in c("ElasticNet")){
        roc.dat <- list()
        for (nfeatures in c(20, 40, 60)){
            # create ROC
            probs.tmp <- probs %>% filter(model==!!model & data==!!data & fmodel==!!fmodel & nfeatures==!!nfeatures)
            roc.tmp <- roc(probs.tmp$bin, probs.tmp$prob, auc=TRUE, ci=TRUE)
            roc.dat[[paste0(paste0("n", nfeatures), "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp
        }

        # create plot
        p <- ggroc(roc.dat) +
            theme_light() +
            theme(legend.title=element_blank(), text = element_text(size=12), legend.key.height=unit(3,"line")) +
            geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="darkgrey", linetype="dashed")

        if (title){
            p <- p + ggtitle(fmodel)
        }
        
        plots[[fmodel]] <- p
    }

    return(plots)
}

# read in results
probs <- data.frame()
for (data in c("antenatal_growth")){
    for (outcome in c("_hie")){
        for (fmodel in c("ElasticNet")){
            for (nfeatures in c(20, 40, 60)){
                for (model in c("LR", "RF", "NB", "NN")){
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

# produce automl ROCs
antenatal_growth_lr <- get_rocs("antenatal_growth", probs, model="LR")
antenatal_growth_rf <- get_rocs("antenatal_growth", probs, model="RF")
antenatal_growth_nb <- get_rocs("antenatal_growth", probs, model="NB")
antenatal_growth_nn <- get_rocs("antenatal_growth", probs, model="NN")
fig2 <- ggarrange(antenatal_growth_lr[["ElasticNet"]] + ggtitle("Logistic regression"), antenatal_growth_rf[["ElasticNet"]] + ggtitle("Random forest"), antenatal_growth_nb[["ElasticNet"]] + ggtitle("Naive Bayes"), antenatal_growth_nn[["ElasticNet"]] + ggtitle("Neural network"), nrow=2, ncol=2)

# print to file
png(paste0("automl-antenatal_growth-ES-roc.png"), width=480*2, height=480*2)
print(fig2)
dev.off()