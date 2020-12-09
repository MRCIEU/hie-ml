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

    for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
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

get_conventional_roc <- function(con){
    roc.dat <- list()

    data ="Antenatal"
    nfeatures <- 20
    con.tmp <- na.omit(con[,c("id", "con_a_hie_pred", "hie")])
    roc.tmp <- roc(con.tmp$hie, con.tmp$con_a_hie_pred, auc=TRUE, ci=TRUE)
    roc.dat[[paste0(data, "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp

    data = "Antenatal & fetal growth"
    nfeatures <- 21
    con.tmp <- na.omit(con[,c("id", "con_g_hie_pred", "hie")])
    roc.tmp <- roc(con.tmp$hie, con.tmp$con_g_hie_pred, auc=TRUE, ci=TRUE)
    roc.dat[[paste0(data, "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp
    
    data = "Antenatal & intrapartum"
    nfeatures <- 35
    con.tmp <- na.omit(con[,c("id", "con_i_hie_pred", "hie")])
    roc.tmp <- roc(con.tmp$hie, con.tmp$con_i_hie_pred, auc=TRUE, ci=TRUE)
    roc.dat[[paste0(data, "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp

    # prepare roc
    roc <- ggroc(roc.dat) +
        theme_light() +
        ggtitle("Conventional") +
        theme(legend.title=element_blank(), text = element_text(size=12), legend.key.height=unit(3,"line")) +
        geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="darkgrey", linetype="dashed")

    return(roc)
}

# read in results
probs <- data.frame()
for (data in c("antenatal", "antenatal_growth", "antenatal_intrapartum")){
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

# read in conventional analysis
con <- read.dta13("data/Risk Deciles_Conventional and Google.dta")
png("conventional-lr-roc.png")
get_conventional_roc(con)
dev.off()

# produce automl ROCs
for (alg in c("LR")){
    message(alg)

    antenatal <- get_rocs("antenatal", probs, model=alg)
    antenatal_growth <- get_rocs("antenatal_growth", probs, model=alg)
    antenatal_intrapartum <- get_rocs("antenatal_intrapartum", probs, model=alg)

    fig1 <- ggarrange(antenatal[["RFE"]] + ggtitle("Antenatal"), antenatal_growth[["RFE"]] + ggtitle("Antenatal & fetal growth"), antenatal_intrapartum[["RFE"]] + ggtitle("Antenatal & intrapartum"), nrow=1, ncol=3)
    fig2 <- ggarrange(antenatal[["ElasticNet"]], antenatal_growth[["ElasticNet"]], antenatal_intrapartum[["ElasticNet"]], nrow=1, ncol=3)
    fig3 <- ggarrange(antenatal[["Lasso"]], antenatal_growth[["Lasso"]], antenatal_intrapartum[["Lasso"]], nrow=1, ncol=3)
    fig4 <- ggarrange(antenatal[["SVC"]], antenatal_growth[["SVC"]], antenatal_intrapartum[["SVC"]], nrow=1, ncol=3)
    fig5 <- ggarrange(antenatal[["Tree"]], antenatal_growth[["Tree"]], antenatal_intrapartum[["Tree"]], nrow=1, ncol=3)

    fig1 <- annotate_figure(fig1, top = text_grob("RFE"), fig.lab.size = 16)
    fig2 <- annotate_figure(fig2, top = text_grob("ElasticNet"), fig.lab.size = 16)
    fig3 <- annotate_figure(fig3, top = text_grob("Lasso"), fig.lab.size = 16)
    fig4 <- annotate_figure(fig4, top = text_grob("SVC"), fig.lab.size = 16)
    fig5 <- annotate_figure(fig5, top = text_grob("Tree"), fig.lab.size = 16)

    fig <- ggarrange(fig1, fig2, fig3, fig4, fig5, nrow=5, ncol=1)

    png(paste0("automl-", alg, "-roc.png"), width=480*3, height=480*5)
    print(fig)
    dev.off()
}