library("data.table")
library('pROC')
library('dplyr')
library('tidy')
set.seed(1234)

get_metrics <- function(dataset, outcome, model){
    dataset_outcome <- paste0(dataset, "_", outcome)
    antenatal_outcome <- paste0("antenatal_", outcome)
    dat0 <- fread(paste0("data/", antenatal_outcome,".", model, ".csv"))
    t0 <- roc(dat0[[antenatal_outcome]], dat0[["Prob"]], auc=TRUE, ci=TRUE)
    dat <- fread(paste0("data/", dataset_outcome,".", model, ".csv"))
    t <- roc(dat[[dataset_outcome]], dat[["Prob"]], auc=TRUE, ci=TRUE)
    test <- roc.test(t0, t)
    dec <- dat %>%
        mutate(decile=ntile(Prob, 10)) %>%
        group_by(decile) %>%
        summarize(n_decile=n(), avg_prob=mean(Prob), sum=sum(!!sym(dataset_outcome)))
    return(data.frame(
        auc=paste0(round(t$ci[1], 2), " (", round(t$ci[2], 2), "-", round(t$ci[3], 2), ")"),
        p_dec=paste0(dec[10,]$sum, " (", round((dec[10,]$sum / sum(dat[[dataset_outcome]])) * 100, 1), "%)"),
        p_diff=tidy(test)$p.value
    ))
}

res <- data.frame()
for (dataset in c("antenatal", "antenatal_growth", "antenatal_intrapartum")){
    for (outcome in c("hie", "resus", "lapgar", "perinataldeath")){
        for (model in c("LR", "RF", "NN", "Adanet")){
            r <- get_metrics(dataset, outcome, model)
            res <- rbind(res, data.frame(
                auc=r$auc,
                p_dec=r$p_dec,
                dataset,
                outcome,
                model,
                p_diff=round(r$p_diff, 2)
            ))
        }
    }
}

write.table(res, file="tb2.txt", quote=F, row.names=F, sep="\t")