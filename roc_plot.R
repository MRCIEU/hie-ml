library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
set.seed(123)
setEPS()

# read in results
probs <- data.frame()
for (data in c("antenatal","antenatal_growth","antenatal_intrapartum")){
    for (outcome in c("_hie")){
        for (model in c("ElasticNet", "Tree", "SVC", "Lasso")){
            # probs
            probs.tmp <- fread(paste0("data/", data, outcome, ".", model, "_probs.csv"), col.names=c("id", "prob", "bin"))
            probs.tmp$model <- model
            probs.tmp$outcome <- outcome
            probs.tmp$data <- data
            probs <- rbind(probs, probs.tmp)
        }
    }
}

# ROC
plots <- list()
for (data in c("antenatal","antenatal_growth","antenatal_intrapartum")){
    roc.dat <- list()
    for (outcome in c("_hie")){
        for (model in c("ElasticNet", "Tree", "SVC", "Lasso")){
            probs.tmp <- probs %>% filter(model==!!model & outcome==!!outcome & data==!!data)
            roc.tmp <- roc(probs.tmp$bin, probs.tmp$prob, auc=TRUE, ci=TRUE)
            roc.dat[[paste0(model, "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp
        }
    }
    title <- str_to_title(str_replace(data, "_", " & "))
    plots[[data]] <- ggroc(roc.dat) +
        theme_light() +
        theme(legend.title=element_blank(), text = element_text(size=12), legend.key.height=unit(3,"line")) +
        ggtitle(title) +
        geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="darkgrey", linetype="dashed")
}

postscript("roc.eps", width=21)
ggarrange(plots[["antenatal"]], plots[["antenatal_growth"]], plots[["antenatal_intrapartum"]], nrow=1, ncol=3, labels = c("A", "B", "C"))
dev.off()