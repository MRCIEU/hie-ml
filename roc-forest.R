library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
library("viridis")
library("readstata13")
set.seed(123)

get_roc_dat <- function(data, probs, model){
    roc.dat <- data.frame()

    if (data == "antenatal"){
        label <- "Antenatal"
    } else if (data == "antenatal_growth"){
        label <- "Antenatal & growth"
    } else if (data == "antenatal_intrapartum"){
        label <- "Antenatal & intrapartum"
    }

    for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
        for (nfeatures in c(20, 40, 60)){
            # create ROC
            probs.tmp <- probs %>% filter(model==!!model & data==!!data & fmodel==!!fmodel & nfeatures==!!nfeatures)
            roc.tmp <- roc(probs.tmp$bin, probs.tmp$prob, auc=TRUE, ci=TRUE)

            # store estimate and 95 CI
            roc.dat <- rbind(roc.dat, data.frame(
              nfeatures,
              data=label,
              fmodel,
              model,
              auc=roc.tmp$ci[2],
              lci=roc.tmp$ci[1],
              uci=roc.tmp$ci[3]
            ))

        }
    }

    return(roc.dat)
}

get_conventional_roc_dat <- function(con){
    roc.dat <- data.frame()

    data <- "Antenatal"
    nfeatures <- 20
    con.tmp <- na.omit(con[,c("id", "con_a_hie_pred", "hie")])
    roc.tmp <- roc(con.tmp$hie, con.tmp$con_a_hie_pred, auc=TRUE, ci=TRUE)

    roc.dat <- rbind(roc.dat, data.frame(
        nfeatures,
        data,
        fmodel="Badawi",
        model="LR",
        auc=roc.tmp$ci[2],
        lci=roc.tmp$ci[1],
        uci=roc.tmp$ci[3]
    ))

    data <- "Antenatal & growth"
    nfeatures <- 21
    con.tmp <- na.omit(con[,c("id", "con_g_hie_pred", "hie")])
    roc.tmp <- roc(con.tmp$hie, con.tmp$con_g_hie_pred, auc=TRUE, ci=TRUE)

    roc.dat <- rbind(roc.dat, data.frame(
        nfeatures,
        data,
        fmodel="Badawi",
        model="LR",
        auc=roc.tmp$ci[2],
        lci=roc.tmp$ci[1],
        uci=roc.tmp$ci[3]
    ))   
    
    data <- "Antenatal & intrapartum"
    nfeatures <- 35
    con.tmp <- na.omit(con[,c("id", "con_i_hie_pred", "hie")])
    roc.tmp <- roc(con.tmp$hie, con.tmp$con_i_hie_pred, auc=TRUE, ci=TRUE)
    
    roc.dat <- rbind(roc.dat, data.frame(
        nfeatures,
        data,
        fmodel="Badawi",
        model="LR",
        auc=roc.tmp$ci[2],
        lci=roc.tmp$ci[1],
        uci=roc.tmp$ci[3]
    ))   
    
    return(roc.dat)
}

# read in results
probs <- data.frame()
for (data in c("antenatal", "antenatal_growth", "antenatal_intrapartum")){
    for (outcome in c("_hie")){
        for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
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

data <- data.frame()

# read in conventional analysis
con <- read.dta13("data/Risk Deciles_Conventional and Google.dta")
data <- rbind(data, get_conventional_roc_dat(con))

# produce automl ROCs
for (alg in c("LR", "RF", "NB", "NN")){
    data <- rbind(data, get_roc_dat("antenatal", probs, alg), get_roc_dat("antenatal_growth", probs, alg), get_roc_dat("antenatal_intrapartum", probs, alg))
}

# tidy
data[which(data$fmodel=="Tree"),]$fmodel <- "ExtraTrees"
data[which(data$fmodel=="Badawi"),]$fmodel <- "Badawi et al"
data$fmodel <- factor(data$fmodel, levels = c("Badawi et al", "RFE", "ElasticNet", "Lasso", "SVC", "ExtraTrees"))

# plot all feature selection methods using LR
p1 <- data %>% filter(model == "LR") %>%
    ggplot(., aes(x=fmodel, y=auc, ymin=lci, ymax=uci, group=nfeatures, color=nfeatures)) +
    geom_point(position=position_dodge(width=0.75)) +
    geom_errorbar(width=.05, position=position_dodge(width=0.75)) +
    theme_classic() + 
    ggtitle("Logitstic regression discrimination using a range of feature selection methods") +
    xlab("Feature selection method") + 
    ylab(paste0("AUROC (95% CI)")) +
    scale_y_continuous(limits = c(0.3, 1), breaks = scales::pretty_breaks(n = 10)) +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "grey") +
    facet_grid(cols = vars(data)) +
    labs(col="No. features") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))

png("LR_all_feature_selection.png", width=500)
print(p1)
dev.off()

# plot all ML methods using feature selection by ES
p2 <- data %>% filter(fmodel == "ElasticNet" & nfeatures==60) %>%
    ggplot(., aes(x=model, y=auc, ymin=lci, ymax=uci)) +
    geom_point(position=position_dodge(width=0.75)) +
    geom_errorbar(width=.05, position=position_dodge(width=0.75)) +
    theme_classic() + 
    ggtitle("Machine learning discrimination using elastic net feature selection") +
    xlab("Classifier") + 
    ylab(paste0("AUROC (95% CI)")) +
    scale_y_continuous(limits = c(0.3, 1), breaks = scales::pretty_breaks(n = 10)) +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "grey") +
    facet_grid(cols = vars(data)) +
    labs(col="No. features") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))

png("ML_elastic_net.png", width=500)
print(p2)
dev.off()