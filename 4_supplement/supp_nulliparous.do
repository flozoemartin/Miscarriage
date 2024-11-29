********************************************************************************

* Supplementary analysis restricted to first pregnancies

* Author: Flo Martin 

* Date: 13/06/2024

********************************************************************************

* Supplementary table restricted to first pregnancies

********************************************************************************

* Start logging 

	log using "$Logdir\4_supplement\supp_nulliparous", name(supp_nulliparous) replace
	
********************************************************************************

	* Prepare the table elements
	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_nulliparous.txt", write replace
	file write `myhandle' "" _tab "Total" _tab "Exposed n/N (%)" _tab "Total exposed time (days)" _tab "Unexposed n/N (%)" _tab "Total unexposed time (days)" _tab "HR" _tab "aHR" _n
	
********************************************************************************

* Primary analysis

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
			
	keep if parity==0
	
	* Complete cases
	gen cc = 1 if matage!=. & imd_practice!=. & smokstatus!=. & severe_mental_illness!=. & preg_yr_gp!=. & grav_hist_sa!=. & bmi_cat!=. & parity_cat!=. & folic_prepreg1!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=.
	keep if cc==1
			
	* Multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date (day 0)
	stset end_fup, fail(misc) id(pregid) enter(start_date) 
			
	tab cf_unexposed
	sum cycle_1_start
			
	* Split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_unexposed=0 if exposure_up==-1
			
	* Counts for the table
	count
	local n=`r(N)'
			
	count if _d==1 & cf_unexposed==1
	local exp_n=`r(N)'
			
	count if cf_unexposed==1
	local exp_denom=`r(N)'
			
	local exp_pct=(`exp_n'/`exp_denom')*100
			
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==1
	sum total_fup
				
	if `r(N)'!=. {
			
		local exp_pY=`r(mean)'
						
	}

	count if _d==1 & cf_unexposed==0
	local unexp_n=`r(N)'
			
	count if cf_unexposed==0
	local unexp_denom=`r(N)'
			
	local unexp_pct=(`unexp_n'/`unexp_denom')*100
			
	cap drop total_fup
	egen total_fup=total(_t) if cf_unexposed==0
	sum total_fup
				
	if `r(N)'!=. {
			
		local unexp_pY=`r(mean)'
						
	}
			
********************************************************************************
		
		* Add the table elements
		file write `myhandle' "Restricted by nulliparous" _tab %7.0fc (`n') _tab %7.0fc (`exp_n') ("/") %7.0fc (`exp_denom') (" (") %4.2f (`exp_pct') (")") _tab %9.0fc (`exp_pY') _tab %7.0fc (`unexp_n') ("/") %7.0fc (`unexp_denom') (" (") %4.2f (`unexp_pct') (")") _tab %10.0fc (`unexp_pY') 

********************************************************************************

	* Unadjusted 
	stcox i.cf_unexposed, vce(cluster patid)

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

	lincom _b[1.cf_unexposed], hr
	local minadjhr=`r(estimate)'
	local minadjuci=`r(ub)'
	local minadjlci=`r(lb)'
		
********************************************************************************

		* Add the table elements
		file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
			
********************************************************************************	
	
* Stop logging
		
	log close supp_nulliparous
	
	translate "$Logdir\4_supplement\supp_nulliparous.smcl" "$Logdir\4_supplement\supp_nulliparous.pdf", replace
	
	erase "$Logdir\4_supplement\supp_nulliparous.smcl"

********************************************************************************
