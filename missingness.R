library("readstata13")
library("ggplot2")
library("dplyr")
library("ggrepel")
set.seed(123)

# read in full dataset & split by cohort
full <- readstata13::read.dta13("data/1. Done.dta")
full1 <- full[full[['_cohort']] == 1,]
full2 <- full[full[['_cohort']] == 2,]

# drop derived variables
full1 <- full1[!grepl("^_", names(full1))]
full2 <- full2[!grepl("^_", names(full2))]

# estimate missingness proportion in combined population
p <- apply(rbind(full1, full2), 2, function(x) sum(is.na(x)) / length(x)) %>% as.data.frame
names(p) <- "missing"
p$col <- row.names(p)
row.names(p) <- NULL

# define dropped n=28 variables
drop <- p$col[p$missing > 0.1]

# estimate missingness proportion for both training & testing cohorts
m1 <- apply(full1, 2, function(x) sum(is.na(x)) / length(x)) %>% as.data.frame
m2 <- apply(full2, 2, function(x) sum(is.na(x)) / length(x)) %>% as.data.frame
names(m1) <- "m1"
names(m2) <- "m2"
m <- cbind(m1,m2)
m$col <- row.names(m)
row.names(m) <- NULL

# drop n=28
m <- m[!m$col %in% drop,] 

# difference in proportions
m$diff <- abs(m$m1-m$m2)
m$lab <- m$col
m$lab <- substr(m$lab, 4, 99)
m$lab[m$diff < 0.1] <- NA

# plot
pdf("missingness.pdf")
ggplot(m, aes(x=m1, y=m2, label=lab)) +
    geom_point() +
    scale_y_continuous(limits = c(0, .2), breaks = scales::pretty_breaks(n = 5)) +
    scale_x_continuous(limits = c(0, .2), breaks = scales::pretty_breaks(n = 5)) +
    geom_abline(intercept=0, slope=1, linetype = "dashed", color = "grey") +
    geom_label_repel() +
    scale_colour_grey() + 
    theme_classic() +
    labs(x="Training missingness", y="Testing missingness", color="Missingness in whole dataset") +
    theme(
        legend.position = "bottom",
        legend.background = element_blank(),
        legend.box.background = element_rect(colour = "black")
    )
dev.off()