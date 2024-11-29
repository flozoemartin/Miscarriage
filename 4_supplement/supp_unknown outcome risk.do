********************************************************************************

* Creating supplementary table - risk of having an unknown outcome pregnancy compared exposed to unexposed

* Author: Flo Martin 

* Date: 03/04/20234

********************************************************************************

* Supplemetary table of the risk of unknown outcome following antidepressant use before pregnancy, depression or anxiety in pregnancy outcomes paper is created by this script

********************************************************************************

* Start logging 

	log using "$Logdir\2_analysis\supp_unknown outcome risk", name(supp_unknown_outcome_risk) replace
	
********************************************************************************

	* Prepare the table elements
	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_unknown outcome risk.txt", write replace
	file write `myhandle' "Total" _tab "Exposed/diagnosed n/N (%)" _tab "Unexposed/not diagnosed n/N (%)" _tab "OR" _tab "aOR" _n
	
********************************************************************************

* Unknown outcome
			
	foreach cf_group in any_prepreg depression_12mo anxiety_12mo {
	
		use "$Datadir\primary_analysis_dataset_with_unknown_outcomes.dta", clear
			
		recode uout .=0
		recode any_prepreg .=0
			
		gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & grav_hist_sa!=. & smokstatus!=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
		keep if cc==1
			
		count
		local n=`r(N)'
			
		count if uout==1 & `cf_group'==1
		local exp_n=`r(N)'
					
		count if `cf_group'==1
		local exp_total=`r(N)'
				
		local exp_pct=((`exp_n')/(`exp_total'))*100
					
		count if uout==1 & `cf_group'==0
		local unexp_n=`r(N)'
					
		count if `cf_group'==0
		local unexp_total=`r(N)'
					
		local unexp_pct=((`unexp_n')/(`unexp_total'))*100
			
********************************************************************************
			
			* Add the table elements
			file write `myhandle' %9.0fc (`n') _tab %9.0fc (`exp_n') ("/") %9.0fc (`exp_total') (" (") %4.1f (`exp_pct') (")") _tab %9.0fc (`unexp_n') ("/") %9.0fc  (`unexp_total') (" (") %4.1f (`unexp_pct') (")")

********************************************************************************

		* Unadjusted 
		logistic `cf_group' i.uout, or vce(cluster patid)
				
		lincom 1.uout, or
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
		
********************************************************************************
			
			* Add the table elements
			file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 

********************************************************************************

		* Fully-adjusted 
		logistic `cf_group' i.uout matage i.imd_practice i.preg_yr_gp i.grav_hist_sa i.smokstatus i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg, or vce(cluster patid)

		lincom 1.uout, or
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

	log close supp_unknown_outcome_risk
	
	translate "$Logdir\2_analysis\supp_unknown outcome risk.smcl" "$Logdir\2_analysis\supp_unknown outcome risk.pdf", replace
	
	erase "$Logdir\2_analysis\supp_unknown outcome risk.smcl"
	
********************************************************************************
