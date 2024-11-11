********************************************************************************

* Creating the primary figure dataset

* Author: Flo Martin 

* Date: 25/09/2024

********************************************************************************

* Dataset needed to create the forest plot part of the primary figure

********************************************************************************

* Start logging 

	log using "$Logdir\3_figures\1_primary figure dataset", name(primary_figure_dataset) replace
	
********************************************************************************

	* Prepare the table elements
	tempname myhandle	
	file open `myhandle' using "$Graphdir\results fig data.txt", write replace
	file write `myhandle' "outcome" _tab "model" _tab "misc" _tab "total" _tab "pct" _tab "unadj_or" _tab "unadj_lci" _tab "unadj_uci" _tab "or" _tab "lci" _tab "uci" _n

********************************************************************************
	
	* Primary analysis
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=. & smokstatus!=.
	keep if cc==1
	
	gen matage_sq = matage*matage
	
	* stset data with outcome under study
	stset end_fup, fail(misc) id(pregid) enter(start_date)  
	* stsplit for T1 initiators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	
	replace cf_unexposed=0 if exposure_up==-1		
	replace cf_unexposed=2 if exposure_up==0 & cycle_1_start!=.
	* Combine new and prevalent users:
	recode cf_unexposed 2=1
	
	forvalues level=0/1 {
	
		* Create counts for the table
		count if _d==1 & cf_unexposed==`level'
		local n_`level'=`r(N)'
				
		count if cf_unexposed==`level'
		local total_`level'=`r(N)'
				
		local pct_`level'=((`n_`level'')/(`total_`level''))*100
		
		stcox i.cf_unexposed, vce(cluster patid)
		
		lincom _b[`level'.cf_unexposed], hr
		local minunadjhr=`r(estimate)'
		local minunadjuci=`r(ub)'
		local minunadjlci=`r(lb)'
		
		stcox i.cf_unexposed matage matage_sq i.preg_yr_gp i.grav_hist_sa i.smokstatus i.imd_practice i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid)
		
		lincom _b[`level'.cf_unexposed], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'

********************************************************************************
			
			* Add the table elements
			file write `myhandle' "misc" _tab "primary" _tab (`n_`level'') _tab (`total_`level'') _tab (`pct_`level'') _tab (`minunadjhr') _tab (`minunadjlci') _tab (`minunadjuci') _tab (`minadjhr') _tab (`minadjlci') _tab (`minadjuci') _n
			
********************************************************************************
			
	}

********************************************************************************

	* Exposure discordant pregnancy analysis
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
		
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=. & smokstatus!=.
	keep if cc==1
	
	gen matage_sq = matage*matage

	* Drop women with one preg in study period
	duplicates tag patid, gen(dupes)
	drop if dupes==0 // 604,744 remaining (multiparous)

	* Drop women with same exposure in each pregnancy
	bysort patid: gen diff=1 if cf_unexposed != cf_unexposed[_n-1] & _n!=1
	bysort patid: egen diff_max=max(diff)
	keep if diff_max==1 // 527,359 concordant dropped

	* stset data with outcome under study
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
	* stsplit for T1 initiators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	
	replace cf_unexposed=0 if exposure_up==-1
	replace cf_discont=. if exposure_up==-1
	replace cf_unexposed=2 if exposure_up==0 & cycle_1_start!=.
	* Combine new and prevalent users:
	recode cf_unexposed 2=1
	
	* Generate variable for exposed, then unexp
			bysort patid (pregstart_num): gen first_exposed=1 if cf_unexposed[_n==1]==1
			bysort patid: egen first_exposed_max=max(first_exposed)

		* Generate variable for unexposed, then exposed 
		bysort patid (pregstart_num): gen first_unexp=1 if cf_unexposed[_n==1]==0
		bysort patid: egen first_unexp_max=max(first_unexp)
	
	forvalues level=0/1 {
	
		* Create counts for the table
		count if _d==1 & cf_unexposed==`level'
		local n_`level'=`r(N)'
				
		count if cf_unexposed==`level'
		local total_`level'=`r(N)'
				
		local pct_`level'=((`n_`level'')/(`total_`level''))*100
		
		stcox i.cf_unexposed, vce(cluster patid) strata(patid)
		
		lincom _b[`level'.cf_unexposed], hr
		local minunadjhr=`r(estimate)'
		local minunadjuci=`r(ub)'
		local minunadjlci=`r(lb)'
		
		stcox i.cf_unexposed matage matage_sq i.preg_yr_gp i.smokstatus i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid) strata(patid)
		
		lincom _b[`level'.cf_unexposed], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
		
********************************************************************************
						
			* Add the table elements
			file write `myhandle' "misc" _tab "discordant" _tab (`n_`level'') _tab (`total_`level'') _tab (`pct_`level'') _tab (`minunadjhr') _tab (`minunadjlci') _tab (`minunadjuci') _tab (`minadjhr') _tab (`minadjlci') _tab (`minadjuci') _n
	
********************************************************************************

	}

********************************************************************************

	* Propensity score matched analysis
	
	import delimited "$Datadir\ps_matched_data.csv", clear	
	count
	
	gen cycle_1_start_num = real(cycle_1_start)
	drop cycle_1_start
	rename cycle_1_start_num cycle_1_start
	
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
	stsplit exposure_updated, after(cycle_1_start) at(0)
	
	replace cf_unexposed=0 if exposure_up==-1
	replace cf_unexposed=2 if exposure_up==0 & cycle_1_start!=.
	* Combine new and prevalent users:
	recode cf_unexposed 2=1
	
	gen matage_sq=matage*matage
	gen bmi_sq=bmi*bmi
	
	forvalues level=0/1 {
	
		* Create counts for the table
		count if _d==1 & cf_unexposed==`level'
		local n_`level'=`r(N)'
				
		count if cf_unexposed==`level'
		local total_`level'=`r(N)'
				
		local pct_`level'=((`n_`level'')/(`total_`level''))*100
		
		stcox i.cf_unexposed preg_year hes_apc_e matage matage_sq areaofresidence imd_practice bmi bmi_sq alcstatus_num smokstatus_num illicitdrug_12mo cprd_consultation_events_cat_num diab endo pcos antipsychotics_prepreg moodstabs_prepreg teratogen_prepreg folic_prepreg1 depression anxiety ed pain migraine headache incont
		
		lincom _b[`level'.cf_unexposed], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'

********************************************************************************

			* Add the table elements
			file write `myhandle' "misc" _tab "propensity" _tab (`n_`level'') _tab (`total_`level'') _tab (`pct_`level'') _tab _tab _tab _tab (`minadjhr') _tab (`minadjlci') _tab (`minadjuci') _n

********************************************************************************

	}

********************************************************************************

	* Pattern analysis
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
			
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=. & smokstatus!=.
	keep if cc==1
	
	gen matage_sq = matage*matage
	
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
	stsplit exposure_updated, after(cycle_1_start) at(0)
	
	replace cf_prev_incid=0 if exposure_up==-1		
	replace cf_prev_incid=3 if exposure_up==0 & cycle_1_start!=.
	recode cf_prev_incid 3=2
	
	foreach level in 0 1 2 {
		
		* Create counts for the table
		count if _d==1 & cf_prev_incid==`level'
		local n_`level'=`r(N)'
				
		count if cf_prev_incid==`level'
		local total_`level'=`r(N)'
				
		local pct_`level'=((`n_`level'')/(`total_`level''))*100
		
		stcox i.cf_prev_incid, vce(cluster patid)
		
		lincom _b[`level'.cf_prev_incid], hr
		local minunadjhr=`r(estimate)'
		local minunadjuci=`r(ub)'
		local minunadjlci=`r(lb)'
		
		stcox i.cf_prev_incid matage matage_sq i.preg_yr_gp i.grav_hist_sa i.smokstatus i.imd_practice i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid)
		
		lincom _b[`level'.cf_prev_incid], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'

********************************************************************************

		file write `myhandle' "misc" _tab "pattern `level'" _tab (`n_`level'') _tab (`total_`level'') _tab (`pct_`level'') _tab (`minunadjhr') _tab (`minunadjlci') _tab (`minunadjuci') _tab (`minadjhr') _tab (`minadjlci') _tab (`minadjuci') _n
		
********************************************************************************
		
	}

********************************************************************************

	* Class analysis
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
			
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=. & smokstatus!=.
	keep if cc==1
	
	tab cf_class
	replace cf_class = 0 if cf_class==.
	tab cf_class
			
	gen cf_class_og=cf_class
	gen matage_sq = matage*matage

	stset end_fup, fail(misc) id(pregid) enter(start_date) 
	* split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
			
	replace cf_class=0 if exposure_up==-1
	replace cf_class=5 if exposure_up==0 & cycle_1_start!=.
					
	recode cf_class 5=1 if cf_class_og==1
	recode cf_class 5=2 if cf_class_og==2
	recode cf_class 5=3 if cf_class_og==3
	recode cf_class 5=4 if cf_class_og==4
	recode cf_class 5=5 if cf_class_og==5
	
	foreach level in 0 1 2 3 4 5 {
		
		* Create counts for the table
		count if _d==1 & cf_class==`level'
		local n_`level'=`r(N)'
				
		count if cf_class==`level'
		local total_`level'=`r(N)'
				
		local pct_`level'=((`n_`level'')/(`total_`level''))*100
		
		stcox i.cf_class, vce(cluster patid)
		
		lincom _b[`level'.cf_class], hr
		local minunadjhr=`r(estimate)'
		local minunadjuci=`r(ub)'
		local minunadjlci=`r(lb)'
		
		stcox i.cf_class matage matage_sq i.preg_yr_gp i.grav_hist_sa i.smokstatus i.imd_practice i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid)
		
		lincom _b[`level'.cf_class], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'

********************************************************************************

		* Add the table elements
		file write `myhandle' "misc" _tab "class `level'" _tab (`n_`level'') _tab (`total_`level'') _tab (`pct_`level'') _tab (`minunadjhr') _tab (`minunadjlci') _tab (`minunadjuci') _tab (`minadjhr') _tab (`minadjlci') _tab (`minadjuci') _n

********************************************************************************

	}

********************************************************************************

	* Dose analysis
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
			
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=. & smokstatus!=.
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
			
	levelsof cf_dose, local(explevel)
	
	foreach level of local explevel {
		
		* Create counts for the table
		count if _d==1 & cf_dose==`level'
		local n_`level'=`r(N)'
				
		count if cf_dose==`level'
		local total_`level'=`r(N)'
				
		local pct_`level'=((`n_`level'')/(`total_`level''))*100
		
		stcox i.cf_dose, vce(cluster patid)
		
		lincom _b[`level'.cf_dose], hr
		local minunadjhr=`r(estimate)'
		local minunadjuci=`r(ub)'
		local minunadjlci=`r(lb)'
		
		stcox i.cf_dose matage matage_sq i.preg_yr_gp i.grav_hist_sa i.smokstatus i.imd_practice i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid)
		
		lincom _b[`level'.cf_dose], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'

********************************************************************************

		* Add the table elements
		file write `myhandle' "misc" _tab "dose `level'" _tab (`n_`level'') _tab (`total_`level'') _tab (`pct_`level'') _tab (`minunadjhr') _tab (`minunadjlci') _tab (`minunadjuci') _tab (`minadjhr') _tab (`minadjlci') _tab (`minadjuci') _n

********************************************************************************

	}
	
********************************************************************************	
	
* Stop logging

	log close primary_figure_dataset
	
	translate "$Logdir\3_figures\1_primary figure dataset.smcl" "$Logdir\3_figures\1_primary figure dataset.pdf", replace
	
	erase "$Logdir\3_figures\1_primary figure dataset.smcl"
	
********************************************************************************
