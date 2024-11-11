********************************************************************************

* Running the logisitic regression to generate the adjusted marginal risk for manuscript and primary figure

* Author: Flo Martin 

* Date started: 23/09/2024

********************************************************************************

* Creates the dataset for the marginal risk portion of figure 2

********************************************************************************

* Start logging

	log using "$Logdir\2_analysis\2_marginal risk dataset", name(marginal_risk_dataset) replace
	
********************************************************************************

* Primary analysis marginal risk 

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa!=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	
	count
	
	* multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date, origin - subject becomes at risk at the pregnancy start date, scale 
	stset end_fup, fail(misc) id(pregid) enter(start_date)
			
	tab cf_unexposed			
	sum cycle_1_start
	
	* stsplit data to account for time-updated exposure 
	stsplit exposure_updated, after(cycle_1_start) at(0)
	
	tab exposure_up, miss
	replace cf_unexposed=0 if exposure_up==-1		
	replace cf_unexposed=2 if exposure_up==0 & cycle_1_start!=.
	tab cf_unexposed exposure_up
		
	* Combine new and prevalent users
	recode cf_unexposed 2=1
	tab cf_unexposed
	recode misc .=0
					
	lab define cf_unexposed 1 "exposed-prev+new users"  0 unexposed
	label values cf_unexposed cf_unexposed
	tab cf_unexposed
	tab misc
	tab misc cf_unexposed, col chi
	
	gen matage_sq = matage*matage
	
	program risk, rclass
	
		stcox i.cf_unexposed matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid) basesurv(S0)
		summ S0 if _t<=168, meanonly
		local S0 = r(min)
	
		margins cf_unexposed, expression(1-`S0'^exp(predict(xb))) grand nose
		
		matrix risk_table = r(table)
		
		return scalar risk_exp = risk_table[1,1]
		return scalar risk_unexp = risk_table[1,2]
		
		cap drop S0
		
	end
		
	bootstrap r(risk_exp) r(risk_unexp), reps(1000): risk
	
	// marginal risk in unexposed 13.10564% (bootstrapped CIs 13.03307-13.17821)
	// marginal risk in exposed 13.56159% (bootstrapped CIs 13.30526-13.81792)
	
	import delimited using "$Graphdir\marginal risk.txt", clear
	
	tab x
	
	replace risk = 13.10564 if x == "Unexposed"
	replace lci = 13.03307 if x == "Unexposed"
	replace uci = 13.17821 if x == "Unexposed"
	replace risk = 13.56159 if x == "Exposed"
	replace lci = 13.30526 if x == "Exposed"
	replace uci = 13.81792 if x == "Exposed"
	
	save "$Graphdir\marginal risk.dta", replace

********************************************************************************

* Exposure discordant analysis marginal risk 

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	cap program drop risk
		
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1

	* Drop women with one preg in study period
	duplicates tag patid, gen(dupes)
	ta dupes
	drop if dupes==0 // 604,744 remaining (multiparous)
	count

	* Drop women with same exposure in each pregnancy
	bysort patid: gen diff=1 if cf_unexposed != cf_unexposed[_n-1] & _n!=1
	bysort patid: egen diff_max=max(diff)
	keep if diff_max==1 // 491,404 concordant dropped
	codebook patid 	/*25,284 women*/
	codebook pregid /*71,924 pregnancies*/ 

	* stset data with outcome under study
	stset end_fup, fail(misc) id(pregid) enter(start_date) 

	* stsplit data to account for time-updated exposure 
	tab cf_unexposed
	sum cycle_1_start
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss

	replace cf_unexposed=0 if exposure_up==-1
	replace cf_discont=. if exposure_up==-1
	replace cf_unexposed=2 if exposure_up==0 & cycle_1_start!=.
	tab cf_unexposed exposure_up 

	* Combine new and prevalent users
	recode cf_unexposed 2=1
	tab cf_unexposed
	recode misc .=0

	lab define  cf_unexposed 1 "exposed-prev+new users"  0 unexposed
	lab val cf_unexposed cf_unexposed
	tab cf_unexposed 
	tab misc
	tab misc cf_unexposed, col chi
	
	gen matage_sq = matage*matage
	
	program risk, rclass
	
		stcox i.cf_unexposed matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid) strata(patid) basesurv(S0)
		summ S0 if _t<=168, meanonly
		local S0 = r(min)
	
		margins cf_unexposed, expression(1-`S0'^exp(predict(xb))) grand nose
		
		matrix risk_table = r(table)
		
		return scalar risk_exp = risk_table[1,1]
		return scalar risk_unexp = risk_table[1,2]
		
		cap drop S0
		
	end
		
	bootstrap r(risk_exp) r(risk_unexp), reps(1000): risk

	// marginal risk in unexposed x% (bootstrapped CIs x-x)
	// marginal risk in exposed x% (bootstrapped CIs x-x)
	
	import delimited using "$Graphdir\marginal risk.txt", clear
	
	tab x
	
	replace risk = 13.10564 if x == "Unexposed"
	replace lci = 13.03307 if x == "Unexposed"
	replace uci = 13.17821 if x == "Unexposed"
	replace risk = 13.56159 if x == "Exposed"
	replace lci = 13.30526 if x == "Exposed"
	replace uci = 13.81792 if x == "Exposed"
	
	save "$Graphdir\marginal risk exposure discordant.dta", replace
	
********************************************************************************
	
* Propensity score matched marginal risk

	import delimited "$Datadir\ps_matched_data.csv", clear	
	count
	
	cap program drop risk
	
	* Data management from .csv to .dta
	gen cycle_1_start_num = real(cycle_1_start)
	drop cycle_1_start
	rename cycle_1_start_num cycle_1_start
	
	gen cf_discont_num = real(cf_discont)
	drop cf_discont
	rename cf_discont_num cf_discont
		
	* stset the data for the Cox model
		
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
	
	* stsplit data to account for time-updated exposure 
	tab cf_unexposed
	sum cycle_1_start
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss

	replace cf_unexposed=0 if exposure_up==-1
	replace cf_discont=. if exposure_up==-1
	replace cf_unexposed=2 if exposure_up==0 & cycle_1_start!=.
	tab cf_unexposed exposure_up 

	* Combine new and prevalent users
	recode cf_unexposed 2=1
	tab cf_unexposed
	recode misc .=0

	lab define  cf_unexposed 1 "exposed-prev+new users"  0 unexposed
	lab val cf_unexposed cf_unexposed
	tab cf_unexposed 
	tab misc
	tab misc cf_unexposed, col chi
	
	gen matage_sq=matage*matage
	gen bmi_sq=bmi*bmi
	
	program risk, rclass
	
		stcox i.cf_unexposed preg_year i.hes_apc_e areaofresidence matage matage_sq i.imd_practice bmi bmi_sq i.alcstatus_num i.smokstatus_num i.illicitdrug_12mo i.cprd_consultation_events_cat_num i.diab i.endo i.pcos i.antipsychotics_prepreg i.moodstabs_prepreg i.teratogen_prepreg i.folic_prepreg1 i.depression i.anxiety i.ed i.pain i.migraine i.incont i.headache i.severe_mental_illness, basesurv(S0)
		summ S0 if _t<=168
		local S0 = r(min)
	
		margins cf_unexposed, expression(1-`S0'^exp(predict(xb))) grand nose 
		
		matrix risk_table = r(table)
		
		return scalar risk_exp = risk_table[1,1]
		return scalar risk_unexp = risk_table[1,2]
		
		cap drop S0
		
	end
		
	bootstrap r(risk_exp) r(risk_unexp), reps(1000): risk
	
********************************************************************************/

* Pattern analysis marginal risk

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	cap program drop risk
	
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	
	gen matage_sq = matage*matage
			
	* multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date, origin - subject becomes at risk at the pregnancy start date, scale
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
			
	tab cf_prev_incid
	sum cycle_1_start
	
	* split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_prev_incid=0 if exposure_up==-1
					
	replace cf_prev_incid=3 if exposure_up==0 & cycle_1_start!=.
	tab cf_prev_incid exposure_up
					
	recode cf_prev_incid 3=2
	tab cf_prev_incid
	recode misc .=0
					
	lab define cf_prev_incid 2 "exposed-new users" 1"prevalent users"  0 unexposed
	label values cf_prev_incid cf_prev_incid
	tab cf_prev_incid
	tab misc
	tab misc cf_prev_incid, col
	
	program risk, rclass
	
		stcox i.cf_prev_incid matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid) basesurv(S0)
		summ S0 if _t<=168, meanonly
		local S0 = r(min)
	
		margins cf_prev_incid, expression(1-`S0'^exp(predict(xb))) grand nose 
		
		matrix risk_table = r(table)
		
		return scalar risk_unexp = risk_table[1,3]
		return scalar risk_prev_exp = risk_table[1,2]
		return scalar risk_incid_exp = risk_table[1,1]
		
		cap drop S0
		
	end
		
	bootstrap r(risk_incid_exp) r(risk_prev_exp) r(risk_unexp), reps(1000): risk
	
	// marginal risk in unexposed 13.10837% (bootstrapped CIs 13.03803-13.1787)
	// marginal risk in prevalent exposed 13.14398% (bootstrapped CIs 12.88498-13.40297)
	// marginal risk in incident exposed 15.96196% (bootstrapped CIs 15.31315-16.61077)
	
	import delimited using "$Graphdir\marginal risk.txt", clear
	
	tab x
	
	replace x = "Prevalent" if x=="Exposed"
	set obs `=_N+1'
	replace x = "Incident" if x==""
	tab x
	
	replace risk = 13.10837 if x == "Unexposed"
	replace lci = 13.03803 if x == "Unexposed"
	replace uci = 13.1787 if x == "Unexposed"
	
	replace risk = 13.14398 if x == "Prevalent"
	replace lci = 12.88498 if x == "Prevalent"
	replace uci = 13.40297 if x == "Prevalent"
	
	replace risk = 15.96196 if x == "Incident"
	replace lci = 15.31315 if x == "Incident"
	replace uci = 16.61077 if x == "Incident"
	
	save "$Graphdir\marginal risk patterns.dta", replace
	
********************************************************************************

	log using "$Logdir\2_analysis\supp_marginal absolute risk class", name(supp_marginal_absolute_risk) replace

* Class analysis marginal risk
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	cap program drop risk

	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	
	tab cf_class
	replace cf_class = 0 if cf_unexposed==0
	tab cf_class
			
	gen cf_class_og=cf_class
	gen matage_sq = matage*matage
			
	* multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date, origin - subject becomes at risk at the pregnancy start date, scale - rescale time value by day?
	stset end_fup, fail(misc) id(pregid) enter(start_date) origin(start_date)
			
	tab cf_class
	sum cycle_1_start
	* split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_class=0 if exposure_up==-1
					
	replace cf_class=5 if exposure_up==0 & cycle_1_start!=.
	tab cf_class exposure_up
					
	recode cf_class 5=1 if cf_class_og==1
	recode cf_class 5=2 if cf_class_og==2
	recode cf_class 5=3 if cf_class_og==3
	recode cf_class 5=4 if cf_class_og==4
	recode cf_class 5=5 if cf_class_og==5
	tab cf_class
	drop cf_class_og
				
	recode misc .=0
					
	tab cf_class
	tab misc
	tab misc cf_class, col chi
	
	program risk, rclass
	
		stcox i.cf_class matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid) basesurv(S0)
		summ S0 if _t<=168, meanonly
		local S0 = r(min)
	
		margins cf_class, expression(1-`S0'^exp(predict(xb))) grand nose 
		
		matrix risk_table = r(table)
		
		return scalar risk_unexp = risk_table[1,1]
		return scalar risk_ssri_exp = risk_table[1,2]
		return scalar risk_snri_exp = risk_table[1,3]
		return scalar risk_tca_exp = risk_table[1,4]
		return scalar risk_other_exp = risk_table[1,5]
		return scalar risk_multi_exp = risk_table[1,6]
		
		cap drop S0
		
	end
		
	bootstrap r(risk_unexp) r(risk_ssri_exp) r(risk_snri_exp) r(risk_tca_exp) r(risk_other_exp) r(risk_multi_exp), reps(1000): risk
	
	// marginal risk in unexposed 13.10564% (bootstrapped CIs 13.03361-13.17768)
	// marginal risk in ssri exposed 13.45503% (bootstrapped CIs 13.15455-13.7555)
	// marginal risk in snri exposed 13.56034% (bootstrapped CIs 12.58564-14.53504)
	// marginal risk in tca exposed 13.85885% (bootstrapped CIs 13.2051-14.51259)
	// marginal risk in other exposed 14.64617% (bootstrapped CIs 13.5395-15.75285)
	// marginal risk in multi exposed 13.4548% (bootstrapped CIs 12.53812-14.37148)
	
	import delimited using "$Graphdir\marginal risk.txt", clear
	
	tab x
	
	replace x = "ssri" if x=="Exposed"
	set obs `=_N+1'
	replace x = "snri" if x==""
	set obs `=_N+1'
	replace x = "tca" if x==""
	set obs `=_N+1'
	replace x = "other" if x==""
	set obs `=_N+1'
	replace x = "multi" if x==""
	tab x
	
	replace risk = 13.10564 if x == "Unexposed"
	replace lci = 13.03361 if x == "Unexposed"
	replace uci = 13.17768 if x == "Unexposed"
	
	replace risk = 13.45503 if x == "ssri"
	replace lci = 13.15455 if x == "ssri"
	replace uci = 13.7555 if x == "ssri"
	
	replace risk = 13.56034 if x == "snri"
	replace lci = 12.58564 if x == "snri"
	replace uci = 14.53504 if x == "snri"
	
	replace risk = 13.85885 if x == "tca"
	replace lci = 13.2051 if x == "tca"
	replace uci = 14.51259 if x == "tca"
	
	replace risk = 14.64617 if x == "other"
	replace lci = 13.5395 if x == "other"
	replace uci = 15.75285 if x == "other"
	
	replace risk = 13.4548 if x == "multi"
	replace lci = 12.53812 if x == "multi"
	replace uci = 14.37148 if x == "multi"
	
	save "$Graphdir\marginal risk class.dta", replace
	
	log close supp_marginal_absolute_risk
	
	translate "$Logdir\2_analysis\supp_marginal absolute risk class.smcl" "$Logdir\2_analysis\supp_marginal absolute risk class.pdf", replace
	
	erase "$Logdir\2_analysis\supp_marginal absolute risk class.smcl"
	
********************************************************************************

	log using "$Logdir\2_analysis\supp_marginal absolute risk dose", name(supp_marginal_absolute_risk) replace

* Class analysis marginal risk
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	cap program drop risk

	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	
	gen matage_sq = matage*matage
	
	recode cf_dose .=0
	tab cf_dose
			
	gen cf_dose_og=cf_dose
			
	* multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date, origin - subject becomes at risk at the pregnancy start date, scale - rescale time value by day?
	stset end_fup, fail(misc) id(pregid) enter(start_date) origin(start_date)
			
	tab cf_dose
	sum cycle_1_start
	* split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_dose=0 if exposure_up==-1
					
	replace cf_dose=3 if exposure_up==0 & cycle_1_start!=.
	tab cf_dose exposure_up
					
	recode cf_dose 3=1 if cf_dose_og==1
	recode cf_dose 3=2 if cf_dose_og==2
	recode cf_dose 3=3 if cf_dose_og==3
	tab cf_dose
	drop cf_dose_og

	recode misc .=0
	
	program risk, rclass
	
		stcox i.cf_dose matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid) basesurv(S0)
		summ S0 if _t<=168, meanonly
		local S0 = r(min)
	
		margins cf_dose, expression(1-`S0'^exp(predict(xb))) grand nose 
		
		matrix risk_table = r(table)
		
		return scalar risk_unexp = risk_table[1,1]
		return scalar risk_low_exp = risk_table[1,2]
		return scalar risk_med_exp = risk_table[1,3]
		return scalar risk_high_exp = risk_table[1,4]
		
		cap drop S0
		
	end
		
	bootstrap r(risk_unexp) r(risk_low_exp) r(risk_med_exp) r(risk_high_exp), reps(1000): risk
	
	// marginal risk in unexposed 13.10616% (bootstrapped CIs 13.03366-13.17866)
	// marginal risk in low exposed 13.65165% (bootstrapped CIs 13.2902-14.01311)
	// marginal risk in med exposed 13.72512% (bootstrapped CIs 13.358-14.09223)
	// marginal risk in high exposed 12.68438% (bootstrapped CIs 12.06763-13.30114)
	
	import delimited using "$Graphdir\marginal risk.txt", clear
	
	tab x
	
	replace x = "low" if x=="Exposed"
	set obs `=_N+1'
	replace x = "med" if x==""
	set obs `=_N+1'
	replace x = "high" if x==""
	tab x
	
	replace risk = 13.10616 if x == "Unexposed"
	replace lci = 13.03366 if x == "Unexposed"
	replace uci = 13.17866 if x == "Unexposed"
	
	replace risk = 13.65165 if x == "low"
	replace lci = 13.2902 if x == "low"
	replace uci = 14.01311 if x == "low"
	
	replace risk = 13.72512 if x == "med"
	replace lci = 13.358 if x == "med"
	replace uci = 14.09223 if x == "med"
	
	replace risk = 12.68438 if x == "high"
	replace lci = 12.06763 if x == "high"
	replace uci = 13.30114 if x == "high"
	
	save "$Graphdir\marginal risk dose.dta", replace
	
	log close supp_marginal_absolute_risk
	
	translate "$Logdir\2_analysis\supp_marginal absolute risk dose.smcl" "$Logdir\2_analysis\supp_marginal absolute risk dose.pdf", replace
	
	erase "$Logdir\2_analysis\supp_marginal absolute risk dose.smcl"

*******************************************************************************

	* Prepare tables elements for the figure dataset
	tempname myhandle	
	file open `myhandle' using "$Graphdir\marginal risk.txt", write replace
	file write `myhandle' "x" _tab "risk" _tab "lci" _tab "uci" _n
	
	file write `myhandle' ("Unexposed") _tab (`unexp_risk_percent') _tab (`unexp_risk_lci') _tab (`unexp_risk_uci') _n
	
	file write `myhandle' ("Exposed") _tab (`exp_risk_percent') _tab (`exp_risk_lci') _tab (`exp_risk_uci') _n
	
*******************************************************************************

* Stop logging
		
	log close marginal_risk_dataset
	
	translate "$Logdir\2_analysis\2_marginal risk dataset.smcl" "$Logdir\2_analysis\2_marginal risk dataset.pdf", replace
	
	erase "$Logdir\2_analysis\2_marginal risk dataset.smcl"

********************************************************************************
