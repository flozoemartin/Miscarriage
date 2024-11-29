********************************************************************************

* Supplementary analysis - pre-pregnancy discontinuation compared to exposed during pregnancy

* Author: Flo Martin 

* Date: 13/06/2024

********************************************************************************

* Supplementary table pre-pregnancy discontinuation - negative-control type analysis

********************************************************************************

* Start logging 

	log using "$Logdir\4_supplement\supp_negative control", name(supp_negative_control) replace
	
********************************************************************************

	* Prepare the table elements
	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_negative control.txt", write replace
	file write `myhandle' "" _tab "Total" _tab "Exposed n/N (%)" _tab "Total exposed time (days)" _tab "Unexposed n/N (%)" _tab "Total unexposed time (days)" _tab "HR" _tab "aHR" _n
	
********************************************************************************

* Primary analysis

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
			
	tab cf_discont
	
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa!=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
			
	* Multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date (day 0)
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
	
	* No need to stsplit because they're all using before preg
			
	/* Split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_discont=0 if exposure_up==-1*/
			
	* Counts for the table
	count if cf_discont!=.
	local n=`r(N)' 
			
	count if _d==1 & cf_discont==1
	local exp_n=`r(N)'
			
	count if cf_discont==1
	local exp_denom=`r(N)'
			
	local exp_pct=(`exp_n'/`exp_denom')*100
			
	cap drop total_fup
	egen total_fup=total(_t) if cf_discont==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}

	count if _d==1 & cf_discont==0
	local unexp_n=`r(N)'
			
	count if cf_discont==0
	local unexp_denom=`r(N)'
			
	local unexp_pct=(`unexp_n'/`unexp_denom')*100
			
	cap drop total_fup
	egen total_fup=total(_t) if cf_discont==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
			
********************************************************************************
		
		* Add the table elements
		file write `myhandle' "Prevalent antidepressant use in T1 compared to discontinuation in the 3 months prior to pregnancy" _tab %7.0fc (`n') _tab %7.0fc (`exp_n') ("/") %7.0fc (`exp_denom') (" (") %4.2f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %7.0fc (`unexp_n') ("/") %7.0fc (`unexp_denom') (" (") %4.2f (`unexp_pct') (")") _tab %10.0fc (`unexp_pY') 

********************************************************************************

	* Unadjusted 
	stcox i.cf_discont, vce(cluster patid)

	lincom _b[1.cf_discont], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
	
********************************************************************************

		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 

********************************************************************************

	* Fully-adjusted
	stcox i.cf_discont matage i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, vce(cluster patid)

	lincom _b[1.cf_discont], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
		
********************************************************************************

		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
			
********************************************************************************	
	
* Stop logging
		
	log close supp_negative_control
	
	translate "$Logdir\4_supplement\supp_negative control.smcl" "$Logdir\4_supplement\supp_negative control.pdf", replace
	
	erase "$Logdir\4_supplement\supp_negative control.smcl"

********************************************************************************
