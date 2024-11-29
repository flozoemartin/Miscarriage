********************************************************************************

* Creating supplementary table for miscarriage paper - investigating the association between missing data in covariates and miscarriage

* Author: Flo Martin 

* Date: 14/06/2024

********************************************************************************

* Supplementary table of regressions assessing the association between missing data in covariates and miscarriage created by this script

********************************************************************************

* Start logging

	log using "$Logdir\4_supplement\supp_missingness regressions", name(supp_missingness_regressions) replace
	
********************************************************************************

* Set up the table elements
	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_missingness regressions.txt", write replace
	file write `myhandle' "Variable" _tab "miscs with missing" _tab "Continuers with missing" _tab "OR (95%CI)" _tab "aOR (95%CI)" _n
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	recode misc .=0 if inlist(outcome, 1,2,3,11,12)
	
	foreach var in eth5 bmi_cat smokstatus {
	
		gen `var'_m = 1 if `var'==.
		replace `var'_m = 0 if `var'!=.
		tab `var'_m, m
		
	}
	
	foreach var in eth5 bmi_cat smokstatus {
		
		count if `var'_m==1 & misc==1
		local n_discont = `r(N)'
		
		count if misc==1
		local total_discont = `r(N)'
		
		local pct_discont = (`n_discont'/`total_discont')*100
		
		count if `var'_m==1 & misc==0
		local n_cont = `r(N)'
		
		count if misc==0
		local total_cont = `r(N)'
		
		local pct_cont = (`n_cont'/`total_cont')*100
		
		file write `myhandle' ("`var'") _tab %7.0fc (`n_discont') ("/") %7.0fc (`total_discont') (" (") %5.2fc (`pct_discont') (")") _tab %7.0fc (`n_cont') ("/") %7.0fc (`total_cont') (" (") %5.2fc (`pct_cont') (")") 
		
		logistic `var'_m i.misc, or vce(cluster patid)
		
		lincom 1.misc, or 
		local minadjor=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
		
		file write `myhandle' _tab %4.2fc (`minadjor') (" (") %4.2fc (`minadjlci') ("-") %4.2fc (`minadjuci') (")")
		
		logistic `var'_m i.misc matage i.preg_yr_gp i.grav_hist_sa i.severe_mental_illness i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat i.depression i.anxiety, or vce(cluster patid)
		
		lincom 1.misc, or 
		local minadjor=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
		
		file write `myhandle' _tab %4.2fc (`minadjor') (" (") %4.2fc (`minadjlci') ("-") %4.2fc (`minadjuci') (")") _n
		
	}
