********************************************************************************

* Supplementary table giving counts of each outcome in the eligible sample

* Author: Flo Martin 

* Date started: 13/06/2024

********************************************************************************

* Supplementary table giving counts of each outcome

********************************************************************************

* Start logging 

	log using "$Logdir\4_supplement\supp_outcome distribution", name(supp_outcome_distribution) replace
	
********************************************************************************

* Prepare the table elements
	
	tempname myhandle	
	file open `myhandle' using "$Tabledir\supp_outcome dist.txt", write replace
	file write `myhandle' "Total (%)" _tab "Exposed (%)" _tab "Unexposed (%)" _n
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	count
	local total = `r(N)'
	
	forvalues y=0/1 {
	
		count if cf_unexposed==`y'
		local total_`y' = `r(N)'
		
	}
	
	file write `myhandle' %9.0fc (`total') (" (100)") _tab %7.0fc (`total_1') (" (100)") _tab %7.0fc (`total_0') (" (100)") _n
	
	forvalues x=1/12 {
		
		count if outcome==`x'
		local n = `r(N)'
		
		count
		local total = `r(N)'
		
		local pct = ((`n')/(`total'))*100 
		
		forvalues y=0/1 {
			
			count if outcome==`x' & cf_unexposed==`y'
			local n_`y' = `r(N)'
			
			count if cf_unexposed==`y'
			local total_`y' = `r(N)'
			
			local pct_`y' = ((`n_`y'')/(`total_`y''))*100 
			
		}
		
		file write `myhandle' %7.0fc (`n') (" (") %4.2fc (`pct') (")") _tab %7.0fc (`n_1') (" (") %4.2fc (`pct_1') (")") _tab %7.0fc (`n_0') (" (") %4.2fc (`pct_0') (")") _n
		
	}

********************************************************************************	
	
* Stop logging
		
	log close supp_outcome_distribution
	
	translate "$Logdir\4_supplement\supp_outcome distribution.smcl" "$Logdir\4_supplement\supp_outcome distribution.pdf", replace
	
	erase "$Logdir\4_supplement\supp_outcome distribution.smcl"

********************************************************************************
