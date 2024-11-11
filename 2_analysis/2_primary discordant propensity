********************************************************************************

* Creating table 2 for miscarriage paper - primary analysis, exposure discordant pregnancy analysis and propensity score analysis

* Author: Flo Martin 

* Date: 08/10/2024

********************************************************************************

* Table S6 - Findings from the primary and secondary analysis (Figure 2) with total contributed days of follow-up.

********************************************************************************

* Start logging

	log using "$Logdir\2_analysis\2_primary discordant propensity", name(primary_discordant_propensity) replace
	
********************************************************************************

	* Set up the table elements
	tempname myhandle	
	file open `myhandle' using "$Tabledir\primary analysis.txt", write replace
	file write `myhandle' "" _tab "Total" _tab "n/N (%)" _tab "Total contributed time (days)" _tab "HR (95%CI)" _tab "aHR (95%CI)" _n
	file write `myhandle' "Primary analyses" _n

********************************************************************************
	
	file write `myhandle' "Primary Cox model" _n
	
* Primary analysis - Cox proportional hazards model of antidepressant use during pregnancy and miscarriage
	
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
	
	* Create the count macros for the table
	count
	local n=`r(N)'
	
	* Number of miscarriages in the exposed
	count if _d==1 & cf_unexposed==1
	local exp_n=`r(N)'
	
	* Number of exposed
	count if cf_unexposed==1
	local exp_total=`r(N)'
	
	* % of miscarriage in exposed
	local exp_pct=((`exp_n')/(`exp_total'))*100
	
	* Total days follow-up in the exposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}
	
	* Number of miscarriages in the unexposed
	count if _d==1 & cf_unexposed==0
	local unexp_n=`r(N)'
	
	* Number of unexposed
	count if cf_unexposed==0
	local unexp_total=`r(N)'
		
	* % of miscarriage in unexposed
	local unexp_pct=((`unexp_n')/(`unexp_total'))*100
	
	* Total days follow-up in the exposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
	
********************************************************************************
	
		* Add the elements to the first row of the table
		file write `myhandle' ("Unexposed in T1") _tab %9.0fc (`n') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %16.0fc (`unexp_pY') _tab ("1.00 (ref)") _tab ("1.00 (ref)") _n
		 
		file write `myhandle' ("Exposed in T1") _tab ("") _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %14.0fc (`exp_pY') 

********************************************************************************

	* Unadjusted 
	stcox i.cf_unexposed, vce(cluster patid) 
	
	count
	local tot=`e(N)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
	
********************************************************************************
				    
		* Add the elements to the table
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 
		
********************************************************************************

	gen matage_sq = matage*matage

	* Fully-adjusted 
	stcox i.cf_unexposed matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid) 
				
	count
	local tot=`e(N)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
	
********************************************************************************
		
		* Add the elements to the table
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
					
********************************************************************************

	file write `myhandle' "Exposure discordant analysis" _n

* Exposure discordant analysis 

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
		
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

	* Create the count macros for the table
	count
	local n=`r(N)'
	
	* Number of miscarriages in the exposed
	count if _d==1 & cf_unexposed==1
	local exp_n=`r(N)'
	
	* Number of exposed
	count if cf_unexposed==1
	local exp_total=`r(N)'
	
	* % of miscarriages in the exposed
	local exp_pct=((`exp_n')/(`exp_total'))*100
		
	* Total days follow-up in the exposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}
	
	* Number of miscarriages in the unexposed
	count if _d==1 & cf_unexposed==0
	local unexp_n=`r(N)'
	
	* Number of unexposed
	count if cf_unexposed==0
	local unexp_total=`r(N)'
	
	* % of miscarriages in the unexposed
	local unexp_pct=((`unexp_n')/(`unexp_total'))*100
	
	* Total days follow-up in the unexposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
	
********************************************************************************
		
		* Add elements to the table
		file write `myhandle' ("Unexposed in T1") _tab %9.0fc (`n') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %16.0fc (`unexp_pY') _tab ("1.00 (ref)") _tab ("1.00 (ref)") _n
		 
		file write `myhandle' ("Exposed in T1") _tab ("") _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %14.0fc (`exp_pY')  

********************************************************************************

	* Unadjusted 
	stcox i.cf_unexposed, vce(cluster patid) strata(patid) 
			
	count
	local tot=`e(N)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
	
********************************************************************************
		
		* Add elements to the table
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 
		
********************************************************************************

	gen matage_sq = matage*matage

	* Fully adjusted 
	stcox i.cf_unexposed matage matage_sq i.preg_yr_gp i.smokstatus i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid) strata(patid) 

	count
	local tot=`e(N)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
	
********************************************************************************
					
		* Add the elements to the table
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
		
********************************************************************************

	file write `myhandle' "Propensity score matched analysis" _n

* Propensity score matched analysis

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	merge 1:1 patid pregid using "$Deriveddir\covariates\pregnancy_cohort_covariates.dta",  keep(match master) nogen
	
	* Summarise variables for formatting to pull into R to perform propensity score matching
	* Pregnancy year
	tab preg_year
	
	* Maternal age
	tab matage
	
	* Area of residence 
	tab AreaOfResidence
	label drop AreaOfResidence
	tab AreaOfResidence
	
	* IMD practice quintiles
	tab imd_practice
	
	* Alcohol consumption around the start of pregnancy
	tab alcstatus
	gen alcstatus_num = 0 if alcstatus==0
	replace alcstatus_num = 1 if alcstatus==1
	replace alcstatus_num = 2 if alcstatus==2
	
	* Smoking status around the start of pregnancy
	tab smokstatus
	gen smokstatus_num = 0 if smokstatus==0
	replace smokstatus_num = 1 if smokstatus==1
	replace smokstatus_num = 2 if smokstatus==2
	
	* Illicit drug use in the 12 months prior to pregnancy
	tab illicitdrug_12mo
	
	* CPRD consultations in the 12 months prior to pregnancy
	tab CPRD_consultation_events_cat
	gen CPRD_consultation_events_cat_num = 0 if CPRD_consultation_events_cat==0
	replace CPRD_consultation_events_cat_num = 1 if CPRD_consultation_events_cat==1
	replace CPRD_consultation_events_cat_num = 2 if CPRD_consultation_events_cat==2
	replace CPRD_consultation_events_cat_num = 3 if CPRD_consultation_events_cat==3
	
	* Maternal chronic diabetes ever
	tab diab
	
	* Maternal endometriosis ever
	tab endo
	format endo %1.0fc
	tab endo
	
	* Maternal PCOS ever
	tab pcos
	
	* Maternal high blood pressure ever
	tab hypbp
	
	* Antipsychotic use in the 12 months prior to pregnancy
	tab antipsychotics_prepreg
	* Anti-seizure medication in the 12 months prior to pregnancy
	tab moodstabs_prepreg
	* Teratogen use in the 12 months prior to pregnancy
	tab teratogen_prepreg
	* High-dose folic acid prescriptions in the 12 months prior to pregnancy
	tab folic_prepreg1
	
	* Miscarriage - outcome
	tab misc
	recode misc .=0
	tab misc
	
	* Antidepressant use during trimester one - exposure
	tab cf_unexposed
	
	count if parity==0 & hes_apc_e !=. & misc !=. & cf_discont !=. & cf_unexposed !=. & preg_year !=. & matage !=. & AreaOfResidence !=. & imd_practice !=. & bmi !=. & alcstatus_num !=. & smokstatus_num !=. & illicitdrug_12mo !=. & CPRD_consultation_events_cat_num !=. & diab !=. & endo !=. & pcos !=. & antipsychotics_prepreg !=. & moodstabs_prepreg !=. & teratogen_prepreg !=. & folic_prepreg1 !=. & depression !=. & anxiety !=. & ed !=. & pain !=. & migraine !=. & incont !=. & headache !=. & severe_mental_illness!=.
	
	* Data management
	keep patid pregid pregnum_new hes_apc_e cycle_1_start start_date end_fup misc cf_discont cf_unexposed preg_year matage AreaOfResidence imd_practice bmi alcstatus_num smokstatus_num illicitdrug_12mo CPRD_consultation_events_cat_num diab endo pcos hypbp antipsychotics_prepreg moodstabs_prepreg teratogen_prepreg folic_prepreg1 depression anxiety ed pain migraine incont headache severe_mental_illness grav_hist_sa grav_hist_sb
	
	format start_date %tg
	format cycle_1_start %tg
	format end_fup %tg
	
	* Save the data as .csv for pulling into R
	export delimited "$Datadir\pscore_analysis_dataset_r.csv", replace

********************************************************************************

/* Run the propensity score matching script in R - primary analysis
		
		"2_analysis\2a_propensity score analysis.R"
		
*/

********************************************************************************

* Import the propensity score matched data generated from the above R script

	import delimited "$Datadir\ps_matched_data.csv", clear	
	count
	
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

	* Create count macros for the table
	count
	local n=`r(N)'
	
	* Number of miscarriages in the exposed
	count if _d==1 & cf_unexposed==1
	local exp_n=`r(N)'
	
	* Number of exposed
	count if cf_unexposed==1
	local exp_total=`r(N)'
	
	* % of miscarriages in the exposed
	local exp_pct=((`exp_n')/(`exp_total'))*100
	
	* Total days follow-up in the exposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}
	
	* Number of miscarriages in the unexposed
	count if _d==1 & cf_unexposed==0
	local unexp_n=`r(N)'
	
	* Number of unexposed				
	count if cf_unexposed==0
	local unexp_total=`r(N)'
	
	* % of miscarriages in the unexposed
	local unexp_pct=((`unexp_n')/(`unexp_total'))*100
	
	* Total days follow-up in the exposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}

********************************************************************************
	
		* Add the elements to the table
		file write `myhandle' ("Unexposed in T1") _tab %9.0fc (`n') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %16.0fc (`unexp_pY') _tab ("1.00 (ref)") _tab ("1.00 (ref)") _n
		 
		file write `myhandle' ("Exposed in T1") _tab ("") _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %14.0fc (`exp_pY') 
		
********************************************************************************

* Generate the squared continuous covariates from the PS model
			
	gen matage_sq=matage*matage
	gen bmi_sq=bmi*bmi
	
	* Unadjusted
	
********************************************************************************

		* Add the elements to the table
		file write `myhandle' _tab ("-") // this is a matched sample so there is no unadjusted estimate
		
********************************************************************************
		
	* Adjusted - doubly robust estimator (covariates specified in the propensity score matching and the model)
	stcox i.cf_unexposed preg_year hes_apc_e areaofresidence matage matage_sq imd_practice bmi bmi_sq alcstatus_num smokstatus_num illicitdrug_12mo cprd_consultation_events_cat_num diab endo pcos antipsychotics_prepreg moodstabs_prepreg teratogen_prepreg folic_prepreg1 depression anxiety ed pain migraine incont headache severe_mental_illness
	
	count
	local tot=`e(N)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'

********************************************************************************
		
		* Add the elements to the table
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
		
********************************************************************************

* Stop logging
		
	log close primary_discordant_propensity
	
	translate "$Logdir\2_analysis\2_primary discordant propensity.smcl" "$Logdir\2_analysis\2_primary discordant propensity.pdf", replace
	
	erase "$Logdir\2_analysis\2_primary discordant propensity.smcl"

********************************************************************************
