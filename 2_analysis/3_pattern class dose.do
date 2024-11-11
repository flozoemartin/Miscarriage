********************************************************************************

* Creating table 3 for miscarriage paper - pattener analysis, class analysis and dose analysis

* Author: Flo Martin 

* Date started: 07/10/2023

********************************************************************************

* Table 3 in miscarriage paper is created by this script

********************************************************************************

* Start logging

	log using "$Logdir\2_analysis\3_pattern class dose", name(pattern_class_dose) replace
	
********************************************************************************

* Prepare the table elements

	tempname myhandle	
	file open `myhandle' using "$Tabledir\pattern class dose.txt", write replace
	file write `myhandle' "" _tab "Total" _tab "n/N (%)" _tab "Total exposed time (in days)" _tab "HR (95% CI)" _tab "aHR (95% CI)" _n
	file write `myhandle' "Secondary analyses" _n
	
********************************************************************************	

* Pattern analysis

	file write `myhandle' "Pattern analysis" _n
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear
	
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	
	gen matage_sq = matage*matage
			
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
	
	count
	local total = `r(N)'

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
		
********************************************************************************	

		* Add the table elements
		if `level'==0 {
				
			file write `myhandle' "Unexposed in T1" _tab %7.0fc (`total') _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %16.0fc (`pY')
					
		}
				
		if `level'==1 {
				    
			file write `myhandle' "Prevalent, exposed in T1" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
					
		}
		
		else if `level'==2 {
				
			file write `myhandle' "Incident, exposed in T1" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
					
		}

********************************************************************************	

		* Unadjusted 
		stcox i.cf_prev_incid, vce(cluster patid)
		
		count
		local tot=`e(N)'
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
		stcox i.cf_prev_incid matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid)
			
		count
		local tot=`e(N)'
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

	file write `myhandle' "Class analysis" _n

* Class analysis
	
	use "$Datadir\primary_analysis_dataset_updated.dta", clear

	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	
	tab cf_class
	replace cf_class = 0 if cf_unexposed==0
	tab cf_class
			
	gen cf_class_og=cf_class
	gen matage_sq = matage*matage
			
	* multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date, origin - subject becomes at risk at the pregnancy start date, scale - rescale time value by day?
	stset end_fup, fail(misc) id(pregid) enter(start_date) origin(start_date)
			
	tab cf_class
	sum cycle_1_start
	* split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_class=0 if exposure_up==-1
					
	replace cf_class=5 if exposure_up==0 & cycle_1_start!=.
	tab cf_class exposure_up
					
	recode cf_class 5=1 if cf_class_og==1
	recode cf_class 5=2 if cf_class_og==2
	recode cf_class 5=3 if cf_class_og==3
	recode cf_class 5=4 if cf_class_og==4
	recode cf_class 5=5 if cf_class_og==5
	tab cf_class
	drop cf_class_og
				
	recode misc .=0
					
	tab cf_class
	tab misc
	tab misc cf_class, col chi
			
	file write `myhandle' "Class analysis" _n
	
	count
	local total = `r(N)'
			
	foreach level in 0 1 2 3 4 5 {
			
		count if  misc==1  & cf_class==`level' 
		local n=`r(N)'
		cap drop total_fup
		egen total_fup=total(_t) if cf_class==`level'  
		sum total_fup
			
		if `r(N)'!=. {
			
			local pY=`r(mean)'
			
		}
				
		cap drop littlen
		gen littlen=_n
		cap drop total_pregs
		count if cf_class==`level' 
		local pregs=`r(N)'
		local rate_100=(`n'/`pY')*100
		local percent=(`n'/`pregs')*100

		if `level'==0 {
				
			file write `myhandle' "Unexposed in T1" _tab %7.0fc (`total') _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %16.0fc (`pY')
					
		}
				
		if `level'==1 {
				    
			file write `myhandle' "SSRI exposed in T1" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
					
		}
					
		if `level'==2 {
				    
			file write `myhandle' "SNRI exposed in T1" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")")  _tab %10.0fc (`pY')
					
		}
					
		if `level'==3 {
				    
			file write `myhandle' "TCA exposed in T1" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
					
		}
					
		else if `level'==4 {
				    
			file write `myhandle' "Other exposed in T1" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
					
		}
					
		else if `level'==5 {
				    
			file write `myhandle' "Multiple in T1" _tab "" _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
					
		}

********************************************************************************	

		* Unadjusted 
		stcox i.cf_class, vce(cluster patid) 

		count
		local tot=`e(N)'
		lincom _b[`level'.cf_class], hr
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
		stcox i.cf_class matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid)
			
		count
		local tot=`e(N)'
		lincom _b[`level'.cf_class], hr
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

	file write `myhandle' "Dose analysis" _n

* Dose analysis

	use "$Datadir\primary_analysis_dataset_updated.dta", clear
		
	* Complete cases
	gen cc = 1 if matage!=. & preg_year!=. & imd_practice!=. & smokstatus!=. & grav_hist_sa !=. & parity_cat!=. & folic_prepreg1!=. & CPRD_consultation_events_cat!=. & antipsychotics_prepreg!=. & moodstabs_prepreg!=. & depression!=. & anxiety!=.
	keep if cc==1
	
	gen matage_sq = matage*matage
	
	recode cf_dose .=0
	tab cf_dose
			
	gen cf_dose_og=cf_dose
			
	* multiple-record-per-subject survival data - censored if follow ends or failure event if experience the event, id variable pregnancy ID, enter - subject first enters the study at the pregnancy start date, origin - subject becomes at risk at the pregnancy start date, scale - rescale time value by day?
	stset end_fup, fail(misc) id(pregid) enter(start_date) origin(start_date)
			
	tab cf_dose
	sum cycle_1_start
	* split at designated times i.e. after the date of intiation for first trimester initators
	stsplit exposure_updated, after(cycle_1_start) at(0)
	tab exposure_up, miss
	replace cf_dose=0 if exposure_up==-1
					
	replace cf_dose=3 if exposure_up==0 & cycle_1_start!=.
	tab cf_dose exposure_up
					
	recode cf_dose 3=1 if cf_dose_og==1
	recode cf_dose 3=2 if cf_dose_og==2
	recode cf_dose 3=3 if cf_dose_og==3
	tab cf_dose
	drop cf_dose_og

	recode misc .=0
	
	count
	local total = `r(N)'
			
	levelsof cf_dose, local(explevel)
			
	file write `myhandle' "Dose analysis" _n
			
	foreach level of local explevel {
			
		count if  misc==1  & cf_dose==`level' 
		local n=`r(N)'
		cap drop total_fup
		egen total_fup=total(_t) if cf_dose==`level'  
		sum total_fup
			
		if `r(N)'!=. {
			
			local pY=`r(mean)'
					
		}
				
		cap drop littlen
		gen littlen=_n
		cap drop total_pregs
		count if  cf_dose==`level' 
		local pregs=`r(N)'
		local rate_100=(`n'/`pY')*100
		local percent=(`n'/`pregs')*100
		
********************************************************************************	

		* Add the table elements
		if `level'==0 {
					
			file write `myhandle' "Unexposed in T1" _tab %7.0fc (`total') _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
							
		}
		
		if `level'==1 {
					
			file write `myhandle' "Low dose" _tab ("") _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
							
		}
				
		if `level'==2 {
					
			file write `myhandle' "Medium dose" _tab ("") _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
							
		}
				
		else if `level'==3 {
					
			file write `myhandle' "High dose" _tab ("") _tab %7.0fc (`n') ("/") %7.0fc (`pregs') (" (") %4.1f (`percent') (")") _tab %10.0fc (`pY')
							
		}

********************************************************************************	

		* Unadjusted 
		stcox i.cf_dose, vce(cluster patid)
		
		count
		local tot=`e(N)'
		lincom _b[`level'.cf_dose], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
			
********************************************************************************	

		* Add the table elements
		if `minadjhr'!=1 {
				
			file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") 
					
		}
				
		else if `minadjhr'==1 {
				
			file write `myhandle' _tab ("1.00 (ref)") 
					
		}
		
********************************************************************************	

		* Fully-adjusted
		stcox i.cf_dose matage matage_sq i.imd_practice i.preg_yr_gp i.smokstatus i.severe_mental_illness i.grav_hist_sa i.parity_cat i.folic_prepreg1 i.antipsychotics_prepreg i.moodstabs_prepreg i.CPRD_consultation_events_cat depression anxiety, vce(cluster patid)
				
		count
		local tot=`e(N)'
		lincom _b[`level'.cf_dose], hr
		local minadjhr=`r(estimate)'
		local minadjuci=`r(ub)'
		local minadjlci=`r(lb)'
			
********************************************************************************	
				
		* Add the table elements
		if `minadjhr'!=1 {
				
			file write `myhandle' _tab %4.2f (`minadjhr') (" (") %4.2f (`minadjlci') ("-") %4.2f (`minadjuci') (")") _n
					
		}
				
		else if `minadjhr'==1 {
				
			file write `myhandle' _tab ("1.00 (ref)") _n
					
		}
		
********************************************************************************	

	}
	
********************************************************************************

* Stop logging
		
	log close pattern_class_dose
	
	translate "$Logdir\2_analysis\3_pattern class dose.smcl" "$Logdir\2_analysis\3_pattern class dose.pdf", replace
	
	erase "$Logdir\2_analysis\3_pattern class dose.smcl"

********************************************************************************
