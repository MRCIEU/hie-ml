library('broom')
library("data.table")
library('pROC')
library('readstata13')
library('dplyr')
library('ggplot2')
set.seed(1234)
setEPS()

get_metrics <- function(model, dataset, outcome, dat){
    # prepare ROCs
    roc_a <- roc(dat[[outcome]], dat[[paste0(model, "_", "a", "_", outcome, "_pred")]], auc=TRUE, ci=TRUE)
    roc_c <- roc(dat[[outcome]], dat[[paste0("con", "_", dataset, "_", outcome, "_pred")]], auc=TRUE, ci=TRUE)
    roc1 <- roc(dat[[outcome]], dat[[paste0(model, "_", dataset, "_", outcome, "_pred")]], auc=TRUE, ci=TRUE)
    
    # compare this dataset to antenatal only
    test_a <- roc.test(roc_a, roc1)
    # compare this dataset to conventional only
    test_c <- roc.test(roc_c, roc1)

    # count number of affected in top decile
    dec <- dat %>%
        filter(!is.na(!!sym(paste0(model, "_", dataset, "_", outcome, "_pred")))) %>%
        mutate(decile=ntile(!!sym(paste0(model, "_", dataset, "_", outcome, "_pred")), 10)) %>%
        group_by(decile) %>%
        summarize(n_decile=n(), avg_prob=mean(!!sym(paste0(model, "_", dataset, "_", outcome, "_pred")), na.rm=T), sum=sum(!!sym(outcome), na.rm=T))
    
    return(data.frame(
        dataset,
        outcome,
        model,
        auc=paste0(round(roc1$ci[2], 2), " (", round(roc1$ci[1], 2), "-", round(roc1$ci[3], 2), ")"),
        prop_in_top_dec=paste0(dec[10,]$sum, " (", round(dec[10,]$sum / sum(dec$sum) * 100, 1), "%)"),
        p_diff_antenatal=round(tidy(test_a)$p.value,2),
        p_diff_conventional=round(tidy(test_c)$p.value,2), stringsAsFactors=F
    ))

}

# combine data with David's analysis
dat <- read.dta13("data/Risk Deciles_Conventional and Google.dta")
for (dataset in c("antenatal", "antenatal_growth", "antenatal_intrapartum")){
    for (outcome in c("hie", "resus", "lapgar", "perinataldeath")){
        for (model in c("LR", "RF", "NN", "Adanet")){
            if(dataset == "antenatal"){
                dataset_do <- "a"
            } else if (dataset == "antenatal_growth") {
               dataset_do <- "g"
            } else if (dataset == "antenatal_intrapartum") {
               dataset_do <- "i"
            }
            df <- fread(paste0("data/", dataset, "_", outcome,".", model, ".csv"), select=c("_id", "Prob"), col.names=c("id", paste0(model, "_", dataset_do, "_", outcome, "_pred")))
            dat <- merge(dat, df, "id", all=T)
        }
    }
}

# table 2
res <- data.frame()
for (dataset in c("a", "g", "i")){
    for (outcome in c("hie", "perinataldeath")){
        for (model in c("con", "automl", "LR", "RF", "NN", "Adanet")){
            if (dataset == "i" && outcome == "perinataldeath"){
                next
            }
            res <- rbind(res, get_metrics(model, dataset, outcome, dat), stringsAsFactors=F)
        }
    }
}

# format table and write to file
tb <- rbind(
    c("Outcome", "Antenatal Factors", "", "Antenatal and Growth Factors", "", "", "Antenatal and Intrapartum Factors", "", ""),
    c("", "AUC (95% CI)", "Proportion in highest decile", "AUC (95% CI)", "Proportion in highest decile", "p-value*", "AUC (95% CI)", "Proportion in highest decile", "p-value*")
)
get_roc_row <- function(res, outcome, model){
    return(
        c(
            filter(res, dataset == "a" & outcome == !!outcome & model == !!model) %>% select("auc") %>% as.character,
            filter(res, dataset == "a" & outcome == !!outcome & model == !!model) %>% select("prop_in_top_dec") %>% as.character,
            filter(res, dataset == "g" & outcome == !!outcome & model == !!model) %>% select("auc") %>% as.character,
            filter(res, dataset == "g" & outcome == !!outcome & model == !!model) %>% select("prop_in_top_dec") %>% as.character,
            filter(res, dataset == "g" & outcome == !!outcome & model == !!model) %>% select("p_diff_antenatal") %>% as.character,
            if(outcome == "perinataldeath") { NA } else {filter(res, dataset == "i" & outcome == !!outcome & model == !!model) %>% select("auc") %>% as.character},
            if(outcome == "perinataldeath") { NA } else {filter(res, dataset == "i" & outcome == !!outcome & model == !!model) %>% select("prop_in_top_dec") %>% as.character},
            if(outcome == "perinataldeath") { NA } else {filter(res, dataset == "i" & outcome == !!outcome & model == !!model) %>% select("p_diff_antenatal") %>% as.character}
        )
    )
}
get_p_row <- function(res, outcome, model){
    return(
        c(
            filter(res, dataset == "a" & outcome == !!outcome & model == !!model) %>% select(p_diff_conventional) %>% as.numeric,
            "",
            filter(res, dataset == "g" & outcome == !!outcome & model == !!model) %>% select(p_diff_conventional) %>% as.numeric,
            "",
            "",
            if(outcome == "perinataldeath") { NA } else {filter(res, dataset == "i" & outcome == !!outcome & model == !!model) %>% select(p_diff_conventional) %>% as.numeric},
            "",
            ""
        )
    )
}
for (outcome in c("hie", "perinataldeath")){
    if (outcome == "hie"){
        outcome_full <- "Hypoxic-Ischaemic Encephalopathy"
    }
    if (outcome == "perinataldeath"){
        outcome_full <- "Perinatal Death"
    }
    tb <- rbind(tb, 
        c(outcome_full, rep("", 8)),
        c("Conventional Analysis", get_roc_row(res, outcome, "con")),
        c("ML (Google)", get_roc_row(res, outcome, "automl")),
        c("p-value**", get_p_row(res, outcome, "automl")),
        c("ML (L-Regression)", get_roc_row(res, outcome, "LR")),
        c("p-value**", get_p_row(res, outcome, "LR")),
        c("ML (Random Forest)", get_roc_row(res, outcome, "RF")),
        c("p-value**", get_p_row(res, outcome, "RF")),
        c("ML (Neural Net)", get_roc_row(res, outcome, "NN")),
        c("p-value**", get_p_row(res, outcome, "NN")),
        c("ML Model (Adanet)", get_roc_row(res, outcome, "Adanet")),
        c("p-value**", get_p_row(res, outcome, "Adanet"))
    )
}
write.table(tb, file="tb2.txt", row.names=F, col.names=F, sep="\t", quote=F)

# figure 2
con_a_hie_roc <- roc(dat$hie, dat$con_a_hie_pred, auc=TRUE, ci=TRUE)
con_g_hie_roc <- roc(dat$hie, dat$con_g_hie_pred, auc=TRUE, ci=TRUE)
con_i_hie_roc <- roc(dat$hie, dat$con_i_hie_pred, auc=TRUE, ci=TRUE)
automl_a_hie_roc <- roc(dat$hie, dat$automl_a_hie_pred, auc=TRUE, ci=TRUE)
automl_g_hie_roc <- roc(dat$hie, dat$automl_g_hie_pred, auc=TRUE, ci=TRUE)
automl_i_hie_roc <- roc(dat$hie, dat$automl_i_hie_pred, auc=TRUE, ci=TRUE)

l <- list()
l[[paste0("Conventional & antenatal\nAUC ", round(con_a_hie_roc$ci[2],2), "\n(95CI ", round(con_a_hie_roc$ci[1], 2), ", ", round(con_a_hie_roc$ci[3], 2), ")")]] <- con_a_hie_roc
l[[paste0("Conventional & growth\nAUC ", round(con_g_hie_roc$ci[2],2), "\n(95CI ", round(con_g_hie_roc$ci[1], 2), ", ", round(con_g_hie_roc$ci[3], 2), ")")]] <- con_g_hie_roc
l[[paste0("Conventional & intrapartum\nAUC ", round(con_i_hie_roc$ci[2],2), "\n(95CI ", round(con_i_hie_roc$ci[1], 2), ", ", round(con_i_hie_roc$ci[3], 2), ")")]] <- con_i_hie_roc

l[[paste0("AutoML & antenatal\nAUC ", round(automl_a_hie_roc$ci[2],2), "\n(95CI ", round(automl_a_hie_roc$ci[1], 2), ", ", round(automl_a_hie_roc$ci[3], 2), ")")]] <- automl_a_hie_roc
l[[paste0("AutoML & growth\nAUC ", round(automl_g_hie_roc$ci[2],2), "\n(95CI ", round(automl_g_hie_roc$ci[1], 2), ", ", round(automl_g_hie_roc$ci[3], 2), ")")]] <- automl_g_hie_roc
l[[paste0("AutoML & intrapartum\nAUC ", round(automl_i_hie_roc$ci[2],2), "\n(95CI ", round(automl_i_hie_roc$ci[1], 2), ", ", round(automl_i_hie_roc$ci[3], 2), ")")]] <- automl_i_hie_roc

# plot ROC
p <- ggroc(l) + 
    theme_light() +
    theme(legend.title=element_blank(), text = element_text(size=12), legend.key.height=unit(3,"line")) +
    ggtitle("Holdout validation ROC curve") +
    geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="darkgrey", linetype="dashed")
ggsave('roc.eps', p, height=4, width=5)
