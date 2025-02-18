library(plyr)
library(dplyr)

# Get path of script
dataset_name = 'UCI_HAR_Dataset'
script.dir <- dirname(sys.frame(1)$ofile)
print(script.dir)
path_to_dataset = file.path(script.dir, dataset_name)
print(path_to_dataset)

# The dataset on which this script depends should be in the same directory.
if (!file.exists(path_to_dataset)) {
  stop("Please make sure that this script is located in the same directory as the working dataset 'UCI_HAR_Dataset'. If script is in the same directory please make sure that the dataset directory is called 'UCI_HAR_Dataset'.")
} else {
  print("Setting working directory to: ", path_to_dataset)
  setwd(path_to_dataset);
}

variable_names = read.table('./features.txt', header=F, stringsAsFactors = F)[,2]
activity_labels = read.table('./activity_labels.txt', header=F, stringsAsFactors = F)
colnames(activity_labels) = c('activity_id', 'activity')

# Keep only mean and standard deviation measurements
filter_variables = function (x) {
  grepl('mean\\(\\)|std\\(\\)', x)
}
keep_variables_raw = sapply(variable_names, filter_variables)
keep_variables = c(c(TRUE, TRUE), keep_variables_raw)
column_names = c(c('subject', 'activity'), variable_names)

# Raw training data
train_raw = read.table('./train/X_train.txt', header=F)
train_subjects = read.table('./train/subject_train.txt', header=F)
train_activities = read.table('./train/y_train.txt', header=F)
colnames(train_activities) = "activity_id"

# Combine subject-, activity-, and feature-vectors of the train datasets, keeping only mean and standard deviation measurements
train_activities = join(train_activities, activity_labels, by = 'activity_id') %>% select(activity)
train_all = cbind(train_subjects, train_activities, train_raw)
colnames(train_all) = column_names
train = train_all[, keep_variables]
train = cbind(dataset='training', train)
str(train)
summary(train)
ncol(train)

# Raw test data
test_raw = read.table('./test/X_test.txt', header=F)
test_subjects = read.table('./test/subject_test.txt', header=F)
test_activities = read.table('./test/y_test.txt', header=F)
colnames(test_activities) = "activity_id"

# Combine subject-, activity-, and feature-vectors of the test datasets, keeping only mean and standard deviation measurements
test_activities = join(test_activities, activity_labels, by = 'activity_id') %>% select(activity)
test_all = cbind(test_subjects, test_activities, test_raw)
colnames(test_all) = column_names
test = test_all[, keep_variables]
test = cbind(dataset='test', test)
str(test)
summary(test)
ncol(test)

# Combine train and test datasets
dataset = bind_rows(train, test)
dataset = dataset %>% mutate_if(is.character, as.factor)
# OR
# dataset = dataset %>% as.data.frame(unclass()) %>% tbl_df
str(dataset)
summary(dataset)
View(dataset)

# Tidy dataset
dataMelt = melt(dataset, id=c("subject", "activity"), measure.vars = variable_names[keep_variables_raw])
tidy_dataset = ddply(dataMelt,.(subject, activity, variable), summarize,average=mean(value))
tidy_dataset = cbind(id=1:nrow(tidy_dataset), tidy_dataset)
str(tidy_dataset)
summary(tidy_dataset)
View(tidy_dataset)

write.csv(tidy_dataset, '../tidy_dataset.csv')
write.table(tidy_dataset, '../tidy_dataset.txt', row.names = F)

