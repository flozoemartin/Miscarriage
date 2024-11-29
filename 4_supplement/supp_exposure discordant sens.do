
********************************************************************************

* Supplementary analysis exploring results for the exposure discordant analysis

* Author: Flo Martin 

* Date: 25/09/2024

********************************************************************************

* Supplementary table for the sensitivity analysis of the exposure discordant pregnancy analysis: stratifying on groups where first pregnancies were exposed compared to subsequent pregnancies then when subsequent pregnancies in the group are exposed

********************************************************************************

* Start logging

	log using "$Logdir\4_supplement\supp_exposure discordant sens", name(supp_exposure_discordant_sens) replace
	
********************************************************************************

	* Set up the table elements
	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_exposure discordant sens.txt", write replace
	file write `myhandle' "" _tab "Total" _tab "n/N (%)" _tab "Total contributed time (days)" _tab "HR (95%CI)" _tab "aHR (95%CI)" _n
	file write `myhandle' "Primary analyses" _n

********************************************************************************

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
		
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1

	* Drop women with one preg in study period
	duplicates tag patid, gen(dupes)
	ta dupes
	drop if dupes==0 // 563,328 remaining (multiparous)
	count

	* Drop women with same exposure in each pregnancy
	bysort patid: gen diff=1 if cf_unexposed != cf_unexposed[_n-1] & _n!=1
	bysort patid: egen diff_max=max(diff)
	keep if diff_max==1 // 491,397 concordant dropped
	codebook patid 	/*25,286 women*/
	codebook pregid /*71,931 pregnancies*/ 

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
	
	* Generate variable for exposed, then unexp
	bysort patid (pregstart_num): gen first_exposed=1 if cf_unexposed[_n==1]==1
	bysort patid: egen first_exposed_max=max(first_exposed)

	* Generate variable for unexposed, then exposed 
	bysort patid (pregstart_num): gen first_unexp=1 if cf_unexposed[_n==1]==0
	bysort patid: egen first_unexp_max=max(first_unexp)

* If the first pregnancy in the exposure discordant group is exposed
	
	* Create the count macros for the table
	count if first_exposed_max==1
	local n=`r(N)'
	
	* Number of miscarriages in the exposed
	count if _d==1 & cf_unexposed==1 & first_exposed_max==1
	local exp_n=`r(N)'
	
	* Number of exposed
	count if cf_unexposed==1 & first_exposed_max==1
	local exp_total=`r(N)'
	
	* % of miscarriages in the exposed
	local exp_pct=((`exp_n')/(`exp_total'))*100
		
	* Total days follow-up in the exposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==1 & first_exposed_max==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}
	
	* Number of miscarriages in the unexposed
	count if _d==1 & cf_unexposed==0 & first_exposed_max==1
	local unexp_n=`r(N)'
	
	* Number of unexposed
	count if cf_unexposed==0 & first_exposed_max==1
	local unexp_total=`r(N)'
	
	* % of miscarriages in the unexposed
	local unexp_pct=((`unexp_n')/(`unexp_total'))*100
	
	* Total days follow-up in the unexposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==0 & first_exposed_max==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
	
********************************************************************************
		
		* Add elements to the table
		file write `myhandle' ("Unexposed in T1") _tab %9.0fc (`n') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %16.0fc (`unexp_pY') _tab ("1.00 (ref)") _tab ("1.00 (ref)") _n
		 
		file write `myhandle' ("Exposed in T1 (first pregnancy)") _tab ("") _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %14.0fc (`exp_pY')  

********************************************************************************

	* Unadjusted 
	stcox i.cf_unexposed if first_exposed_max==1, vce(cluster patid) strata(patid) 
			
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
	stcox i.cf_unexposed matage matage_sq i.preg_yr_gp i.smokstatus i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety if first_exposed_max==1, vce(cluster patid) strata(patid) 

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

* If the subsequent pregnancy (not the first) in the exposure discordant group is exposed

* Create the count macros for the table
	count if first_unexp_max==1
	local n=`r(N)' 
	
	* Number of miscarriages in the exposed
	count if _d==1 & cf_unexposed==1 & first_unexp_max==1
	local exp_n=`r(N)'
	
	* Number of exposed
	count if cf_unexposed==1 & first_unexp_max==1
	local exp_total=`r(N)'
	
	* % of miscarriages in the exposed
	local exp_pct=((`exp_n')/(`exp_total'))*100
		
	* Total days follow-up in the exposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==1 & first_unexp_max==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}
	
	* Number of miscarriages in the unexposed
	count if _d==1 & cf_unexposed==0 & first_unexp_max==1
	local unexp_n=`r(N)'
	
	* Number of unexposed
	count if cf_unexposed==0 & first_unexp_max==1
	local unexp_total=`r(N)'
	
	* % of miscarriages in the unexposed
	local unexp_pct=((`unexp_n')/(`unexp_total'))*100
	
	* Total days follow-up in the unexposed
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==0 & first_unexp_max==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
	
********************************************************************************
		
		* Add elements to the table
		file write `myhandle' ("Unexposed in T1") _tab %9.0fc (`n') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %16.0fc (`unexp_pY') _tab ("1.00 (ref)") _tab ("1.00 (ref)") _n
		 
		file write `myhandle' ("Exposed in T1 (subsequent pregnancy)") _tab ("") _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %14.0fc (`exp_pY')  

********************************************************************************

	* Unadjusted 
	stcox i.cf_unexposed if first_unexp_max==1, vce(cluster patid) strata(patid) 
			
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

	* Fully adjusted 
	stcox i.cf_unexposed matage matage_sq i.preg_yr_gp i.smokstatus i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety if first_unexp_max==1, vce(cluster patid) strata(patid) 

	count
	local tot=`e(N)'
	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
	
********************************************************************************
					
		* Add the elements to the table
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
		
		file close `myhandle'
		
********************************************************************************

* FIGURE DATA

	* Prepare the table elements
	tempname myhandle	
	file open `myhandle' using "$Graphdir\discordant supp results fig data.txt", write replace
	file write `myhandle' "outcome" _tab "model" _tab "misc" _tab "total" _tab "pct" _tab "unadj_or" _tab "unadj_lci" _tab "unadj_uci" _tab "or" _tab "lci" _tab "uci" _n
	
	foreach var in first_exposed_max first_unexp_max {

		forvalues level=0/1 {
		
			* Create counts for the table
			count if _d==1 & cf_unexposed==`level' & `var'==1
			local n_`level'=`r(N)'
					
			count if cf_unexposed==`level' & `var'==1
			local total_`level'=`r(N)'
					
			local pct_`level'=((`n_`level'')/(`total_`level''))*100
			
			stcox i.cf_unexposed if `var'==1, vce(cluster patid) strata(patid)
			
			lincom _b[`level'.cf_unexposed], hr
			local minunadjhr=`r(estimate)'
			local minunadjuci=`r(ub)'
			local minunadjlci=`r(lb)'
			
			stcox i.cf_unexposed matage matage_sq i.preg_yr_gp i.smokstatus i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety if `var'==1, vce(cluster patid) strata(patid)
			
			lincom _b[`level'.cf_unexposed], hr
			local minadjhr=`r(estimate)'
			local minadjuci=`r(ub)'
			local minadjlci=`r(lb)'
			
			* Add the table elements
			file write `myhandle' "misc" _tab "discordant" _tab (`n_`level'') _tab (`total_`level'') _tab (`pct_`level'') _tab (`minunadjhr') _tab (`minunadjlci') _tab (`minunadjuci') _tab (`minadjhr') _tab (`minadjlci') _tab (`minadjuci') _n
			
		}
		
	}
		
********************************************************************************

* Stop logging
		
	log close supp_exposure_discordant_sens
	
	translate "$Logdir\4_supplement\supp_exposure discordant sens.smcl" "$Logdir\4_supplement\supp_exposure discordant sens.pdf", replace
	
	erase "$Logdir\4_supplement\supp_exposure discordant sens.smcl"

********************************************************************************
