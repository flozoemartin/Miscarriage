
********************************************************************************

* Creating supplementary active indication sample table

* Author: Flo Martin 

* Date: 13/06/2024

********************************************************************************

* Supplementary table restricting to those with depression or anxiety in the 12 months prior to pregnancy or severe depression noted in the 12 months prior to pregnancy

********************************************************************************

* Start logging 

	log using "$Logdir\4_supplement\supp_active indic", name(supp_active_indic) replace
	
********************************************************************************

	* Prepare the table elements

	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_active indic.txt", write replace
	
	file write `myhandle' "" _tab "Total" _tab "Exposed n/N (%)" _tab "Total exposed time (days)" _tab "Unexposed n/N (%)" _tab "Total unexposed time (days)" _tab "HR (95%CI)" _tab "aHR (95%CI)" _n
	
********************************************************************************

* Miscarriage risk among those with a depression- or anxiety-related code in the 12 months prior to pregnancy
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
			
	keep if depression_12mo==1 | anxiety_12mo==1
	
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
			
	* Multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date (day 0)
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
			
	tab cf_unexposed
	sum cycle_1_start
			
	* Split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_unexposed=0 if exposure_up==-1
			
	* Create the count macros for the table
	count
	local n=`r(N)'
	
	* Number of miscarriages among the exposed
	count if _d==1 & cf_unexposed==1
	local exp_n=`r(N)'
		
	* Number of exposed
	count if cf_unexposed==1
	local exp_denom=`r(N)'
	
	* % of miscarriages in the exposed
	local exp_pct=(`exp_n'/`exp_denom')*100
	
	* Number of days follow-up
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}

	* Number of miscarriages among the unexposed
	count if _d==1 & cf_unexposed==0
	local unexp_n=`r(N)'
		
	* Number of unexposed
	count if cf_unexposed==0
	local unexp_denom=`r(N)'
	
	* % of miscarriages in the unexposed
	local unexp_pct=(`unexp_n'/`unexp_denom')*100
	
	* Number of days follow-up
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
		
********************************************************************************

		* Add the table elements	
		file write `myhandle' "Miscarriage among those with depression in the 12 months before pregnancy" _tab %7.0fc (`n') _tab %7.0fc (`exp_n') ("/") %7.0fc (`exp_denom') (" (") %4.2f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %7.0fc (`unexp_n') ("/") %7.0fc (`unexp_denom') (" (") %4.2f (`unexp_pct') (")") _tab %9.0fc (`unexp_pY') 
		
********************************************************************************
							
	* Unadjusted 
	stcox i.cf_unexposed, vce(cluster patid)
				
	lincom _b[1.cf_unexposed], rrr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
		
********************************************************************************
		
		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 
		
********************************************************************************

		* Fully-adjusted
		stcox i.cf_unexposed matage i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat, vce(cluster patid)
				
		lincom _b[1.cf_unexposed], rrr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
			
********************************************************************************
			
		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
					
********************************************************************************

* Pattern analysis among those with depression or anxiety in the 12 months before pregnancy

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
		
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	
	keep if depression_12mo==1 | anxiety_12mo==1
			
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
	
********************************************************************************	

	* Add table elements
	file write `myhandle' "Pattern analysis" _n
	
********************************************************************************	

	* Create count macros for the table
	foreach level in 0 1 2 {
				
		count if  _d==1  & cf_prev_incid==`level'
		local n=`r(N)'
		cap drop total_fup
		egen total_fup=total(_t) if cf_prev_incid==`level'
		sum total_fup
				
		if `r(N)'!=. {
			
			local pY=`r(mean)'
						
		}
				
		cap drop littlen
		gen littlen=_n
		cap drop total_pregs
		count if  cf_prev_incid==`level'
		local pregs=`r(N)'
		local rate_100=(`n'/`pY')*100
		local percent=(`n'/`pregs')*100
		
		count
		local tot=`r(N)'
		
********************************************************************************	

		* Add the table elements
		if `level'==0 {
				
			file write `myhandle' "Unexposed in T1 among actively indicated" _tab %7.0fc (`tot') _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %16.0fc (`pY')
					
		}
				
		if `level'==1 {
				    
			file write `myhandle' "Prevalent, exposed in T1 among actively indicated" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
					
		}
		
		else if `level'==2 {
				
			file write `myhandle' "Incident, exposed in T1 among actively indicated" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
					
		}

********************************************************************************	

		* Unadjusted 
		stcox i.cf_prev_incid, vce(cluster patid)
				
		local tot=`e(N_sub)'
		lincom _b[`level'.cf_prev_incid], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
		
********************************************************************************	

		* Add the table elements
		if `minadjhr'==1 {
					
			file write `myhandle' _tab ("1.00 (ref)") 
					
		}
				
		else if `minadjhr'!=1 {
					
			file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 
					
		}

********************************************************************************	

		* Fully-adjusted
		stcox i.cf_prev_incid matage i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat, vce(cluster patid)
				
		di `tot'
		local tot=`e(N_sub)'
		lincom _b[`level'.cf_prev_incid], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
		
********************************************************************************	

		* Add the table elements
		if `minadjhr'==1 {
					
			file write `myhandle' _tab ("1.00 (ref)") _n
					
		}
				
		else if `minadjhr'!=1 {
					
			file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
					
		}

********************************************************************************	

	}	
	
********************************************************************************
					
* Miscarriage risk among those with severe depression noted in the 12 months prior to pregnancy
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
			
	keep if any_preg_severe!=.
	
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
			
	* Multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date (day 0)
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
			
	tab any_preg_severe
	sum cycle_1_start
			
	* Split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace any_preg_severe=0 if exposure_up==-1
			
	* Create the count macros for the table
	count
	local n=`r(N)'
			
	count if _d==1 & any_preg_severe==1
	local exp_n=`r(N)'
			
	count if any_preg_severe==1
	local exp_denom=`r(N)'
			
	local exp_pct=(`exp_n'/`exp_denom')*100
			
	cap drop total_fup
	egen total_fup=total(_t) if any_preg_severe==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}

	count if _d==1 & any_preg_severe==0
	local unexp_n=`r(N)'
			
	count if any_preg_severe==0
	local unexp_denom=`r(N)'
			
	local unexp_pct=(`unexp_n'/`unexp_denom')*100
			
	cap drop total_fup
	egen total_fup=total(_t) if any_preg_severe==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
			
********************************************************************************

		* Add the table elements
		file write `myhandle' "Miscarriage among those with severe depression in the 12 months before pregnancy" _tab %7.0fc (`n') _tab %7.0fc (`exp_n') ("/") %7.0fc (`exp_denom') (" (") %4.2f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %7.0fc (`unexp_n') ("/") %7.0fc (`unexp_denom') (" (") %4.2f (`unexp_pct') (")") _tab %9.0fc (`unexp_pY') 

********************************************************************************
							
	* Unadjusted 
	stcox i.any_preg_severe, vce(cluster patid)
				
	lincom _b[1.any_preg_severe], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
					
********************************************************************************

		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 

********************************************************************************

	* Fully-adjusted
	stcox i.any_preg_severe matage i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat, vce(cluster patid)
				
	lincom _b[1.any_preg_severe], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
	
********************************************************************************

		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
		
********************************************************************************	
	
* Stop logging

	log close supp_active_indic
	
	translate "$Logdir\4_supplement\supp_active indic.smcl" "$Logdir\4_supplement\supp_active indic.pdf", replace
	
	erase "$Logdir\4_supplement\supp_active indic.smcl"
	
********************************************************************************
