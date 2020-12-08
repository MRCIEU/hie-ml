library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
set.seed(123)

get_rocs <- function(data, probs, model="LR"){
    plots <- list()

    for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
        roc.dat <- list()
        for (nfeatures in c(20, 40, 60)){
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
# TODO growth & intrapartum
probs <- data.frame()
for (data in c("antenatal")){
    for (outcome in c("_hie")){
        for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
            for (nfeatures in c(20, 40, 60)){
                for (model in c("LR")){
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

# ROC for LR only
antenatal <- get_rocs("antenatal", probs)
antenatal_intrapartum <- get_rocs("antenatal", probs) # TODO
antenatal_growth <- get_rocs("antenatal", probs) # TODO

fig1 <- ggarrange(antenatal[["RFE"]], antenatal[["ElasticNet"]], antenatal[["Lasso"]], antenatal[["SVC"]], antenatal[["Tree"]], nrow=1, ncol=5)
fig1 <- annotate_figure(fig1, top = text_grob("Antenatal"))

fig2 <- ggarrange(antenatal_intrapartum[["RFE"]], antenatal_intrapartum[["ElasticNet"]], antenatal_intrapartum[["Lasso"]], antenatal_intrapartum[["SVC"]], antenatal_intrapartum[["Tree"]], nrow=1, ncol=5)
fig2 <- annotate_figure(fig2, top = text_grob("Antenatal & Intrapartum"))

fig3 <- ggarrange(antenatal_growth[["RFE"]], antenatal_growth[["ElasticNet"]], antenatal_growth[["Lasso"]], antenatal_growth[["SVC"]], antenatal_growth[["Tree"]], nrow=1, ncol=5)
fig3 <- annotate_figure(fig3, top = text_grob("Antenatal & Growth"))

png("lr-roc.png", width=480*5, height=480*3)
ggarrange(fig1, fig2, fig3, nrow=3, ncol=1)
dev.off()