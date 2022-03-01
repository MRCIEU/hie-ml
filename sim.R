library("dplyr")
library("broom")
library("pROC")
library("caret")

set.seed(1234)

n_obs <- 10000
n_sim <- 30
p <- 20

# simulate logistic regression model with p predictors
# set to have AUC of 0.7, and 1% case rate
results <- data.frame()
for (i in 1:n_sim){
    # simulate variables
    b <- rnorm(p, sd=0.15)
    dat <- sapply(1:p, function(x) rnorm(n_obs)) %>% as.data.frame
    xb <- -4.9 + t(b %*% t(dat))
    xp <- 1/(1 + exp(-xb))
    dat$y <- rbinom(n = n_obs, size = 1, prob = xp)

    # test setup with standard LR
    #fit <- glm(y ~ ., data=dat, family="binomial")
    #pred <- predict(fit)
    #roc <- roc(dat$y, pred, auc=TRUE, ci=TRUE)
    #auc <- roc$auc %>% as.numeric
    #n1=sum(dat$y==1)
    #results <- rbind(results, data.frame(
    #    auc, n1
    #))

    # bootstrap samples with matched case:control as per Li et al, 2018
    for (k in 1:30){
        # split cases and controls
        y0 <- dat %>% dplyr::filter(y == 0)
        y1 <- dat %>% dplyr::filter(y == 1)
        # sample from controls
        y0s <- y0[sample(1:nrow(y0), nrow(y1), replace=FALSE),]
        # combine new dataset
        d <- rbind(y0s, y1)
        d$y <- as.factor(d$y)
        # split data into training and testing
        idx <- 1:nrow(d)
        train_idx <- sample(idx, nrow(d) * 0.75, replace=FALSE)
        test_idx <- idx[!idx %in% train_idx]
        train <- d[train_idx,]
        test <- d[test_idx,]
        # fit LR with 10-fold CV
        fit <- glm(y ~ ., data=d, family="binomial")
        # define training control
        train_control <- trainControl(method = "cv", number = 10)
        # train the model on training set
        model <- train(y ~ .,
               data = train,
               trControl = train_control,
               method = "glm",
               family=binomial())
        # predict outcome
        pred <- predict(model, newdata = test)
        roc <- roc(test$y %>% as.numeric, pred %>% as.numeric, auc=TRUE, ci=TRUE)
        auc <- roc$auc %>% as.numeric
        n1=sum(dat$y==1)

        # store results
        results <- rbind(results, data.frame(
            auc, n1, k
        ))
    }
}

# estimate mean and 95% CI
t.test(results$auc) %>% tidy
t.test(results$n1) %>% tidy