library("glmnet")
library("data.table")
library("dplyr")
library("broom")
set.seed(123)
setEPS()

for (alpha in c(0.5, 1)){
    message(paste0("alpha = ", alpha))
    for (data in c("antenatal", "antenatal_growth", "antenatal_intrapartum")){
        for (outcome in c('_hie')){
            
            # read in data
            train <- fread(paste0("data/", data, outcome, "_train.csv"), check.names=T)
            test <- fread(paste0("data/", data, outcome, "_test.csv"), check.names=T)
            rownames(train) <- train$X_id
            train$X_id <- NULL
            rownames(test) <- test$X_id
            test$X_id <- NULL

            # drop missing values
            train <- train[complete.cases(train)]
            test <- test[complete.cases(test)]

            ### downsample for testing ###
            train <- sample_n(train, 5000)
            train <- train[,c(names(train)[1:100], paste0("X", outcome)), with=F]
            test <- sample_n(test, 5000)
            test <- test[,c(names(test)[1:100], paste0("X", outcome)), with=F]
            ###
            
            # split predictors from outcome
            train_x <- model.matrix(as.formula(paste0("X", outcome, "~.")), train)[,-1]
            test_x <- model.matrix(as.formula(paste0("X", outcome, "~.")), test)[,-1]
            train_y <- get(paste0("X", outcome), train)
            test_y <- get(paste0("X", outcome), test)

            # Find the optimal value of lambda
            # Adapted from http://www.sthda.com/english/articles/36-classification-methods-essentials/149-penalized-logistic-regression-essentials-in-r-ridge-lasso-and-elastic-net/
            cv.lasso <- cv.glmnet(train_x, train_y, alpha = alpha, family = "binomial", maxit=1e+8)

            # Final model with lambda.min
            lasso.model <- glmnet(train_x, train_y, alpha = alpha, family = "binomial", maxit=1e+8, lambda = cv.lasso$lambda.min)
            write.table(tidy(lasso.model), row.names=F, quote=F, sep="\t", file=paste0("data/", data, outcome, "_", alpha, "_lasso_coef_train.csv"))

            # Make prediction on test data
            prob <- lasso.model %>% predict(newx = test_x)
            write.table(cbind(prob, test_y), row.names=F, quote=F, sep="\t", file=paste0("data/", data, outcome, "_", alpha, "_lasso_prob_test.csv"))
        }
    }
}