library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
library("readstata13")
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

get_conventional_roc <- function(data, con){
    # extract data
    if (data == "antenatal"){
        nfeatures <- 20
        con.tmp <- na.omit(con[,c("id", "con_a_hie_pred", "hie")])
        roc.tmp <- roc(con.tmp$hie, con.tmp$con_a_hie_pred, auc=TRUE, ci=TRUE)
    } else if (data == "antenatal_growth"){
        nfeatures <- 21
        con.tmp <- na.omit(con[,c("id", "con_g_hie_pred", "hie")])
        roc.tmp <- roc(con.tmp$hie, con.tmp$con_g_hie_pred, auc=TRUE, ci=TRUE)
    } else if (data == "antenatal_intrapartum"){
        nfeatures <- 35
        con.tmp <- na.omit(con[,c("id", "con_i_hie_pred", "hie")])
        roc.tmp <- roc(con.tmp$hie, con.tmp$con_i_hie_pred, auc=TRUE, ci=TRUE)
    }

    # prepare roc
    roc.dat <- list()
    roc.dat[[paste0(paste0("n", nfeatures), "\nAUC ", round(roc.tmp$ci[2],2), "\n(95CI ", round(roc.tmp$ci[1], 2), ", ", round(roc.tmp$ci[3], 2), ")")]] <- roc.tmp
    roc <- plots[["Conventional"]] <- ggroc(roc.dat) +
        theme_light() +
        ggtitle(fmodel) +
        theme(legend.title=element_blank(), text = element_text(size=12), legend.key.height=unit(3,"line")) +
        geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="darkgrey", linetype="dashed")

    return(roc)
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

# read in conventional analysis
con <- read.dta13("data/Risk Deciles_Conventional and Google.dta")

# produce ROCs
antenatal <- get_rocs("antenatal", probs)
antenatal[["Conventional"]] <- get_conventional_roc(con, "antenatal")
#antenatal_intrapartum <- get_rocs("antenatal_intrapartum", probs)
#antenatal_intrapartum[["Conventional"]] <- get_conventional_roc(con, "antenatal_intrapartum")
#antenatal_growth <- get_rocs("antenatal_growth", probs)
#antenatal_growth[["Conventional"]] <- get_conventional_roc(con, "antenatal_growth")

# TODO
antenatal_intrapartum <- antenatal
antenatal_growth <- antenatal

fig1 <- ggarrange(antenatal[["RFE"]], antenatal[["ElasticNet"]], antenatal[["Lasso"]], antenatal[["SVC"]], antenatal[["Tree"]], nrow=1, ncol=5)
fig1 <- annotate_figure(fig1, top = text_grob("Antenatal"), fig.lab.size = 14)

fig2 <- ggarrange(antenatal_intrapartum[["RFE"]], antenatal_intrapartum[["ElasticNet"]], antenatal_intrapartum[["Lasso"]], antenatal_intrapartum[["SVC"]], antenatal_intrapartum[["Tree"]], nrow=1, ncol=5)
fig2 <- annotate_figure(fig2, top = text_grob("Antenatal & Intrapartum"), fig.lab.size = 14)

fig3 <- ggarrange(antenatal_growth[["RFE"]], antenatal_growth[["ElasticNet"]], antenatal_growth[["Lasso"]], antenatal_growth[["SVC"]], antenatal_growth[["Tree"]], nrow=1, ncol=5)
fig3 <- annotate_figure(fig3, top = text_grob("Antenatal & Growth"), fig.lab.size = 14)

png("lr-roc.png", width=480*5, height=480*3)
ggarrange(fig1, fig2, fig3, nrow=3, ncol=1)
dev.off()