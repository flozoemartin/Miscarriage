********************************************************************************

* Creating supplementary characteristics table for pregnancy outcomes paper - characteristics of incident and prevalent users of antidepressants in trimester one

* Author: Flo Martin 

* Date: 13/06/2024

********************************************************************************

* Supplementary table 2 in pregnancy outcomes paper is created by this script

********************************************************************************

* Start logging 

	log using "$Logdir\4_supplement\supp_prev incid characteristics", name(supp_prev_incid_characteristics) replace
	
********************************************************************************

	* Generic code to output one row of table
	cap prog drop generaterow

	program define generaterow
		
		syntax, variable(varname) condition(string) outcome(string)
	
		* Put the varname and condition to left so that alignment can be checked vs shell
		file write tablecontent "" _tab
		
		cou
		local overalldenom=r(N)
		
		cou if `variable' `condition'
		local rowdenom = r(N)
		local colpct = 100*(r(N)/`overalldenom')
		file write tablecontent %11.0fc (`rowdenom') (" (") %4.1f (`colpct') (")") _tab

		cou if cf_prev_incid==2
		local coldenom = r(N)
		cou if cf_prev_incid==2 & `variable' `condition'
		local pct = 100*(r(N)/`coldenom')
		file write tablecontent %11.0fc (r(N)) (" (") %4.1f (`pct') (")") _tab
		
		cou if cf_prev_incid==1 
		local coldenom = r(N)
		cou if cf_prev_incid==1 & `variable' `condition'
		local pct = 100*(r(N)/`coldenom')
		file write tablecontent %11.0fc (r(N)) (" (") %4.1f (`pct') (")") _tab

		cou if cf_prev_incid==0 
		local coldenom = r(N)
		cou if cf_prev_incid==0 & `variable' `condition'
		local pct = 100*(r(N)/`coldenom')
		file write tablecontent %11.0fc (r(N)) (" (") %4.1f (`pct') (")") _n
	
	end


********************************************************************************

* Generic code to output one section (varible) within table (calls above)

	cap prog drop tabulatevariable
	prog define tabulatevariable
		
		syntax, variable(varname) start(real) end(real) [missing] outcome(string)

		foreach varlevel of numlist `start'/`end'{ 
		
			generaterow, variable(`variable') condition("==`varlevel'") outcome(cf_prev_incid)
	
		}
	
		if "`missing'"!="" generaterow, variable(`variable') condition(">=.") outcome(cf_prev_incid)

	end

********************************************************************************

* Set up output file

		use "$Datadir\primary_analysis_dataset_updated.dta", clear
		
		recode eth5 .=9
		recode bmi_cat .=9
		recode smokstatus .=9

*********************************************************************************
* 2 - Prepare formats for data for output
*********************************************************************************

		cap file close tablecontent
		file open tablecontent using "$Tabledir\supp_prev incid characteristics.txt", write text replace

		file write tablecontent "Variable" _tab "All" _tab "Incident, exposed in T1" _tab "Prevalent, exposed in T1" _tab "Unexposed in T1" _n
		
		gen byte total=1
		tabulatevariable, variable(total) start(1) end(1) outcome(cf_prev_incid)
		
*********************************************************************************

* Maternal age
	
		file write tablecontent "Maternal age at start of pregnancy" _n
		
		file write tablecontent "<18" 
		tabulatevariable, variable(matage_cat) start(1) end(1) outcome(cf_prev_incid) 
		
		file write tablecontent "18-24" 
		tabulatevariable, variable(matage_cat) start(2) end(2) outcome(cf_prev_incid)
		
		file write tablecontent "25-29" 
		tabulatevariable, variable(matage_cat) start(3) end(3) outcome(cf_prev_incid) 
		
		file write tablecontent "30-34" 
		tabulatevariable, variable(matage_cat) start(4) end(4) outcome(cf_prev_incid)
		
		file write tablecontent ">=35" 
		tabulatevariable, variable(matage_cat) start(5) end(5) outcome(cf_prev_incid)
		
*********************************************************************************

* Year of pregnancy
		
		file write tablecontent "Year of pregnancy" _n

		file write tablecontent "1996-2000" 
		tabulatevariable, variable(preg_yr_gp) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "2001-2005" 
		tabulatevariable, variable(preg_yr_gp) start(2) end(2) outcome(cf_prev_incid) 
		
		file write tablecontent "2006-2010" 
		tabulatevariable, variable(preg_yr_gp) start(3) end(3) outcome(cf_prev_incid)
		
		file write tablecontent "2011-2015" 
		tabulatevariable, variable(preg_yr_gp) start(4) end(4) outcome(cf_prev_incid) 
		
		file write tablecontent "2016-2018" 
		tabulatevariable, variable(preg_yr_gp) start(5) end(5) outcome(cf_prev_incid) 

*********************************************************************************

* Practice index of multiple deprivation
		
		file write tablecontent "Practice IMD (in quintiles)" _n

		file write tablecontent "1" 
		tabulatevariable, variable(imd_practice) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "2" 
		tabulatevariable, variable(imd_practice) start(2) end(2) outcome(cf_prev_incid)
		
		file write tablecontent "3" 
		tabulatevariable, variable(imd_practice) start(3) end(3) outcome(cf_prev_incid)
		
		file write tablecontent "4" 
		tabulatevariable, variable(imd_practice) start(4) end(4) outcome(cf_prev_incid)
		
		file write tablecontent "5" 
		tabulatevariable, variable(imd_practice) start(5) end(5) outcome(cf_prev_incid)

*********************************************************************************

* Maternal ethnicity		
		
		file write tablecontent "Maternal ethnicity" _n

		file write tablecontent "White" 
		tabulatevariable, variable(eth5) start(0) end(0) outcome(cf_prev_incid)
		
		file write tablecontent "South Asian" 
		tabulatevariable, variable(eth5) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "Black" 
		tabulatevariable, variable(eth5) start(2) end(2) outcome(cf_prev_incid)
		
		file write tablecontent "Other" 
		tabulatevariable, variable(eth5) start(3) end(3) outcome(cf_prev_incid)
		
		file write tablecontent "Mixed" 
		tabulatevariable, variable(eth5) start(4) end(4) outcome(cf_prev_incid)
		
		file write tablecontent "Missing" 
		tabulatevariable, variable(eth5) start(9) end(9) outcome(cf_prev_incid)
		
*********************************************************************************

* Maternal body mass index
		
		file write tablecontent "Maternal body mass index (BMI)" _n

		file write tablecontent "Underweight (<18.5 kg/m^2)" 
		tabulatevariable, variable(bmi_cat) start(0) end(0) outcome(cf_prev_incid)
		
		file write tablecontent "Healthy weight (18.5-24.9 kg/m^2)" 
		tabulatevariable, variable(bmi_cat) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "Overweight (25.0-29.9 kg/m^2)" 
		tabulatevariable, variable(bmi_cat) start(2) end(2) outcome(cf_prev_incid)
		
		file write tablecontent "Obese (>=30.0 kg/m^2)" 
		tabulatevariable, variable(bmi_cat) start(3) end(3) outcome(cf_prev_incid)
		
		file write tablecontent "Missing" 
		tabulatevariable, variable(bmi_cat) start(9) end(9) outcome(cf_prev_incid)
		
*********************************************************************************

* Gravidity history
		
		file write tablecontent "Maternal history of miscarriage" _n

		file write tablecontent "Yes" 
		tabulatevariable, variable(grav_hist_sa) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "Maternal history of stillbirth" _n

		file write tablecontent "Yes" 
		tabulatevariable, variable(grav_hist_sb) start(1) end(1) outcome(cf_prev_incid)
		
*********************************************************************************

* Parity

		file write tablecontent "Maternal parity at the start of pregnancy" _n
		
		file write tablecontent "0"
		tabulatevariable, variable(parity_cat) start(0) end(0) outcome(cf_prev_incid)
		
		file write tablecontent "1"
		tabulatevariable, variable(parity_cat) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "2"
		tabulatevariable, variable(parity_cat) start(2) end(2) outcome(cf_prev_incid)
		
		file write tablecontent ">=3"
		tabulatevariable, variable(parity_cat) start(3) end(3) outcome(cf_prev_incid)
		
*********************************************************************************

* Maternal indications for antidepressants
		
		file write tablecontent "Maternal indications for antidepressants ever before pregnancy" _n

		file write tablecontent "Depression" 
		tabulatevariable, variable(depression) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "Anxiety" 
		tabulatevariable, variable(anxiety) start(1) end(1) outcome(cf_prev_incid)
		
		/*file write tablecontent "Other indications" 
		tabulatevariable, variable(other_indic) start(1) end(1) outcome(cf_prev_incid)
		
*********************************************************************************/

* Maternal indications for antidepressants
		
		file write tablecontent "Maternal severe mental illness ever before the start of pregnancy" _n

		file write tablecontent "Yes" 
		tabulatevariable, variable(severe_mental_illness) start(1) end(1) outcome(cf_prev_incid)
		
*********************************************************************************


* Number of CPRD consultations in the 12 months prior to pregnancy
		
		file write tablecontent "Number of consultations in the 12 months before pregnancy" _n
		
		file write tablecontent "0" 
		tabulatevariable, variable(CPRD_consultation_events_cat) start(0) end(0) outcome(cf_prev_incid)
		
		file write tablecontent "1-3" 
		tabulatevariable, variable(CPRD_consultation_events_cat) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "4-10" 
		tabulatevariable, variable(CPRD_consultation_events_cat) start(2) end(2) outcome(cf_prev_incid)
		
		file write tablecontent ">10" 
		tabulatevariable, variable(CPRD_consultation_events_cat) start(3) end(3) outcome(cf_prev_incid)
		
*********************************************************************************

* Smoking around the start of pregnancy

		file write tablecontent "Smoking status around the start of pregnancy" _n
		
		file write tablecontent "Non-smoker" 
		tabulatevariable, variable(smokstatus) start(0) end(0) outcome(cf_prev_incid)
		
		file write tablecontent "Current smoker" 
		tabulatevariable, variable(smokstatus) start(2) end(2) outcome(cf_prev_incid)
		
		file write tablecontent "Ex-smoker" 
		tabulatevariable, variable(smokstatus) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "Missing" 
		tabulatevariable, variable(smokstatus) start(9) end(9) outcome(cf_prev_incid)
		
*********************************************************************************

* Other prescriptions in the 12 months prior to pregnancy

		file write tablecontent "Other prescriptions 12 months before pregnancy" _n
		
		file write tablecontent "Antipsychotics" 
		tabulatevariable, variable(antipsychotics_prepreg) start(1) end(1) outcome(cf_prev_incid)
		
		file write tablecontent "Mood stabilisers" 
		tabulatevariable, variable(moodstabs_prepreg) start(1) end(1) outcome(cf_prev_incid) 
		
		file write tablecontent "Folic acid (5mg)" 
		tabulatevariable, variable(folic_prepreg1) start(1) end(1) outcome(cf_prev_incid)
		
*********************************************************************************

* End of table
		
		file close tablecontent
		
********************************************************************************

* Stop logging
		
	log close supp_prev_incid_characteristics
	
	translate "$Logdir\4_supplement\supp_prev incid characteristics.smcl" "$Logdir\4_supplement\supp_prev incid characteristics.pdf", replace
	
	erase "$Logdir\4_supplement\supp_prev incid characteristics.smcl"

********************************************************************************