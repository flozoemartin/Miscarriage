#########################################################################

# Propensity score matching 

# Author: Flo Martin

# Date: 08/10/2024

#########################################################################

  install.packages("haven")
  library("haven")
  install.packages("MatchIt")
  library("MatchIt")
  install.packages("cobalt")
  library("cobalt")
  install.packages("twang")
  library("twang")
  library("ggplot2")
  install.packages("WeightIt")
  library("WeightIt")
  if(!require(randomForest)){install.packages("randomForest"); require(randomForest)}

  setwd("//ads.bris.ac.uk/filestore/HealthSci SafeHaven/CPRD Projects UOB/Projects/21_000362/Flo/4_datafiles/2_pregnancy outcomes/")

  data <- read.csv("pscore_analysis_dataset_r.csv")
  
  summary(data)
  
  table(data$misc)
  table(data$cf_unexposed)
  
  firstpreg_data <- subset(data,pregnum_new == 1 )
  
  table(firstpreg_data$cf_unexposed)
  table(firstpreg_data$misc)
  
  # Logistic regression model to estimate the propensity scores
  ps_model <- glm(cf_unexposed ~ preg_year + hes_apc_e + matage + matage*matage + AreaOfResidence + imd_practice + bmi + bmi*bmi + alcstatus_num + smokstatus_num + illicitdrug_12mo + CPRD_consultation_events_cat_num + diab + endo + pcos + antipsychotics_prepreg + moodstabs_prepreg + teratogen_prepreg + folic_prepreg1 + depression + anxiety + ed + pain + migraine + headache + incont + severe_mental_illness, data=firstpreg_data, binomial(link="logit"), na.action=na.exclude)
  
  odds1 <- exp(predict(ps_model, firstpreg_data))
  firstpreg_data$PS <- odds1/(1+odds1)
  
  MISSING <- is.na(firstpreg_data$PS)
  sum(MISSING)
  ps <- subset(firstpreg_data, subset = !MISSING )
  
  # First matching attempt
  nn1 <- matchit(cf_unexposed ~ preg_year + hes_apc_e + matage + matage*matage + AreaOfResidence + imd_practice + bmi + bmi*bmi + alcstatus_num + smokstatus_num + illicitdrug_12mo + CPRD_consultation_events_cat_num + diab + endo + pcos + antipsychotics_prepreg + moodstabs_prepreg + teratogen_prepreg + folic_prepreg1 + depression + anxiety + ed + pain + migraine + headache + incont + severe_mental_illness, data=ps, distance=ps$PS, method="nearest", ratio = 10, discard="both")
  
  summary(nn1, standardize=T)
  b1 <- bal.plot(nn1, which="both")
  setwd("c://Users/ti19522/OneDrive - University of Bristol/Documents/PhD/Year 4/Manuscripts/3_Miscarriage/Supplementary figures")
  b1 + labs(title="Balance plot - first matching attempt")
  # 4 by 8
  l1 <- love.plot(nn1, binary = "std", thresholds = c(m = .1))
  l1 + labs(title="Love plot - first matching attempt")
  # 9 by 7
  
  # Second matching attempt - 
  nn2 <- matchit(cf_unexposed ~ preg_year + hes_apc_e + matage + matage*matage + AreaOfResidence + imd_practice + bmi + bmi*bmi + alcstatus_num + smokstatus_num + illicitdrug_12mo + CPRD_consultation_events_cat_num + diab + endo + pcos + antipsychotics_prepreg + moodstabs_prepreg + teratogen_prepreg + folic_prepreg1 + depression + anxiety + ed + pain + migraine + headache + incont + severe_mental_illness, data=ps, distance=ps$PS, method="nearest", ratio = 5, discard="both", exact = "CPRD_consultation_events_cat_num")
  
  summary(nn2, standardize=T)
  b2 <- bal.plot(nn2, which="both")
  b2 + labs(title="Balance plot - second matching attempt")
  #l2 <- love.plot(nn2, binary = "std", thresholds = c(m = .1))
  #l2 + labs(title="Love plot - second matching attempt")
  
  # Third matching attempt - 
  nn3 <- matchit(cf_unexposed ~ preg_year + hes_apc_e + matage + matage*matage + AreaOfResidence + imd_practice + bmi + bmi*bmi + alcstatus_num + smokstatus_num + illicitdrug_12mo + CPRD_consultation_events_cat_num + diab + endo + pcos + antipsychotics_prepreg + moodstabs_prepreg + teratogen_prepreg + folic_prepreg1 + depression + anxiety + ed + pain + migraine + headache + incont + severe_mental_illness, data=ps, distance=ps$PS, method="nearest", ratio = 1, discard="both", exact = "CPRD_consultation_events_cat_num", caliper=0.2)
  
  summary(nn3, standardize=T)
  b3 <- bal.plot(nn3, which="both")
  b3 + labs(title="Balance plot - third matching attempt")
  set.cobalt.options(binary = "std")
  l3 <- love.plot(nn3, binary = "std", thresholds = c(m = .1))
  l3 + labs(title="Love plot - third matching attempt")
  
  write.csv(nn3.data, "//ads.bris.ac.uk/filestore/HealthSci SafeHaven/CPRD Projects UOB/Projects/21_000362/Flo/4_datafiles/2_pregnancy outcomes/ps_matched_data.csv", row.names=FALSE)
  
  # HES only sensitivity analysis
  
  data <- read.csv("pscore_analysis_dataset_r_hes_only.csv")
  
  summary(data)
  
  table(data$misc)
  table(data$cf_unexposed)
  
  firstpreg_data <- subset(data,pregnum_new == 1 )
  
  table(firstpreg_data$cf_unexposed)
  table(firstpreg_data$misc)
  
  # Logistic regression model to estimate the propensity scores
  ps_model <- glm(cf_unexposed ~ preg_year + matage + matage*matage + AreaOfResidence + imd_practice + bmi + bmi*bmi + alcstatus_num + smokstatus_num + illicitdrug_12mo + CPRD_consultation_events_cat_num + diab + endo + pcos + antipsychotics_prepreg + moodstabs_prepreg + teratogen_prepreg + folic_prepreg1 + depression + anxiety + ed + pain + migraine + headache + incont + severe_mental_illness, data=firstpreg_data, binomial(link="logit"), na.action=na.exclude)
  
  odds1 <- exp(predict(ps_model, firstpreg_data))
  firstpreg_data$PS <- odds1/(1+odds1)
  
  MISSING <- is.na(firstpreg_data$PS)
  sum(MISSING)
  ps <- subset(firstpreg_data, subset = !MISSING )
  
  # First matching attempt
  nn1 <- matchit(cf_unexposed ~ preg_year + matage + matage*matage + AreaOfResidence + imd_practice + bmi + bmi*bmi + alcstatus_num + smokstatus_num + illicitdrug_12mo + CPRD_consultation_events_cat_num + diab + endo + pcos + antipsychotics_prepreg + moodstabs_prepreg + teratogen_prepreg + folic_prepreg1 + depression + anxiety + ed + pain + migraine + headache + incont + severe_mental_illness, data=ps, distance=ps$PS, method="nearest", discard="both")
  
  summary(nn1, standardize=T)
  b1 <- bal.plot(nn1, which="both")
  setwd("c://Users/ti19522/OneDrive - University of Bristol/Documents/PhD/Year 4/Manuscripts/3_Miscarriage/Supplementary figures")
  b1 + labs(title="Balance plot - first matching attempt")
  # 4 by 8
  l1 <- love.plot(nn1, binary = "std", thresholds = c(m = .1))
  l1 + labs(title="Love plot - first matching attempt")
  # 9 by 7
  
  # Second matching attempt - 
  nn2 <- matchit(cf_unexposed ~ preg_year + hes_apc_e + matage + matage*matage + AreaOfResidence + imd_practice + bmi + bmi*bmi + alcstatus_num + smokstatus_num + illicitdrug_12mo + CPRD_consultation_events_cat_num + diab + endo + pcos + antipsychotics_prepreg + moodstabs_prepreg + teratogen_prepreg + folic_prepreg1 + depression + anxiety + ed + pain + migraine + headache + incont + severe_mental_illness, data=ps, distance=ps$PS, method="nearest", discard="both", exact = "CPRD_consultation_events_cat_num")
  
  summary(nn2, standardize=T)
  b2 <- bal.plot(nn2, which="both")
  b2 + labs(title="Balance plot - second matching attempt")
  l2 <- love.plot(nn2, binary = "std", thresholds = c(m = .1))
  l2 + labs(title="Love plot - second matching attempt")
  
  # Third matching attempt - 
  nn3 <- matchit(cf_unexposed ~ preg_year + matage + matage*matage + AreaOfResidence + imd_practice + bmi + bmi*bmi + alcstatus_num + smokstatus_num + illicitdrug_12mo + CPRD_consultation_events_cat_num + diab + endo + pcos + antipsychotics_prepreg + moodstabs_prepreg + teratogen_prepreg + folic_prepreg1 + depression + anxiety + ed + pain + migraine + headache + incont + severe_mental_illness, data=ps, distance=ps$PS, method="nearest", discard="both", exact = "CPRD_consultation_events_cat_num", caliper=0.2)
  
  summary(nn3, standardize=T)
  b3 <- bal.plot(nn3, which="both")
  b3 + labs(title="Balance plot - third matching attempt")
  l3 <- love.plot(nn3, binary = "std", thresholds = c(m = .1))
  l3 + labs(title="Love plot - third matching attempt")
  
  nn1.data <- match.data(nn1)
  table(nn1.data$misc)
  table(nn1.data$cf_unexposed)
  
  write.csv(nn1.data, "//ads.bris.ac.uk/filestore/HealthSci SafeHaven/CPRD Projects UOB/Projects/21_000362/Flo/4_datafiles/2_pregnancy outcomes/ps_matched_data_hes_only.csv", row.names=FALSE)
