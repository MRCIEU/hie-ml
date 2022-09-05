library("readstata13")
library("dplyr")
library("mltools")
set.seed(124)

# Returns list of highly correlated features to drop
to_drop <- function(tx, features){
    # subset features
    tx <- tx %>% dplyr::select(all_of(features))
    # sort features by missingness
    features <- apply(tx, 2, function(x) sum(is.na(x) | is.infinite(x) | is.nan(x))) %>% sort %>% names
    for (feature in features){
        r <- cor(tx[,feature, with=F], tx[,-feature, with=F], use = "pairwise.complete.obs") %>% abs
        r[r>0.95]
    }
}

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

# split X and Y
train_x <- train %>% dplyr::select(-'_hie')
train_y <- train %>% dplyr::select('_hie')
test_x <- test %>% dplyr::select(-'_hie')
test_y <- test %>% dplyr::select('_hie')

# estimate mean and SD using training dataset
m <- apply(train_x, 2, function(x) mean(x, na.rm=T))
s <- apply(train_x, 2, function(x) sd(x, na.rm=T))

# drop features with SD==0 in training data
train_x <- train_x[,s>0,with=F]
test_x <- test_x[,s>0,with=F]

# Z-score normalisation of predictors
train_x <- (train_x - m) / s
test_x <- (test_x - m) / s

# define feautre sets
antenatal <- data.frame(id=names(train_x)) %>% 
    dplyr::filter(!startsWith(id, "_")) %>% 
    dplyr::filter(substr(id, 1, 1)=="a") %>% 
    dplyr::pull(id)

antenatal_growth <- data.frame(id=names(train_x)) %>% 
    dplyr::filter(!startsWith(id, "_")) %>% 
    dplyr::filter(substr(id, 1, 1)=="a" | substr(id, 1, 1)=="g") %>% 
    dplyr::pull(id)

antenatal_intrapartum <- data.frame(id=names(train_x)) %>% 
    dplyr::filter(!startsWith(id, "_")) %>% 
    dplyr::filter(substr(id, 1, 1)=="a" | substr(id, 1, 1)=="g" | substr(id, 1, 1)=="i") %>% 
    dplyr::pull(id)

# drop features with high covariance
