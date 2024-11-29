********************************************************************************

* Creating supplementary table for miscarriage paper - more stringent definitions of exposure in the primary and patterns analysis

* Author: Flo Martin 

* Date: 13/06/2024

********************************************************************************

* Supplementary table using a more stringent definition of the exposure (>1 in trimester one) for miscarriage paper is created by this script

********************************************************************************

* Start logging

	log using "$Logdir\4_supplement\supp_more than 1 pxn", name(supp_more_than_1_pxn) replace
	
********************************************************************************
	
	* Prepare the table elements
	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_more than 1 pxn.txt", write replace
	file write `myhandle' "" _tab "Total" _tab "Exposed n/N (%)" _tab "Total exposed time (days)" _tab "Unexposed n/N (%)" _tab "Total unexposed time (days)" _tab "HR" _tab "aHR" _n

********************************************************************************

* Primary analysis - more stringent definitions
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa!=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
			
	* Multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date (day 0)
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
			
	tab cf_unexposed_gt1pxn
	sum cycle_1_start
			
	* Split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_unexposed_gt1pxn=0 if exposure_up==-1
		
	count
	local n=`r(N)'
		
	count if _d==1 & cf_unexposed_gt1pxn==1
	local exp_n=`r(N)'
					
	count if cf_unexposed_gt1pxn==1
	local exp_total=`r(N)'
					
	local exp_pct=((`exp_n')/(`exp_total'))*100
			
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed_gt1pxn==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}
					
	count if misc==1 & cf_unexposed_gt1pxn==0
	local unexp_n=`r(N)'
					
	count if cf_unexposed_gt1pxn==0
	local unexp_total=`r(N)'
					
	local unexp_pct=((`unexp_n')/(`unexp_total'))*100
			
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed_gt1pxn==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
		
********************************************************************************

		* Add the table elements
		file write `myhandle' ("Primary analysis") _tab %9.0fc (`n') _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %12.0fc (`unexp_pY')

********************************************************************************

	* Unadjusted 
	stcox i.cf_unexposed_gt1pxn, vce(cluster patid)
						
	local tot=`e(N_sub)'
	lincom _b[1.cf_unexposed_gt1pxn], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
			
********************************************************************************
		
		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 
		
********************************************************************************

	* Fully-adjusted 
	stcox i.cf_unexposed_gt1pxn matage i.preg_yr_gp i.grav_hist_sa i.smokstatus i.imd_practice i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid)
						
	di `tot'
	local tot=`e(N_sub)'
	lincom _b[1.cf_unexposed_gt1pxn], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
			
********************************************************************************

		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n

********************************************************************************

* Patterns analysis - more stringent definitions
			
	forvalues levels=1/2 {
	
		use "$Datadir\primary_analysis_dataset_updated.dta", clear
		
		* Complete cases
		gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa!=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
		keep if cc==1
			
		* Multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date (day 0)
		stset end_fup, fail(misc) id(pregid) enter(start_date) 
			
		tab cf_prev_incid_gt1pxn
		sum cycle_1_start
			
		* Split at designated times i.e. after the date of intiation for first trimester initators
		stsplit exposure_updated, after(cycle_1_start) at(0)
		tab exposure_up, miss
		replace cf_prev_incid_gt1pxn=0 if exposure_up==-1
		
		count if cf_prev_incid_gt1pxn!=.
		local n=`r(N)'
		
		count if _d==1 & cf_prev_incid_gt1pxn==`levels'
		local exp_n=`r(N)'
					
		count if cf_prev_incid_gt1pxn==`levels'
		local exp_total=`r(N)'
					
		local exp_pct=((`exp_n')/(`exp_total'))*100
			
		cap drop total_fup
		egen total_fup=total(_t) if cf_prev_incid_gt1pxn==`levels'
		sum total_fup
				
		if `r(N)'!=. {
			
			local exp_pY=`r(mean)'
						
		}
					
		count if _d==1 & cf_prev_incid_gt1pxn==0
		local unexp_n=`r(N)'
					
		count if cf_prev_incid_gt1pxn==0
		local unexp_total=`r(N)'
					
		local unexp_pct=((`unexp_n')/(`unexp_total'))*100
			
		cap drop total_fup
		egen total_fup=total(_t) if cf_prev_incid_gt1pxn==0
		sum total_fup
				
		if `r(N)'!=. {
			
			local unexp_pY=`r(mean)'
						
		}
		
********************************************************************************

			* Add the table elements
			file write `myhandle' ("Stringent pattern") _tab %9.0fc (`n') _tab %6.0fc (`exp_n') ("/") %6.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")") _tab %12.0fc (`unexp_pY')	

********************************************************************************

		* Unadjusted 
		stcox i.cf_prev_incid_gt1pxn, vce(cluster patid)
				
		local tot=`e(N_sub)'
		lincom _b[`levels'.cf_prev_incid_gt1pxn], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
	
********************************************************************************
					
			* Add the table elements
			file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 

********************************************************************************

		* Fully-adjusted 
		stcox i.cf_prev_incid_gt1pxn matage i.preg_yr_gp i.grav_hist_sa i.smokstatus i.imd_practice i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid)

		lincom _b[`levels'.cf_prev_incid_gt1pxn], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
		
********************************************************************************
					
			* Add the table elements
			file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
			
********************************************************************************
		
		}

********************************************************************************

* Stop logging
		
	log close supp_more_than_1_pxn
	
	translate "$Logdir\4_supplement\supp_more than 1 pxn.smcl" "$Logdir\4_supplement\supp_more than 1 pxn.pdf", replace
	
	erase "$Logdir\4_supplement\supp_more than 1 pxn.smcl"

********************************************************************************
