library("data.table")
library('pROC')
library('dplyr')
set.seed(1234)

get_metrics <- function(outcome, model){
    dat <- fread(paste0("data/", outcome,".", model, ".csv"))
    t <- roc(dat[[outcome]], dat[["Prob"]], auc=TRUE, ci=TRUE)
    dec <- dat %>%
        mutate(decile=ntile(Prob, 10)) %>%
        group_by(decile) %>%
        summarize(n_decile=n(), avg_prob=mean(Prob), sum=sum(!!sym(outcome)))
    return(data.frame(
        auc=paste0(round(t$ci[1], 2), " (", round(t$ci[2], 2), "-", round(t$ci[3], 2), ")"),
        p_dec=paste0(dec[10,]$sum, " (", round((dec[10,]$sum / sum(dat[[outcome]])) * 100, 1), "%)")
    ))
}

res <- data.frame()
for (dataset in c("antenatal", "antenatal_growth", "antenatal_intrapartum")){ 
    for (outcome in c("hie", "resus", "lapgar", "perinataldeath")){
        for (model in c("LR", "RF", "NN", "Adanet")){
            r <- get_metrics(paste0(dataset, "_", outcome), model)
            res <- rbind(res, data.frame(
                auc=r$auc,
                p_dec=r$p_dec,
                dataset,
                outcome,
                model
            ))
        }
    }
}

write.table(res, file="tb2.txt", quote=F, row.names=F, sep="\t")