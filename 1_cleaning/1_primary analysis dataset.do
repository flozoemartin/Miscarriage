*********************************************************************************

* Creating the study dataset for the pregnancy outcomes analyses - miscarriage

* Author: Harriet Forbes (amended by Flo Martin)

* Date: 25/06/2024

*********************************************************************************

* Datasets created by this do-file

*	- $Datadir\primary_analysis_dataset_with_unknown_outcomes.dta
*	- $Datadir\primary_analysis_dataset.dta

*********************************************************************************

* Start logging

	log using "$Logdir\1_cleaning\1_primary analysis dataset", name(primary_analysis_dataset) replace

*********************************************************************************

* Load in the eligible cohort

	use "$Deriveddir\derived_data\pregnancy_cohort_final.dta", clear
	
	* Updated outcome
	drop outcome
	rename updated_outcome outcome
	codebook pregid
	
	tab outcome
	
	gen gestdays_new = pregend_num - pregstart_num
	
	keep patid pregid outcome pregstart_num pregend_num hes_apc_e multiple pregnum_new gestdays_new
	
	count if pregstart_num==pregend_num /*0*/
	
	merge 1:1 patid pregid using "$Patternsdir\patterns_in_pregnancy_long.dta", keep(master match) nogen
	codebook pregid
	
	* Merge on covariate information
	merge 1:1 patid pregid using "$Deriveddir\covariates\pregnancy_cohort_covariates.dta",  keep(match master) nogen
	
	* Indications
	
		* Binary depression from primary care
	merge 1:1 patid pregid using "$Deriveddir\indications\all_depression_read.dta", keep(1 3) nogen
	count
	
		* Binary anxiety from primary care
	merge 1:1 patid pregid using "$Deriveddir\indications\all_anxiety_read.dta", keep(1 3) nogen
	count
	
		* Binary depression from secondary care
	merge 1:1 patid pregid using "$Deriveddir\indications\all_depression_hes.dta", keep(1 3) nogen
	count
	
		* Binary anxiety from secondary care
	merge 1:1 patid pregid using "$Deriveddir\indications\all_anxiety_hes.dta", keep(1 3) nogen
	count
	
		* Binary other AD indications from primary care
	merge 1:1 patid pregid using "$Deriveddir\indications\all_other_indics_read.dta", keep(1 3) nogen
	count
	
		* Binary other AD indications from secondary care
	merge 1:1 patid pregid using "$Deriveddir\indications\all_other_indics_hes.dta", keep(1 3) nogen
	count	

	* Merge on tod, lcd, deathdate_num
	merge m:1 patid using "$Deriveddir\formatted_cprd_data\All_Patient.dta", nogen keep(match) keepusing(tod_num crd_num)
	tostring patid, gen(patid_s) format(%12.0f)
	merge m:1 pracid using "$Deriveddir\formatted_cprd_data\All_Practice.dta", nogen keep(match) keepusing(lcd_num uts_num)
	codebook pregid
	
	* Merge onto scales pre-pregnancy
	merge 1:1 patid pregid using "$Tempdatadir\severity_12mo_preg.dta", keep(1 3) nogen

	count
	
********************************************************************************

* Apply additional exclusions

	tab outcome
	drop if outcome==13 // 211,112
	
	count

	* Multiple pregnancies
	drop if multiple==1 /*6,343 multiple pregnancies*/
	drop if mblbabies>1 & mblbabies!=. // 6,056 - more than one baby linked to the pregnancy in the MBL
		
		* 12,399 multiple births dropped in total
	
	count // 1,021,384 eligible pregnancies
	
*********************************************************************************

* COVARIATES

	* Maternal age

	summ matage		// 10 - 48
	tab matage_cat	
	
	* Maternal BMI
	
	tab bmi_cat, nol
	recode bmi_cat 4=.
	
	* Maternal ethnicity 
	
	tab eth5, nol
	recode eth5 5=. // 32% missing - not include in primary adjustment set?
	
	* IMD
	
	tab imd_practice
	
	* Pregnancy year
	
	gen preg_year=year(pregstart_num)
	egen preg_yr_gp=cut(preg_year), at(1996 2001 2006 2011 2016 2020)
	recode  preg_yr_gp 1996=1 2001=2 2006=3 2011=4 2016=5
	lab define preg_yr_gp 1 "1996-2000" 2 "2001-2005" 3 "2006-2010" 4 "2011-2015" 5 "2016-2018"
	lab val preg_yr_gp preg_yr_gp
	tab preg_year preg_yr_gp
	
	* History of loss
	
	tab grav_hist_sa
	tab grav_hist_sb
	
	gen hist_loss = 1 if grav_hist_sa==1 | grav_hist_sb==1 | grav_hist_otherloss==1 /*Not including terminations*/
	replace hist_loss = 0 if hist_loss!=1
	
	tab hist_loss
	
	* Parity
	
	tab parity_cat
	
	* Folic acid 5mg
	
	tab folic_prepreg1
	
	* Anti-seizure medications
	
	tab moodstabs_prepreg
	
	* Antipsychotics
	
	tab antipsychotics_prepreg
	
	* Smoking
	
	tab smokstatus
	recode smokstatus 3=.
	
	* Teratogen for adjustment in sensitivity
	
	drop teratogen_prepreg
	gen teratogen_prepreg = 1 if prepreg_ace==1 | prepreg_heart==1 | prepreg_arbs==1 | prepreg_mh==1 | prepreg_adhd==1 | prepreg_cancer==1 | prepreg_immunosup==1 | prepreg_ra==1 | prepreg_hormone==1 | prepreg_thyroid==1 | prepreg_emesis==1 | prepreg_acne==1 |  prepreg_anticoag==1
	recode teratogen_prepreg .=0
	tab teratogen_prepreg
	
	* Indication
	
	* Depression ever before the start of pregnancy
	
	rename depression depression_read
	gen depression = 1 if depression_read==1 | depression_hes==1 
	replace depression = 0 if depression==.
	tab depression any_preg, col
	
	label variable depression"Depression noted in CPRD/HES ever before the start of pregnancy"
	
	replace depression_ever = 1 if depression_ever_hes==1
	replace depression_12mo = 1 if depression_12mo_hes==1
	replace depression_preg = 1 if depression_preg_hes==1
	
	* Anxiety ever before the start of pregnancy

	rename anxiety anxiety_read
	gen anxiety =1 if anxiety_read==1 | anxiety_hes==1 
	replace anxiety = 0 if anxiety==.
	tab anxiety any_preg, col
	
	label variable anxiety"Anxiety noted in CPRD/HES ever before the start of pregnancy"
	
	replace anxiety_ever = 1 if anxiety_ever_hes==1
	replace anxiety_12mo = 1 if anxiety_12mo_hes==1
	replace anxiety_preg = 1 if anxiety_preg_hes==1
	
	* Other affective / mood disorders before the start of pregnancy
	
	rename mood mood_read
	gen mood = 1 if mood_read==1 | affective_hes==1 
	replace mood = 0 if mood==.
	tab mood any_preg, col
	
	label variable mood"Other mood disorders with a depressive element noted in CPRD/HES ever before the start of pregnancy"
	
	replace mood_ever = 1 if affective_ever_hes==1
	replace mood_12mo = 1 if affective_12mo_hes==1
	replace mood_preg = 1 if affective_preg_hes==1
	
	* Eating disorders
	
	rename ed ed_read
	gen ed = 1 if ed_read==1 | ed_hes==1
	replace ed = 0 if ed==.
	tab ed any_preg, col
	
	label variable ed"Eating disorder noted in CPRD/HES ever before the start of pregnancy"
	
	replace ed_ever = 1 if ed_ever_hes==1
	replace ed_12mo = 1 if ed_12mo_hes==1
	replace ed_preg = 1 if ed_preg_hes==1
	
	* Pain
	
	rename pain pain_read
	gen pain = 1 if pain_read==1 | pain_hes==1
	replace pain = 0 if pain==.
	tab pain any_preg, col
	
	label variable pain"Pain noted in CPRD/HES ever before the start of pregnancy"
	
	replace pain_ever = 1 if pain_ever_hes==1
	replace pain_12mo = 1 if pain_12mo_hes==1
	replace pain_preg = 1 if pain_preg_hes==1
	
	* Tension-type headache
	
	rename headache headache_read
	gen headache = 1 if headache_read==1 | tt_headache_hes==1 
	replace headache = 0 if headache==.
	tab headache any_preg, col
	
	label variable headache"Tension-type headache noted in CPRD/HES ever before the start of pregnancy"
	
	replace headache_ever = 1 if tt_headache_ever_hes==1
	replace headache_12mo = 1 if tt_headache_12mo_hes==1
	replace headache_preg = 1 if tt_headache_preg_hes==1
	
	* Diabetic neuropathy
	
	rename dn dn_read
	gen dn = 1 if dn_read==1 | dn_hes==1 
	replace dn = 0 if dn==.
	tab dn any_preg, col
	
	label variable dn"Diabetic neuropathy noted in CPRD/HES ever before the start of pregnancy"
	
	replace dn_ever = 1 if dn_ever_hes==1
	replace dn_12mo = 1 if dn_12mo_hes==1
	replace dn_preg = 1 if dn_preg_hes==1
	
	* Migraine prophylaxis
	
	rename migraine migraine_read
	gen migraine = 1 if migraine_read==1 | migraine_hes==1
	replace migraine = 0 if migraine==.
	tab migraine any_preg, col
	
	label variable migraine"Migraine prophylaxis noted in CPRD/HES ever before the start of pregnancy"
	
	replace migraine_ever = 1 if migraine_ever_hes==1
	replace migraine_12mo = 1 if migraine_12mo_hes==1
	replace migraine_preg = 1 if migraine_preg_hes==1
	
	* Stress incontinence
	
	rename incont incont_read
	gen incont = 1 if incont_read==1 | stress_incont_hes==1
	replace incont = 0 if incont==.
	tab incont any_preg, col
	
	label variable incont"Stress incontinence noted in CPRD/HES ever before the start of pregnancy"
	
	replace incont_ever = 1 if stress_incont_ever_hes==1
	replace incont_12mo = 1 if stress_incont_12mo_hes==1
	replace incont_preg = 1 if stress_incont_preg_hes==1
	
	gen other_indic = 1 if incont==1 | migraine==1 | dn==1 | headache==1 | pain==1 | mood==1 | ed==1
	
	* Label indication variables

	tab depression
	tab anxiety
	tab other_indic
	recode other_indic .=0

	label variable other_indic "Other indications for antidepressants ever before the end of pregnancy"
	
*********************************************************************************	

* FOLLOW-UP FOR COX MODELS

* Generate start and end of follow-up  

	gen start_fup_CPRD=pregstart_num
	format start_fup_CPRD %td
	
	* Miscarriage
* Earliest of last data collection date for the practice, ONS death date, date of the outcome, deregistration from a CPRD practice, end of the pregnancy, end of study period (December 31st 2019) and, for early pregnancy losses only, gestational age of 24 weeks (as pregnancy losses after this date would be classified as stillbirths). 

**# End of follow-up for 84 falling out of stpm2
	* change the end of follow-up to 01jan2019 so those 84 stay in?
	
	gen gestage_24wks=pregstart_num+(7*24)
	gen end_fup_CPRD=min(tod_num, lcd_num, pregend_num, d(31dec2018), gestage_24wks)
	gen end_fup_CPRD_SB=min(tod_num, lcd_num, pregend_num, d(31dec2018))
	format end* %td

	* Checks
	count if pregstart_num>end_fup_CPRD /*0 pregnancies start after end of follow-up*/
	count if tod_num<pregend_num /*0 pregnancies transferring out before pregend*/
	
*********************************************************************************

* OUTCOMES

* Create indictor variables for outcomes, for use in tabulations

	tab outcome

	gen misc=1 if outcome==4 | outcome==9 /*miscarriage or blighted ovum*/
	gen sb=1 if outcome==2 /*stillbirth*/
	gen top=1 if outcome==5 | outcome==6 /*top or probably top*/
	gen ectop=1 if outcome==7  /*ectopic */
	gen molar=1 if outcome==8 /*molar*/
	gen ns_loss=1 if outcome==10

	label var misc "Miscarriage indicator variable"
	label var sb "Stillbirth indicator variable"
	label var top "TOP indicator variable"
	label var ns_loss "Unspecified loss indicator variable"
	label var ectop "Ectopic indicator variable"
	label var molar "Molar indicator variable"
	
	* Sensitivity analysis recoding stillbirth < 168 as miscarriage
	
	gen misc_sens = 1 if outcome==2 & gestdays_new<168 /*stillbirths with implausible GA*/
	replace misc_sens = 1 if outcome==4 | outcome==9 /*miscarriage or blighted ovum*/
	
	tab misc_sens // n=42,817
	
	gen sb_sens = 1 if outcome==2 & misc_sens!=1
	
	* replace indicator variable with missing if outcome occured after censoring
	foreach outcome in misc top ns_loss ectop molar misc_sens {

		replace `outcome'=. if pregend_num>end_fup_CPRD

	}

	replace sb=. if pregend_num>end_fup_CPRD_SB
	count
	
	* Late miscarriage 
	
	gen gestwk = round(gestdays_new/7)
	gen late_misc=1 if updated_outcome ==4 & gestwk>12
	
	* Unknown outcome
	gen uout = 1 if updated_outcome==13
	replace uout = 0 if updated_outcome!=13 & updated_outcome!=.
	
********************************************************************************

* EXPOSURE

* Exposure status

	replace any_a = 0 if any_a!=1
	replace any_o = 0 if any_o!=1
	
	* Primary analysis - exposed vs unexposed
	
	gen cf_unexposed=1 if counts_t1>0 & counts_t1!=.
	replace cf_unexposed=0 if counts_t1==0
	
	tab cf_unexposed // 73,540 exposed to antidepressants in trimester 1
	
	* Secondary analysis - exposed prevalent vs unexposed and exposed incident vs unexposed
	
		* Prevalent users exposed in trimester 1
		
		tab prevalent
	
	gen cf_unexp_prev=1 if prevalent==1
	replace cf_unexp_prev=0 if counts_t1==0
	
	tab cf_unexp_prev // 61,718 prevalent users exposed in trimester 1
	
		* Incident users exposed in trimester 1
	
	gen cf_unexp_incid=1 if prevalent==0 // & presc_startdate_num1a>=pregstart_num & presc_startdate_num1a<=pregstart_num+91
	replace cf_unexp_incid=0 if counts_t1==0
	
	tab cf_unexp_incid // 11,822 incident users exposed in trimester 1
	
		* Categorical variable for analysis 
		
	gen cf_prev_incid = 0 if counts_t1==0
	replace cf_prev_incid = 1 if cf_unexp_prev==1
	replace cf_prev_incid = 2 if cf_unexp_incid==1
	
	label define cf_prev_incid_lb 0"Unexposed" 1"Prevalent, exposed" 2"Incident, exposed"
	label values cf_prev_incid cf_prev_incid_lb
	
	tab cf_prev_incid cf_unexposed
	
	* Secondary analysis - negative control-type analysis - exposed vs unexposed discontinuers 12 months pre-preg
	
	gen cf_discont = 1 if counts_t1>0 & counts_t1!=. & any_o==1
	replace cf_discont = 0 if any_o==1 & counts_t1==0
	tab cf_discont
	
	* Secondary analysis - class analysis
	
	tab class_t1
	
	gen cf_class = class_t1
	
	tab highest_dose_t1
	
	gen cf_dose = highest_dose_t1
	
	* Sensitivity analyses
	
	tab cf_unexp_indicated_ever // 128,356 controls indicated ever
	
	gen cf_unexp_indicated_12mo=1 if any_a==1
	replace cf_unexp_indicated_12mo=0 if any_a==0 & (depression_12mo==1 | anxiety_12mo==1 | other_indic_12mo==1) // Unexposed, but indicated in 12 months pre-preg
	
	tab cf_unexp_indicated_12mo // 27,467 controls indicated in 12 months pre-preg 
	
	* Exposed prevalent (at least 2 prescriptions in the 12 months prior to pregnancy) vs unexposed and exposed incident (no prescriptions in the 12 months prior to pregnancy) vs unexposed
	
	gen cf_unexp_prev_sens=1 if counts_t1>0 & counts_t1!=. & any_o==1 & (any_l==1 | any_m==1 | any_n==1)
	replace cf_unexp_prev_sens=0 if counts_t1==0
	
	tab cf_unexp_prev_sens // 50,612 with at least two prescriptions pre-preg
	
	gen cf_unexp_incid_sens=1 if counts_t1>0 & counts_t1!=. & any_o==0 & any_l!=1 & any_m!=1 & any_n!=1
	replace cf_unexp_incid_sens=0 if counts_t1==0
	
	tab cf_unexp_incid_sens // 8,184 incident users with no use in 12 months pre-preg
	
	gen cf_prev_incid_sens = 0 if counts_t1==0
	replace cf_prev_incid_sens = 1 if cf_unexp_prev_sens==1
	replace cf_prev_incid_sens = 2 if cf_unexp_incid_sens==1
	
	drop cf_unexp_prev_sens cf_unexp_incid_sens
	
	* Among those who have a history of depression, those who are untreated
	
	gen cf_untreated = 1 if cf_unexposed==0 & depression==1
	replace cf_untreated = 0 if cf_unexposed==0 & depression==0
	
	* Sensitivity analysis for those with severe depression in the year before pregnancy
	
	gen scale_given = 1 if (flagl!=. | flagm!=. | flagn!=. | flago!=.)
	replace scale_given = 0 if (flagl==. & flagm==. & flagn==. & flago==.)
	
	gen scale_cat = 0 if (flagl==0 | flagm==0 | flagn==0 | flago==0)
	replace scale_cat = 1 if (flagl==1 | flagm==1 | flagn==1 | flago==1)
	replace scale_cat = 2 if (flagl==2 | flagm==2 | flagn==2 | flago==2) 
	replace scale_cat = 3 if (flagl==3 | flagm==3 | flagn==3 | flago==3) 
	
	tab scale_cat
	
	gen severe_flag = 1 if flagl==3 | flagm==3 | flagn==3 | flago==3
	replace severe_flag = 0 if depression==0
	
	gen any_preg_severe = 1 if severe_flag==1 & cf_unexposed==1
	replace any_preg_severe = 0 if severe_flag==1 & cf_unexposed==0
	
	* Those with >1 prescription in trimester 1
	
	gen cf_unexposed_gt1pxn = 1 if counts_t1>0 & counts_t1!=. & counts_t1>1 & counts_t1!=.
	replace cf_unexposed_gt1pxn = 0 if cf_unexposed_gt1pxn==.
	tab cf_unexposed_gt1pxn, m
	tab cf_unexposed
	
	* Prevalent users exposed in trimester 1 with >1 pxns in T1
	
	gen cf_unexp_prev_sens=1 if cf_unexposed_gt1pxn==1 & cf_prev_incid==1
	replace cf_unexp_prev_sens=0 if cf_unexp_prev_sens==.
	
	tab cf_unexp_prev_sens // 42,714 prevalent users exposed in trimester 1
	
		* Incident users exposed in trimester 1 with >1 pxns in T1
	
	gen cf_unexp_incid_sens=1 if cf_unexposed_gt1pxn==1 & cf_prev_incid==2 //presc_startdate_num1a>=pregstart_num & presc_startdate_num1a<=pregstart_num+91
	replace cf_unexp_incid_sens=0 if cf_unexp_incid_sens==.
	
	tab cf_unexp_incid // 11,822 incident users exposed in trimester 1
	
		* Categorical variable for analysis 
		
	gen cf_prev_incid_gt1pxn = 0 if cf_unexposed_gt1pxn==0
	replace cf_prev_incid_gt1pxn = 1 if cf_unexp_prev_sens==1
	replace cf_prev_incid_gt1pxn = 2 if cf_unexp_incid_sens==1
	
	tab cf_prev_incid_gt1pxn cf_prev_incid, m
	
	drop cf_unexp_prev_sens cf_unexp_incid_sens
	
*******************************************************************************

* Save temporary dataset
	
	save "$Tempdatadir\pre_dates_new_users.dta", replace
	
********************************************************************************

* Get data to define time-update exposure status

	* Trimester 1
	use "$Tempdatadir\pre_dates_new_users.dta", clear
	
	gen first_tri_new_user = 1 if prevalent==0 & counts_t1>0 & counts_t1!=. // not in the 3 months before pregnancy but in T1
	label variable first_tri_new_user"Flags new antidepressant use in T1"
	
	save "$Tempdatadir\predates_t1_new_users.dta", replace
	
* Get dates of 1st trimester prescription for new users

	bysort patid (pregnum_new): egen seq=seq()
	summ seq // max number of pregnancies within the study period is 14
	local pregmax = r(max) 
		
	forvalues x=1/`pregmax' {
			
			*duplicates drop patid, force - do I want to do this? Some patients initiate ADs in T1 for multiple pregnancies
			use "$Tempdatadir\predates_t1_new_users.dta", clear
			keep if first_tri_new_user==1
			keep if pregnum_new==`x'
			merge 1:m patid using "$Patternsdir\patterns_in_pregnancy_long.dta", keep(master match) 
			
			if _N>0 {
			
				keep patid pregid pregstart_num any_o any_a presc_startdate_num1a
				sort patid pregid presc_startdate_num1a
				br
				gen flag_1st_trim_presc=1 if presc_startdate_num1a>=pregstart_num & presc_startdate_num1a<=pregstart_num+97
				keep if flag_1st==1
				bysort pregid (presc_startdate_num1a): keep if _n==1
				codebook pregid
				rename presc_startdate_num1a first_tri_initiation_date
				keep patid pregid flag_1st_trim_presc first_tri_initiation_date
				label var first_tri_initiation_date "Date of antidepressant initiation in 1st trim new users"
				
			}
			
			else if _N==0 {
				
				keep patid pregid
				
			}
			
			save "$Tempdatadir\dates_t1_new_users_`x'.dta", replace

	}
		
	use "$Tempdatadir\dates_t1_new_users_1.dta"
	
	forvalues x=2/`pregmax' {
		
		append using "$Tempdatadir\dates_t1_new_users_`x'.dta"
		
	}
	
	duplicates drop patid pregid, force

	merge 1:1 patid pregid using "$Tempdatadir\pre_dates_new_users.dta", nogen // 4,815 with dates*/
	
	gen first_tri_initiation_date = presc_startdate_num1a if presc_startdate_num1a !=. & counts_t1>0 & counts_t1!=. & prevalent==0
	
	count if first_tri_initiation_date!=. // 11,822 with a date
	
	* if first trimester initiation date is pregnancy start date, add one day to intiation dates
	replace first_tri_initiation_date=first_tri_initiation_date+1 if pregstart_num==first_tri_initiation_date
	
	* Get all of the dates on the pregnancy axis
	gen cycle_1_start = first_tri_initiation_date-pregstart_num
	gen start_date = 0
	gen end_fup=end_fup_CPRD-pregstart_num
	
	save "$Tempdatadir\dates_t1_new_users.dta", replace
	
********************************************************************************

* Retain required variables only

	keep patid pregid start_fup_CPRD end* pregstart_num pregend_num presc_startdate_num1a outcome gestdays_new ///
	lcd_num tod_num ///
	cycle_1_start start_date end_fup /// dates for Cox
	misc top ns_loss sb ectop molar late_misc misc_sens sb_sens uout outcome_updated_flag /// /*outcomes*/
	cf* first_tri_initiation_date any_preg_severe counts* /// /*exposures*/
	matage_cat matage eth5  AreaOfResidence  imd_practice preg_year preg_yr_gp teratogen_prepreg ///  /*demogs*/
	smokstatus  bmi_cat bmi alcstatus hazardous_drinking illicitdrug_preg ///   /*behaviours*/
	CPRD_consultation_events_cat ///   /*h/c use*/
	antipsychotics_prepreg  moodstabs_prepreg folic_prepreg1 ///  /*drug use*/
	hes_apc_e multiple_ev pregnum_new hist_loss grav_hist* parity_cat parity ///
	preg_test depression* anxiety* mood* ed* pain* headache* dn* migraine* incont* other_indic severe* scale_* /*indications*/
	* indic indic_preg count_indic_preg_cat count_indic_cat indic indic_6mo preg_test 
	
	save "$Datadir\primary_analysis_dataset_updated.dta", replace
 
	*save "$Datadir\primary_analysis_dataset.dta", replace
	
	* Indication PRIOR TO THE START OF PREGNANCY
	keep if depression==1 | anxiety==1 | other_indic==1
	
	save "$Datadir\primary_analysis_dataset_indic_pre_startofpreg.dta", replace
	
********************************************************************************
	
* Delete unnecessary datasets

	forvalues x=1/`pregmax' {
		
		erase "$Tempdatadir\dates_t1_new_users_`x'.dta"
		
	}
	
	erase "$Tempdatadir\predates_t1_new_users.dta"

*********************************************************************************

* Stop logging

	log close primary_analysis_dataset
	
	translate "$Logdir\1_cleaning\1_primary analysis dataset.smcl" "$Logdir\1_cleaning\1_primary analysis dataset.pdf", replace
	
	erase "$Logdir\1_cleaning\1_primary analysis dataset.smcl"
	
*********************************************************************************
