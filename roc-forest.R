library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
library("viridis")
library("readstata13")
library("RColorBrewer")
set.seed(123)

get_roc_dat <- function(data, probs, model){
    roc.dat <- data.frame()

    if (data == "antenatal"){
        label <- "Antenatal"
    } else if (data == "antenatal_growth"){
        label <- "Antenatal, intrapartum & birthweight"
    } else if (data == "antenatal_intrapartum"){
        label <- "Antenatal & intrapartum"
    }

    for (fmodel in c("RFE", "ElasticNet", "Lasso", "SVC", "Tree")){
        for (nfeatures in c(20, 40, 60)){
            # create ROC
            probs.tmp <- probs %>% dplyr::filter(model==!!model & data==!!data & fmodel==!!fmodel & nfeatures==!!nfeatures)
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

    data <- "Antenatal, intrapartum & birthweight"
    nfeatures <- 35
    con.tmp <- na.omit(con[,c("id", "con_aig_hie_pred", "hie")]) # AIG
    roc.tmp <- roc(con.tmp$hie, con.tmp$con_aig_hie_pred, auc=TRUE, ci=TRUE)

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
    nfeatures <- 34
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
con2 <- read.dta13("data/6. Done_AIG.dta")
con <- merge(con, con2 %>% dplyr::select("con_aig_hie_pred", "id"), "id")
data <- rbind(data, get_conventional_roc_dat(con))

# produce automl ROCs
for (alg in c("LR", "RF", "NB", "NN")){
    data <- rbind(data, get_roc_dat("antenatal", probs, alg), get_roc_dat("antenatal_growth", probs, alg), get_roc_dat("antenatal_intrapartum", probs, alg))
}

# tidy
data[which(data$fmodel=="Tree"),]$fmodel <- "Extra trees"
data[which(data$fmodel=="Badawi"),]$fmodel <- "Badawi et al"
data[which(data$fmodel=="Lasso"),]$fmodel <- "LASSO"
data[which(data$fmodel=="SVC"),]$fmodel <- "Linear SVC"
data[which(data$fmodel=="ElasticNet"),]$fmodel <- "Elastic net"
data$fmodel <- factor(data$fmodel, levels = c("Badawi et al", "RFE", "Elastic net", "LASSO", "Linear SVC", "Extra trees"))

# plot all feature selection methods using LR
lr <- data %>% dplyr::filter(model == "LR") %>% 
    dplyr::mutate(nfeatures = replace(nfeatures, fmodel=="Badawi et al", -1)) %>%
    dplyr::mutate(nfeatures = as.factor(nfeatures))

# create row key
key <- data.frame(fmodel=sort(unique(lr$fmodel)), stringsAsFactors=F)
key$key <- row(key) %% 2
lr <- merge(lr, key, "fmodel")
lr$key <- factor(lr$key)

# count number of fmodel
n_fmodels <- length(unique(lr$fmodel))

# Create a data frame with the faceting variables
# and some dummy data (that will be overwritten)
tp <- data.frame()
for (tr in unique(lr$fmodel)){
    tp <- rbind(tp, data.frame(
        fmodel=rep(tr, length(unique(lr$data))),
        fill=which(tr == unique(lr$fmodel)) %% 2,
        data=unique(lr$data)
    ))
}
tp$fill <- as.factor(tp$fill)

p1 <- ggplot(lr, aes(x=fmodel, y=auc, ymin=lci, ymax=uci, group=nfeatures, shape=nfeatures)) +
    geom_point(position=position_dodge(width=1)) +
    geom_errorbar(width=.05, position=position_dodge(width=1)) +
    theme_classic() +
    xlab("Feature selection method") + 
    ylab(paste0("Logistic regression AUROC (95% CI)")) +
    scale_y_continuous(limits = c(0.3, 1), breaks = scales::pretty_breaks(n = 10)) +
    geom_rect(inherit.aes = F, show.legend = FALSE, data = tp, aes(fill = fill), xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf, alpha = 0.15) +
    scale_fill_grey() +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "black") +
    facet_grid(fmodel~data, scales="free") +
    labs(shape="No. features") +
    scale_shape_manual(breaks = c("20", "40", "60"), values = c(1,6,0,2)) +
    theme(
        axis.text.x = element_text(angle = 90, hjust = 1),
        strip.background = element_blank(),
        strip.text.y = element_blank(),
        legend.position = "bottom",
        legend.background = element_blank(),
        legend.box.background = element_rect(colour = "black"),
        panel.spacing.y = unit(0, "lines")

    ) +
    coord_flip()

pdf("LR_all_feature_selection.pdf")
print(p1)
dev.off()

# plot all ML methods using feature selection by ES
ml <- data %>% dplyr::filter(fmodel == "Elastic net" & nfeatures==60)
ml[which(ml$model=="LR"),]$model <- "Logistic regression"
ml[which(ml$model=="RF"),]$model <- "Random forest"
ml[which(ml$model=="NB"),]$model <- "Naive Bayes"
ml[which(ml$model=="NN"),]$model <- "Neural network"

p2 <- ml %>%
    ggplot(., aes(x=model, y=auc, ymin=lci, ymax=uci)) +
    geom_point(position=position_dodge(width=1)) +
    geom_errorbar(width=.05, position=position_dodge(width=1)) +
    theme_classic() + 
    xlab("Classifier") + 
    ylab(paste0("AUROC (95% CI)")) +
    scale_y_continuous(limits = c(0.3, 1), breaks = scales::pretty_breaks(n = 10)) +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "grey") +
    facet_grid(cols = vars(data)) +
    labs(col="No. features") +
    theme(
        axis.text.x = element_text(angle = 90, hjust = 1),
        strip.background = element_blank(),
        strip.text.y = element_blank(),
        legend.position = "bottom",
        legend.background = element_blank(),
        legend.box.background = element_rect(colour = "black"),
        panel.spacing.y = unit(0, "lines")

    )

pdf("ML_elastic_net.pdf")
print(p2)
dev.off()