# main roc plot

# Elastic Net with Antenatal and Growth Factors (best performing combination under logistic regression)
# and have a single figure comparing the ML methods on this (replacing figs 3-5, with just three sub-plots – one for each ML method)

library("data.table")
library("pROC")
library("ggplot2")
library("dplyr")
library("stringr")
library("ggpubr")
library("readstata13")
set.seed(123)

# produce automl ROCs
for (alg in c("LR", "RF", "NB", "NN")){
    message(alg)

    antenatal_growth <- get_rocs("antenatal_growth", probs, model=alg)

    fig2 <- ggarrange(antenatal[["ElasticNet"]], antenatal_growth[["ElasticNet"]], antenatal_intrapartum[["ElasticNet"]], nrow=1, ncol=3)

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