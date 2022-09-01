library("readstata13")
library("dplyr")
library("mltools")
set.seed(124)

# read in data from DO
dat <- read.dta13("data/1_2_3_4A._Done.dta")
rownames(dat) <- dat[['_id']]
dat[['_id']] <- NULL
dat[['_cohort']] <- NULL
dat[['_lapgar']] <- NULL
dat[['_ne']] <- NULL
dat[['_neonataldeath']] <- NULL
dat[['_perinataldeath']] <- NULL
dat[['_resus']] <- NULL
dat[['_stillborn']] <- NULL
dat[['_yearofbirth']] <- NULL

# find categorical variables
cats <- data.frame(id=names(dat)) %>% 
    dplyr::filter(!startsWith(id, "_")) %>% 
    dplyr::filter(substr(id, 2, 2)=="c") %>% 
    dplyr::pull(id)

# factorize categorical variables
dat <- dat %>%
    dplyr::mutate_at(all_of(cats), list(factor))

# convert unordered categorical to dummy
dat <- one_hot(as.data.table(dat))

# split test and train
dat$train <- sample(c(T,F), nrow(dat), replace = T)
train <- dat %>% dplyr::filter(train) %>% dplyr::select(-train)
test <- dat %>% dplyr::filter(!train) %>% dplyr::select(-train)

# estimate mean and SD using training dataset
m <- apply(train, 2, function(x) mean(x, na.rm=T))
s <- apply(train, 2, function(x) sd(x, na.rm=T))

# Z-score normalisation
train <- (train[-1] - m[-1]) / s[-1]
test <- (test[-1] - m[-1]) / s[-1]

# drop features with SD==0 in training data
train <- train[,s>0,with=F]
test <- test[,s>0,with=F]





for name, variable_list in {"antenatal" : antenatal, "antenatal_growth" : antenatal_growth, "antenatal_intrapartum" : antenatal_intrapartum}.items():
    for outcome in ['_hie']:
        print("Working on {} for {}".format(name, outcome))

        # drop features with high covariance
        sorted_features = train[variable_list].isnull().sum().sort_values(ascending=True).index.to_list()
        to_drop = set()
        for feature in sorted_features:
            if feature in to_drop:
                continue
            variable_list_tmp = [x for x in variable_list if x not in to_drop and x != feature]
            cor = train[variable_list_tmp].corrwith(train[feature]).abs()
            to_drop.update(cor[cor > 0.95].index.to_list())
        to_keep = [x for x in variable_list if x not in to_drop]

        # select variables for this analysis
        train_x = train[to_keep + [outcome]]
        train_x = train_x.dropna(axis='index')
        train_y = train_x.pop(outcome)

        test_x = test[to_keep + [outcome]]
        test_x = test_x.dropna(axis='index')
        test_y = test_x.pop(outcome)

        # oversample training dataset using SMOTE
        X_resampled, y_resampled = SMOTE().fit_resample(train_x, train_y)

        # write to csv
        pd.concat([X_resampled, y_resampled], axis=1).to_csv("data/{}{}_train.csv".format(name, outcome), header=True)
        pd.concat([test_x, test_y], axis=1).to_csv("data/{}{}_test.csv".format(name, outcome), header=True)