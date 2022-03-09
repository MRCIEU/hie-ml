library("readstata13")
library("ggplot2")
library("dplyr")
library("ggrepel")
set.seed(123)

# read in full dataset
d <- readstata13::read.dta13("1. Done.dta")

# chisq test for missingness between cohort=1 and cohort=2
#results <- data.frame()
#for (col in names(d)){
#    if (all(is.na(d[[col]])) | all(!is.na(d[[col]]))){
#        next
#    }
#    result <- chisq.test(is.na(d[[col]]), d[['_cohort']]) %>% tidy
#    result$col <- col
#    results <- rbind(results, result)
#}

# estimate missingness proportion for both training & testing cohorts
m1 <- apply(d %>% dplyr::filter(d[['_cohort']]==1),2,function(x) sum(is.na(x)) / length(x)) %>% as.data.frame
m2 <- apply(d %>% dplyr::filter(d[['_cohort']]==2),2,function(x) sum(is.na(x)) / length(x)) %>% as.data.frame
names(m1) <- "m1"
names(m2) <- "m2"
m <- cbind(m1,m2)
m$col <- row.names(m)
row.names(m) <- NULL

# difference in proportions
m$diff <- abs(m$m1-m$m2)
m$lab <- m$col
m$lab <- substr(m$lab, 4, 99)
m$lab[m$diff < 0.1] <- NA

# plot
pdf("missingness.pdf")
ggplot(m, aes(x=m1, y=m2, label=lab)) +
    geom_point() +
    xlim(0,1) + ylim(0,1) +
    geom_abline(intercept=0, slope=1, linetype = "dashed", color = "grey") +
    geom_label_repel() +
    theme_classic() +
    labs(x="Training missingness", y="Testing missingness")
dev.off()