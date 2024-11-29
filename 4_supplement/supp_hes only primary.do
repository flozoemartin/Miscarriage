
********************************************************************************

* Creating supplementary table for miscarriage paper - restricting to those with linked data

* Author: Flo Martin 

* Date: 27/09/2024

********************************************************************************

* Supplementary table of primary analyses restricted to those with linked data created by this script

********************************************************************************
* Start logging

	log using "$Logdir\4_supplement\supp_hes only primary", name(supp_hes_only_primary) replace
	
********************************************************************************

* Set up the table elements

	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_hes only primary.txt", write replace
	file write `myhandle' "" _tab "Total" _tab "Exposed n/N (%)" _tab "Total exposed time (in days)" _tab "Unexposed n/N (%)" _tab "Total unexposed time (in days)" _tab "HR (95% CI)" _tab "aHR* (95% CI)" _n

********************************************************************************
	
	* Primary analysis - Cox proportional hazards model of antidepressant use during pregnancy and miscarriage
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	keep if hes_apc_e==1
	
	* multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date, origin - subject becomes at risk at the pregnancy start date, scale - rescale time value by day?
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
			
	tab cf_unexposed
				
	sum cycle_1_start
	* split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	
	tab exposure_up, miss
	replace cf_unexposed=0 if exposure_up==-1		
	replace cf_unexposed=2 if exposure_up==0 & cycle_1_start!=.
	tab cf_unexposed exposure_up
					
	recode cf_unexposed 2=1
	tab cf_unexposed
	recode misc .=0
					
	lab define cf_unexposed 1 "exposed-prev+new users"  0 unexposed
	label values cf_unexposed cf_unexposed
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
		file write `myhandle' ("Primary analysis") _tab %9.0fc (`n') _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %12.0fc (`unexp_pY')
		
********************************************************************************

	* Unadjusted 
	stcox i.cf_unexposed, vce(cluster patid)
				
	local tot=`e(N_sub)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'

********************************************************************************
		
		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")")
		
********************************************************************************

	* Fully-adjusted 
	stcox i.cf_unexposed matage i.preg_yr_gp i.grav_hist_sa i.smokstatus i.imd_practice i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid)
				
	di `tot'
	local tot=`e(N_sub)'
	lincom _b[1.cf_unexposed], rrr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'

********************************************************************************
		
		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
					
********************************************************************************

* Exposure discordant analysis 

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
		
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	keep if hes_apc_e==1

	* Drop women with one preg in study period
	duplicates tag patid, gen(dupes)
	ta dupes
	drop if dupes==0 // 604,744 remaining (multiparous)

	* Drop women with same exposure in each pregnancy
	bysort patid: gen diff=1 if cf_unexposed != cf_unexposed[_n-1] & _n!=1
	bysort patid: egen diff_max=max(diff)
	keep if diff_max==1 // 527,359 concordant dropped
	codebook patid 	/*10,959 women*/
	codebook pregid /*31,567 pregnancies*/

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

	* Combine new and prevalent users:
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
		file write `myhandle' ("Exposure discordant pregnancy analysis") _tab %9.0fc (`n') _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %12.0fc (`unexp_pY')
		
********************************************************************************

	* Unadjusted 
	stcox i.cf_unexposed, vce(cluster patid) strata(patid) 
			
	local tot=`e(N_sub)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'

********************************************************************************
		
		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 

********************************************************************************

	* Fully adjusted 
	stcox i.cf_unexposed matage i.preg_yr_gp i.smokstatus i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid) strata(patid) 

	di `tot'
	local tot=`e(N_sub)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'

********************************************************************************
		
		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
		
********************************************************************************

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
	
	* Data management
	keep patid pregid pregnum_new hes_apc_e cycle_1_start start_date end_fup misc cf_discont cf_unexposed preg_year matage AreaOfResidence imd_practice bmi alcstatus_num smokstatus_num illicitdrug_12mo CPRD_consultation_events_cat_num diab endo pcos antipsychotics_prepreg moodstabs_prepreg teratogen_prepreg folic_prepreg1 depression anxiety ed pain migraine incont headache severe_mental_illness grav_hist_sa grav_hist_sb
	
	format start_date %tg
	format cycle_1_start %tg
	format end_fup %tg
	
	keep if hes_apc_e==1
	
	export delimited "$Datadir\pscore_analysis_dataset_r_hes_only.csv", replace 
	
********************************************************************************

/* Run the propensity score matching script in R - sensitivity analysis (HES only)
		
		"$RScript\2_pregnancy outcomes\propensity score analysis.R"
		
*/

********************************************************************************

* Import the data from R

	import delimited "$Datadir\ps_matched_data_hes_only.csv", clear	
	count
	
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

	* Combine new and prevalent users:
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
	
	* Total days follow-up in the unexposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}

********************************************************************************
	
		* Add the elements to the table
		file write `myhandle' ("Propensity score matched analysis") _tab %9.0fc (`n') _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %12.0fc (`unexp_pY')
		
********************************************************************************
 
	gen matage_sq=matage*matage
	gen bmi_sq=bmi*bmi
	
	* Unadjusted
	
********************************************************************************
		
		* Add the table elements
		file write `myhandle' _tab ("-") // this is a matched sample so there is no unadjusted estimate
		
********************************************************************************
		
	* Adjusted
	stcox i.cf_unexposed preg_year matage matage_sq areaofresidence imd_practice bmi bmi_sq alcstatus_num smokstatus_num illicitdrug_12mo cprd_consultation_events_cat_num diab endo pcos antipsychotics_prepreg moodstabs_prepreg teratogen_prepreg folic_prepreg1 depression anxiety ed pain migraine headache incont severe_mental_illness
	
	local tot=`e(N_sub)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
	
********************************************************************************
		
		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
		
********************************************************************************

* Stop logging
		
	log close supp_hes_only_primary
	
	translate "$Logdir\4_supplement\supp_hes only primary.smcl" "$Logdir\4_supplement\supp_hes only primary.pdf", replace
	
	erase "$Logdir\4_supplement\supp_hes only primary.smcl"

********************************************************************************
