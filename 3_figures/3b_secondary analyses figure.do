********************************************************************************	

  * Secondary analyses and absolute risk figure: pattern Cox models, class Cox models, and dose Cox models on the left-hand panel. Absolute risk adjusted for confounders bar chart on the right-hand panel

  * Author: Flo Martin

  * Date: 12/11/2024

********************************************************************************

* Findings from the secondary analyses.

********************************************************************************

* Start logging 

	log using "$Logdir\3_figures\3b_secondary analyses figure", name(secondary_figure) replace

********************************************************************************
	
* Load in the data and prepare for including in the twoway code

	import delimited using "$Graphdir\results fig data.txt", clear
	
	foreach var in primary discordant propensity {
		
		replace model = "`var'0" if or==1 & model=="`var'"
		replace model = "`var'1" if or!=1 & model=="`var'"
		
	}
	
	egen seq=seq()
	
	merge 1:1 model using "$Graphdir\primary analysis counts.dta", nogen
	merge 1:1 model using "$Graphdir\secondary analysis counts.dta", update replace nogen
	
	replace nn = subinstr(nn, " ", "", .)
	replace nn = subinstr(nn, "/", " / ", .)
	replace nn = subinstr(nn, "(", " (", .)
	
	sort seq
	
	local y = 1
	
	foreach var in primary discordant propensity pattern class dose {
		
		set obs `=_N+1'
		replace model = "a_`var'" if model==""
		replace seq = `y' if regexm(model, "`var'")
		
		local y = `y' + 1
		
	}
	
	foreach var in primary discordant propensity pattern class dose {
		
		set obs `=_N+1'
		replace model = "a_`var'" if model==""
		replace seq = `y' if regexm(model, "`var'")
		
		local y = `y' + 1
		
	}
	
	sort seq model
	
	format misc %7.0fc
	format total %7.0fc
	format pct %4.1f
	
	gen logor = log(or)
	gen loglci = log(lci)
	gen loguci = log(uci)
	
	drop seq
	egen seq=seq()
	
	keep if seq>12
	
	* Macros to create the null line
	local t1=13.5
	local t2=32

* To allow the loops to run

	replace unadj_or=10 if unadj_or==.
	replace unadj_lci=10 if unadj_lci==.
	replace unadj_uci=10 if unadj_uci==.

	replace or=10 if or==.
	replace lci=10 if lci==.
	replace uci=10 if uci==.
	
	forvalues x=13/31 {
		foreach y in unadj_or unadj_lci unadj_uci or lci uci {
		
			sum `y' if seq==`x'
			local `y'_`x' = `r(mean)'
			local `y'_`x'_f : display %4.2fc ``y'_`x'' 
			
		}		
	}
	
	forvalues x=13/31 {
		foreach y in unadj_or unadj_lci unadj_uci or lci uci {
		
			sum `y' if seq==`x'
			local `y'_`x' = `r(mean)'
			local `y'_`x'_f : display %4.2fc ``y'_`x'' 
			
		}		
	}
	
	replace unadj_or=. if unadj_or==10
	replace unadj_lci=. if unadj_lci==10
	replace unadj_uci=. if unadj_uci==10
	
	replace or=. if or==10
	replace lci=. if lci==10
	replace uci=. if uci==10
	
	forvalues x=1/19 {
	
		local total_exp_`x' = nn[`x']
		di "`total_exp_`x''"
		
	}
	
	set scheme tab2

* Twoway code to create the left-hand panel showing the results from the secondary Cox models

	twoway ///
	(scatteri `t1' 1 `t2' 1, recast(line) yaxis(1) lpatter(dash) lcolor(cranberry)) /// null line
	(rcap unadj_lci unadj_uci seq if unadj_or!=1, horizontal lcolor(gs12)) /// code for unadjusted 95% CI
	(scatter seq unadj_or if unadj_or!=1, mcolor(gs12) ms(o) msize(medium) mlcolor(gs12) mlw(thin)) /// unadjusted estimates
	(rcap lci uci seq, horizontal lcolor(black)) /// code for adjusted 95% CI
	(scatter seq or, mcolor("85 119 135") ms(o) msize(medium) mlcolor(black) mlw(thin)), /// adjusted estimates
	text(12.75 0.4 "{bf:Analytical approach}", size(*0.5) justification(left) placement(e)) text(12.75 0.79 "{bf:Miscarriage / Total}" "{it:n} / N (%)", size(*0.5) justification(left) placement(w)) text(12.75 2.1 "{bf:Unadjusted HR}", size(*0.5) justification(left) placement(e) color(gs10)) text(12.75 2.8 "{bf:Adjusted* HR}", size(*0.5) justification(left) placement(e)) /// heading text
	text(14 0.4 "{bf:Pattern analysis}", size(*0.5) justification(left) placement(e)) /// graph text: analytical approach
		text(15 0.4 "Unexposed", size(*0.5) justification(left) placement(e)) /// comparator
	text(15 0.79 "`total_exp_3'", size(*0.5) justification(right) placement(w)) /// n / N comparator
	text(15 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) /// 
	text(15 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(16 0.4 "Prevalent, exposed", size(*0.5) justification(left) placement(e)) /// prevalent exposure group
	text(16 0.79 "`total_exp_4'", size(*0.5) justification(right) placement(w)) /// n / N prevalent users
	text(16 2.1 "`unadj_or_16_f' (`unadj_lci_16_f' – `unadj_uci_16_f')", size(*0.5) justification(left) placement(e) color(gs10)) /// unadjusted estimates
	text(16 2.8 "`or_16_f' (`lci_16_f' – `uci_16_f')", size(*0.5) justification(left) placement(e)) /// adjusted estimates
	text(17 0.4 "Incident, exposed", size(*0.5) justification(left) placement(e)) ///
	text(17 0.79 "`total_exp_5'", size(*0.5) justification(right) placement(w)) ///
	text(17 2.1 "`unadj_or_17_f' (`unadj_lci_17_f' – `unadj_uci_17_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(17 2.8 "`or_17_f' (`lci_17_f' – `uci_17_f')", size(*0.5) justification(left) placement(e)) ///
	text(19 0.4 "{bf:Class analysis}", size(*0.5) justification(left) placement(e)) ///
		text(20 0.4 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(20 0.79 "`total_exp_8'", size(*0.5) justification(right) placement(w)) ///
	text(20 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(20 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(21 0.4 "SSRI exposed", size(*0.5) justification(left) placement(e)) ///
	text(21 0.79 "`total_exp_9'", size(*0.5) justification(right) placement(w)) ///
	text(21 2.1 "`unadj_or_21_f' (`unadj_lci_21_f' – `unadj_uci_21_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(21 2.8 "`or_21_f' (`lci_21_f' – `uci_21_f')", size(*0.5) justification(left) placement(e)) ///
	text(22 0.4 "SNRI exposed", size(*0.5) justification(left) placement(e)) ///
	text(22 0.79 "`total_exp_10'", size(*0.5) justification(right) placement(w)) ///
	text(22 2.1 "`unadj_or_22_f' (`unadj_lci_22_f' – `unadj_uci_22_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(22 2.8 "`or_22_f' (`lci_22_f' – `uci_22_f')", size(*0.5) justification(left) placement(e)) ///
	text(23 0.4 "TCA exposed", size(*0.5) justification(left) placement(e)) ///
	text(23 0.79 "`total_exp_11'", size(*0.5) justification(right) placement(w)) ///
	text(23 2.1 "`unadj_or_23_f' (`unadj_lci_23_f' – `unadj_uci_23_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(23 2.8 "`or_23_f' (`lci_23_f' – `uci_23_f')", size(*0.5) justification(left) placement(e)) ///
	text(24 0.4 "Other exposed", size(*0.5) justification(left) placement(e)) ///
	text(24 0.79 "`total_exp_12'", size(*0.5) justification(right) placement(w)) ///
	text(24 2.1 "`unadj_or_24_f' (`unadj_lci_24_f' – `unadj_uci_24_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(24 2.8 "`or_24_f' (`lci_24_f' – `uci_24_f')", size(*0.5) justification(left) placement(e)) ///
	text(25 0.4 "Multiple class exposed", size(*0.5) justification(left) placement(e)) ///
	text(25 0.79 "`total_exp_13'", size(*0.5) justification(right) placement(w)) ///
	text(25 2.1 "`unadj_or_25_f' (`unadj_lci_25_f' – `unadj_uci_25_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(25 2.8 "`or_25_f' (`lci_25_f' – `uci_25_f')", size(*0.5) justification(left) placement(e)) ///
	text(27 0.4 "{bf:Dose analysis}", size(*0.5) justification(left) placement(e)) ///
	text(28 0.4 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(28 0.79 "`total_exp_16'", size(*0.5) justification(right) placement(w)) ///
	text(28 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(28 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
		text(29 0.4 "Low dose", size(*0.5) justification(left) placement(e)) ///
	text(29 0.79 "`total_exp_17'", size(*0.5) justification(right) placement(w)) ///
	text(29 2.1 "`unadj_or_29_f' (`unadj_lci_29_f' – `unadj_uci_29_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(29 2.8 "`or_29_f' (`lci_29_f' – `uci_29_f')", size(*0.5) justification(left) placement(e)) ///
	text(30 0.4 "Medium dose", size(*0.5) justification(left) placement(e)) ///
	text(30 0.79 "`total_exp_18'", size(*0.5) justification(right) placement(w)) ///
	text(30 2.1 "`unadj_or_30_f' (`unadj_lci_30_f' – `unadj_uci_30_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(30 2.8 "`or_30_f' (`lci_30_f' – `uci_30_f')", size(*0.5) justification(left) placement(e)) ///
	text(31 0.4 "High dose", size(*0.5) justification(left) placement(e)) ///
	text(31 0.79 "`total_exp_19'", size(*0.5) justification(right) placement(w)) ///
	text(31 2.1 "`unadj_or_31_f' (`unadj_lci_31_f' – `unadj_uci_31_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(31 2.8 "`or_31_f' (`lci_31_f' – `uci_31_f')", size(*0.5) justification(left) placement(e)) ///
	text(35 0.4 "*Adjusted for maternal age, pregnancy year, practice-level IMD quintile, history of miscarriage, smoking status around the start of pregnancy, parity at the start of" "pregnancy, use of high dose folic acid, antipsychotics, or anti-seizure medication in the 12 months before pregnancy, number of primary care consultations in the" "12 months before pregnancy, and severe mental illness, depression or anxiety ever before the start of pregnancy", size(*0.45) justification(left) placement(e)) /// covariates in the models
	yscale(range(12 31) noline reverse) ylab("", angle(0) labsize(*0.6) notick nogrid nogextend) /// y axis elements
	xscale(range(0.4(0.2)3.6) log titlegap(1)) xlabel(0.8(0.2)2, labsize(vsmall) format(%3.1fc) ) xtitle("{bf}Hazard ratio (95% confidence interval)", size(vsmall)) /// x axis elements
	legend(order(3 "Unadjusted" 5 "Adjusted*") pos(5) col(1) region(lcolor(black))) /// legend
	yline(12) yline(13.5) yline(18, lcolor(gray) lpattern(dot)) yline(26, lcolor(gray) lpattern(dot)) /// distinguishing lines
	plotregion(margin(0 0 0 0)) name(hr_chunk, replace)

* Load in the data for absolute risk adjusted for confounders

	use "$Graphdir\marginal risk.dta", clear
	
	gen row=3 if x=="Unexposed"
	replace row=4 if row==.
	
	drop x
	
	append using "$Graphdir\marginal risk patterns.dta"
	
	replace row = 15 if x=="Unexposed"
	replace row = 16 if x=="Prevalent"
	replace row = 17 if x=="Incident"
	
	drop x
	
	append using "$Graphdir\marginal risk class.dta"
	
	replace row = 20 if x=="Unexposed"
	replace row = 21 if x=="ssri"
	replace row = 22 if x=="snri"
	replace row = 23 if x=="tca"
	replace row = 24 if x=="other"
	replace row = 25 if x=="multi"
	
	drop x
	
	append using "$Graphdir\marginal risk dose.dta"
	
	replace row = 28 if x=="Unexposed"
	replace row = 29 if x=="low"
	replace row = 30 if x=="med"
	replace row = 31 if x=="high"
	
	drop x
	
	drop if row<15
	
	foreach y in risk lci uci {
		foreach x in row 15 16 17 20 21 22 23 24 25 28 29 30 31 {
		
			sum `y' if row==`x'
			local `y'`x' = `r(mean)'
			local `y'`x'_f : display %4.1fc ``y'`x'' 
		
		}
	}

	
	set scheme tab2

	* Make the bar chart of marginal risk
	twoway ///
	(bar risk row, fcolor("85 119 135") lcolor("85 119 135") horiz barwidth(0.75)) /// bar chart for absolute risk
	(rcap lci uci row, horiz lcolor(black)), /// 95% CI
	text(12.75 0.25 "{bf}Absolute risk of miscarriage adjusted for confounders*", box bcolor("white") margin(t+1.2 b+1.2) color(black) size(*0.5) justification(left) placement(e)) /// heading text
	text(15 0.25 "{bf}`risk15_f'%", color(black) size(*0.5) justification(left) placement(e)) text(15 2.2 "(`lci15_f' – `uci15_f'%)", color(black) size(*0.5) justification(left) placement(e)) /// absolute risk and 95% CI
	text(16 0.25 "{bf}`risk16_f'%", color(black) size(*0.5) justification(left) placement(e)) text(16 2.2 "(`lci16_f' – `uci16_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(17 0.25 "{bf}`risk17_f'%", color(black) size(*0.5) justification(left) placement(e)) text(17 2.2 "(`lci17_f' – `uci17_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(20 0.25 "{bf}`risk20_f'%", color(black) size(*0.5) justification(left) placement(e)) text(20 2.2 "(`lci20_f' – `uci20_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(21 0.25 "{bf}`risk21_f'%", color(black) size(*0.5) justification(left) placement(e)) text(21 2.2 "(`lci21_f' – `uci22_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(22 0.25 "{bf}`risk22_f'%", color(black) size(*0.5) justification(left) placement(e)) text(22 2.2 "(`lci22_f' – `uci22_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(23 0.25 "{bf}`risk23_f'%", color(black) size(*0.5) justification(left) placement(e)) text(23 2.2 "(`lci23_f' – `uci23_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(24 0.25 "{bf}`risk24_f'%", color(black) size(*0.5) justification(left) placement(e)) text(24 2.2 "(`lci24_f' – `uci24_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(25 0.25 "{bf}`risk25_f'%", color(black) size(*0.5) justification(left) placement(e)) text(25 2.2 "(`lci25_f' – `uci25_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(28 0.25 "{bf}`risk28_f'%", color(black) size(*0.5) justification(left) placement(e)) text(28 2.2 "(`lci28_f' – `uci28_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(29 0.25 "{bf}`risk29_f'%", color(black) size(*0.5) justification(left) placement(e)) text(29 2.2 "(`lci29_f' – `uci29_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(30 0.25 "{bf}`risk30_f'%", color(black) size(*0.5) justification(left) placement(e)) text(30 2.2 "(`lci30_f' – `uci30_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	text(31 0.25 "{bf}`risk31_f'%", color(black) size(*0.5) justification(left) placement(e)) text(31 2.2 "(`lci31_f' – `uci31_f'%)", color(black) size(*0.5) justification(left) placement(e)) ///
	yline(12) yline(13.5) yline(18, lcolor(gray) lpattern(dot)) yline(26, lcolor(gray) lpattern(dot)) /// distinguishing lines
	legend(label(1 "Adjusted* risk") label(2 "Bootstrapped 95% CI") order(1 2) col(1) pos(6) region(lcolor(black))) /// legend
	yscale(range(12 32) titlegap(5) reverse off) ylab(12 "U" 13 "E", labsize(vsmall) nogrid labcolor(white) notick) ytitle("") /// y axis elements
	xscale(range(0 18) titlegap(1)) xlab(0(2)18, labsize(vsmall) ) xtitle("{bf}Miscarriage (%)", size(vsmall)) /// x axis elements
	graphregion(color(white) lcolor(black)) plotregion(margin(0 0 0 0)) name(risk, replace) ///
	fysize(100) fxsize(40) /// change the size so it isnt equal to the left-hand panel
	
	* Combine the graphs to make the primary figure
	graph combine hr_chunk risk, title("{bf}First trimester antidepressant use and miscarriage:" "adjusted relative and absolute risks from secondary analyses", size(small)) imargin(tiny) name(secondary_fig, replace)
	
	graph export "$Graphdir\secondary_fig.pdf", replace

********************************************************************************	
	
* Stop logging

	log close secondary_figure
	
	translate "$Logdir\3_figures\3b_secondary analyses figure.smcl" "$Logdir\3_figures\3b_secondary analyses figure.pdf", replace
	
	erase "$Logdir\3_figures\3b_secondary analyses figure.smcl"
	
********************************************************************************
