********************************************************************************

* Creating a single figure containing both primary and secondary analyses (for journals with low figure limits)

* Author: Flo Martin 

* Date: 08/11/2024

********************************************************************************

* Findings from the primary and secondary analyses.

********************************************************************************

* Start logging 

	log using "$Logdir\3_figures\3_primary and secondary single figure", name(prim_sec_figure) replace
	
********************************************************************************

	cd "$Graphdir"
	
* Primary analyses counts
	
	import delimited using "$Tabledir\primary analysis.txt", varnames(1) clear
	
	rename v1 model
	egen seq=seq()
	
	keep model nn seq
	
	drop if nn==""
	
		replace model="primary0" if seq==3
		replace model="primary1" if seq==4
		
		replace model="discordant0" if seq==6
		replace model="discordant1" if seq==7
		
		replace model="propensity0" if seq==8
		replace model="propensity1" if seq==9

	drop seq	
	
	gen seq=.
	replace seq=1 if regexm(model, "primary")
	replace seq=2 if regexm(model, "discordant")
	replace seq=3 if regexm(model, "propensity")
	
	save "$Graphdir\primary analysis counts.dta", replace
	
* Secondary analyses counts
	
	import delimited using "$Tabledir\pattern class dose.txt", varnames(1) clear
	
	drop if nn==""
	
	egen seq=seq()
	
	forvalues x=0/2 {
		
		local y=`x'+1
		
		replace v1 = "pattern `x'" if seq==`y'
		
	}
	
	forvalues x=0/5 {
		
		local y=`x'+4
		
		replace v1 = "class `x'" if seq==`y'
		
	}
	
	forvalues x=0/3 {
		
		local y=`x'+10
		
		replace v1 = "dose `x'" if seq==`y'
		
	}
	
	rename v1 model
	
	keep model nn
	
	save "$Graphdir\secondary analysis counts", replace 
	
* Estimates

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
	
	/*gen numbers = ""
	
	forvalues x=1/18 {
		
		sum misc if seq==`x'
		
		local exp_`x'=`r(max)'
		local exp_fm_`x' : display %7.0fc `exp_`x''
		
		sum total if seq==`x'
		local total_`x'=`r(max)'
		local total_fm_`x' : display %7.0fc `total_`x''
		
		replace numbers="`exp_fm_`x''/`total_fm_`x''" if seq==`x'
		
	}
	
	gen analysis=1 if regexm(model, "primary" ) 
	replace analysis=2 if regexm(model, "discordant" )
	replace analysis=3 if regexm(model, "propensity" )
	replace analysis=4 if regexm(model, "pattern" )
	replace analysis=5 if regexm(model, "class" )
	replace analysis=6 if regexm(model, "dose" ) */
	
	gen logor = log(or)
	gen loglci = log(lci)
	gen loguci = log(uci)
	
	drop seq
	egen seq=seq() 
	
	* Macros to create the null line
	local t1=1
	local t2=32
	
	replace unadj_or=10 if unadj_or==.
	replace unadj_lci=10 if unadj_lci==.
	replace unadj_uci=10 if unadj_uci==.

	replace or=10 if or==.
	replace lci=10 if lci==.
	replace uci=10 if uci==.
	
	forvalues x=3/31 {
		foreach y in unadj_or unadj_lci unadj_uci or lci uci {
		
			sum `y' if seq==`x'
			local `y'_`x' = `r(mean)'
			local `y'_`x'_f : display %4.2fc ``y'_`x'' 
			
		}		
	}
	
	forvalues x=3/31 {
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
	
	forvalues x=3/31 {
	
		local total_exp_`x' = nn[`x']
		di "`total_exp_`x''"
		
	}
	
	set scheme tab2
	
	twoway ///
	(scatteri `t1' 1 `t2' 1, recast(line) yaxis(1) lpatter(dash) lcolor(cranberry)) /// null line
	(rcap unadj_lci unadj_uci seq if unadj_or!=1, horizontal lcolor(gs12)) /// code for NO 95% CI
	(scatter seq unadj_or if unadj_or!=1, mcolor(gs12) ms(o) msize(medium) mlcolor(gs12) mlw(thin)) ///
	(rcap lci uci seq, horizontal lcolor(black)) /// code for NO 95% CI
	(scatter seq or, mcolor("85 119 135") ms(o) msize(medium) mlcolor(black) mlw(thin)), ///
	text(0.5 0.4 "{bf:Analytical approach}", size(*0.5) justification(left) placement(e)) text(0.5 0.79 "{bf:Miscarriage n / Total N (%)}", size(*0.5) justification(left) placement(w)) text(0.5 2.1 "{bf:Unadjusted HR}", size(*0.5) justification(left) placement(e) color(gs10)) text(0.5 2.8 "{bf:Adjusted HR}", size(*0.5) justification(left) placement(e)) ///
	text(2 0.4 "{bf:Primary analysis*}", size(*0.5) justification(left) placement(e)) ///
		text(3 0.4 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(3 0.79 "`total_exp_3'", size(*0.5) justification(right) placement(w)) ///
	text(3 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(3 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(4 0.4 "Exposed", size(*0.5) justification(left) placement(e)) ///
	text(4 0.79 "`total_exp_4'", size(*0.5) justification(right) placement(w)) ///
	text(4 2.1 "`unadj_or_4_f' (`unadj_lci_4_f' – `unadj_uci_4_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(4 2.8 "`or_4_f' (`lci_4_f' – `uci_4_f')", size(*0.5) justification(left) placement(e)) ///
	text(6 0.42 "{bf:Exposure discordant analysis**}", size(*0.5) justification(left) placement(e)) ///
		text(7 0.42 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(7 0.79 "`total_exp_7'", size(*0.5) justification(right) placement(w)) ///
	text(7 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(7 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(8 0.42 "Exposed", size(*0.5) justification(left) placement(e)) ///
	text(8 0.79 "`total_exp_8'", size(*0.5) justification(right) placement(w)) ///
	text(8 2.1 "`unadj_or_8_f' (`unadj_lci_8_f' – `unadj_uci_8_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(8 2.8 "`or_8_f' (`lci_8_f' – `uci_8_f')", size(*0.5) justification(left) placement(e)) ///
	text(10 0.42 "{bf:Propensity score analysis***}", size(*0.5) justification(left) placement(e)) ///
		text(11 0.42 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(11 0.79 "`total_exp_11'", size(*0.5) justification(right) placement(w)) ///
	text(11 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(11 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(12 0.42 "Exposed", size(*0.5) justification(left) placement(e)) ///
	text(12 0.79 "`total_exp_12'", size(*0.5) justification(right) placement(w)) ///
	text(12 2.1 "-", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(12 2.8 "`or_12_f' (`lci_12_f' – `uci_12_f')", size(*0.5) justification(left) placement(e)) ///
	text(14 0.4 "{bf:Pattern analysis*}", size(*0.5) justification(left) placement(e)) ///
		text(15 0.4 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(15 0.79 "`total_exp_15'", size(*0.5) justification(right) placement(w)) ///
	text(15 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(15 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(16 0.4 "Prevalent, exposed", size(*0.5) justification(left) placement(e)) ///
	text(16 0.79 "`total_exp_16'", size(*0.5) justification(right) placement(w)) ///
	text(16 2.1 "`unadj_or_16_f' (`unadj_lci_16_f' – `unadj_uci_16_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(16 2.8 "`or_16_f' (`lci_16_f' – `uci_16_f')", size(*0.5) justification(left) placement(e)) ///
	text(17 0.4 "Incident, exposed", size(*0.5) justification(left) placement(e)) ///
	text(17 0.79 "`total_exp_17'", size(*0.5) justification(right) placement(w)) ///
	text(17 2.1 "`unadj_or_17_f' (`unadj_lci_17_f' – `unadj_uci_17_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(17 2.8 "`or_17_f' (`lci_17_f' – `uci_17_f')", size(*0.5) justification(left) placement(e)) ///
	text(19 0.4 "{bf:Class analysis*}", size(*0.5) justification(left) placement(e)) ///
		text(20 0.4 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(20 0.79 "`total_exp_20'", size(*0.5) justification(right) placement(w)) ///
	text(20 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(20 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(21 0.4 "SSRI exposed", size(*0.5) justification(left) placement(e)) ///
	text(21 0.79 "`total_exp_21'", size(*0.5) justification(right) placement(w)) ///
	text(21 2.1 "`unadj_or_21_f' (`unadj_lci_21_f' – `unadj_uci_21_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(21 2.8 "`or_21_f' (`lci_21_f' – `uci_21_f')", size(*0.5) justification(left) placement(e)) ///
	text(22 0.4 "SNRI exposed", size(*0.5) justification(left) placement(e)) ///
	text(22 0.79 "`total_exp_22'", size(*0.5) justification(right) placement(w)) ///
	text(22 2.1 "`unadj_or_22_f' (`unadj_lci_22_f' – `unadj_uci_22_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(22 2.8 "`or_22_f' (`lci_22_f' – `uci_22_f')", size(*0.5) justification(left) placement(e)) ///
	text(23 0.4 "TCA exposed", size(*0.5) justification(left) placement(e)) ///
	text(23 0.79 "`total_exp_23'", size(*0.5) justification(right) placement(w)) ///
	text(23 2.1 "`unadj_or_23_f' (`unadj_lci_23_f' – `unadj_uci_23_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(23 2.8 "`or_23_f' (`lci_23_f' – `uci_23_f')", size(*0.5) justification(left) placement(e)) ///
	text(24 0.4 "Other exposed", size(*0.5) justification(left) placement(e)) ///
	text(24 0.79 "`total_exp_24'", size(*0.5) justification(right) placement(w)) ///
	text(24 2.1 "`unadj_or_24_f' (`unadj_lci_24_f' – `unadj_uci_24_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(24 2.8 "`or_24_f' (`lci_24_f' – `uci_24_f')", size(*0.5) justification(left) placement(e)) ///
	text(25 0.4 "Multiple class exposed", size(*0.5) justification(left) placement(e)) ///
	text(25 0.79 "`total_exp_25'", size(*0.5) justification(right) placement(w)) ///
	text(25 2.1 "`unadj_or_25_f' (`unadj_lci_25_f' – `unadj_uci_25_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(25 2.8 "`or_25_f' (`lci_25_f' – `uci_25_f')", size(*0.5) justification(left) placement(e)) ///
	text(27 0.4 "{bf:Dose analysis*}", size(*0.5) justification(left) placement(e)) ///
	text(28 0.4 "Unexposed in T1", size(*0.5) justification(left) placement(e)) ///
	text(28 0.79 "`total_exp_28'", size(*0.5) justification(right) placement(w)) ///
	text(28 2.1 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(28 2.8 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
		text(29 0.4 "Low dose", size(*0.5) justification(left) placement(e)) ///
	text(29 0.79 "`total_exp_29'", size(*0.5) justification(right) placement(w)) ///
	text(29 2.1 "`unadj_or_29_f' (`unadj_lci_29_f' – `unadj_uci_29_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(29 2.8 "`or_29_f' (`lci_29_f' – `uci_29_f')", size(*0.5) justification(left) placement(e)) ///
	text(30 0.4 "Medium dose", size(*0.5) justification(left) placement(e)) ///
	text(30 0.79 "`total_exp_30'", size(*0.5) justification(right) placement(w)) ///
	text(30 2.1 "`unadj_or_30_f' (`unadj_lci_30_f' – `unadj_uci_30_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(30 2.8 "`or_30_f' (`lci_30_f' – `uci_30_f')", size(*0.5) justification(left) placement(e)) ///
	text(31 0.4 "High dose", size(*0.5) justification(left) placement(e)) ///
	text(31 0.79 "`total_exp_31'", size(*0.5) justification(right) placement(w)) ///
	text(31 2.1 "`unadj_or_31_f' (`unadj_lci_31_f' – `unadj_uci_31_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(31 2.8 "`or_31_f' (`lci_31_f' – `uci_31_f')", size(*0.5) justification(left) placement(e)) ///
	yscale(range(0 31) noline reverse) ylab("", angle(0) labsize(*0.6) notick nogrid nogextend) ///
	xscale(range(0.4(0.2)3.6) log titlegap(1)) xlabel(0.8(0.2)2, labsize(vsmall) format(%3.1fc)) xtitle("{bf}Hazard ratio (95% confidence interval)", size(vsmall)) ///
	legend(order(3 "Unadjusted" 5 "Adjusted") pos(6) col(2)) ///
	yline(0) yline(1) yline(5, lcolor(gray) lpattern(dot)) yline(9, lcolor(gray) lpattern(dot)) yline(13, lcolor(gray) lpattern(dot)) yline(18, lcolor(gray) lpattern(dot)) yline(26, lcolor(gray) lpattern(dot)) ///
	plotregion(margin(0 0 0 0)) name(hr_chunk, replace)
	
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
	
	* Generate variables for second axis (to make box around the graph using scatter)
	gen x=1.5
	gen y=-0.5
	
	foreach y in risk lci uci {
		foreach x in row 3 4 15 16 17 20 21 22 23 24 25 28 29 30 31 {
		
			sum `y' if row==`x'
			local `y'`x' = `r(mean)'
			local `y'`x'_f : display %4.1fc ``y'`x'' 
		
		}
	}

	
	set scheme tab2
	
	* Make the bar chart of marginal risk
	twoway ///
	(bar risk row, fcolor("85 119 135") lcolor("85 119 135") horiz barwidth(0.75)) ///
	(rcap lci uci row, horiz lcolor(black)), ///
	text(0.5 0.25 "{bf}Absolute risk of miscarriage adjusted for confounders*", color(black) bcolor("white") margin(t+0.75 b+0.75) size(*0.5) justification(left) placement(e)) ///
	text(3 0.25 "{bf}`risk3_f'%", color(black) size(tiny) justification(left) placement(e)) text(3 1.75 "(`lci3_f' – `uci3_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(4 0.25 "{bf}`risk4_f'%", color(black) size(tiny) justification(left) placement(e)) text(4 1.75 "(`lci4_f' – `uci4_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(15 0.25 "{bf}`risk15_f'%", color(black) size(tiny) justification(left) placement(e)) text(15 1.75 "(`lci15_f' – `uci15_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(16 0.25 "{bf}`risk16_f'%", color(black) size(tiny) justification(left) placement(e)) text(16 1.75 "(`lci16_f' – `uci16_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(17 0.25 "{bf}`risk17_f'%", color(black) size(tiny) justification(left) placement(e)) text(17 1.75 "(`lci17_f' – `uci17_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(20 0.25 "{bf}`risk20_f'%", color(black) size(tiny) justification(left) placement(e)) text(20 1.75 "(`lci20_f' – `uci20_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(21 0.25 "{bf}`risk21_f'%", color(black) size(tiny) justification(left) placement(e)) text(21 1.75 "(`lci21_f' – `uci22_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(22 0.25 "{bf}`risk22_f'%", color(black) size(tiny) justification(left) placement(e)) text(22 1.75 "(`lci22_f' – `uci22_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(23 0.25 "{bf}`risk23_f'%", color(black) size(tiny) justification(left) placement(e)) text(23 1.75 "(`lci23_f' – `uci23_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(24 0.25 "{bf}`risk24_f'%", color(black) size(tiny) justification(left) placement(e)) text(24 1.75 "(`lci24_f' – `uci24_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(25 0.25 "{bf}`risk25_f'%", color(black) size(tiny) justification(left) placement(e)) text(25 1.75 "(`lci25_f' – `uci25_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(28 0.25 "{bf}`risk28_f'%", color(black) size(tiny) justification(left) placement(e)) text(28 1.75 "(`lci28_f' – `uci28_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(29 0.25 "{bf}`risk29_f'%", color(black) size(tiny) justification(left) placement(e)) text(29 1.75 "(`lci29_f' – `uci29_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(30 0.25 "{bf}`risk30_f'%", color(black) size(tiny) justification(left) placement(e)) text(30 1.75 "(`lci30_f' – `uci30_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	text(31 0.25 "{bf}`risk31_f'%", color(black) size(tiny) justification(left) placement(e)) text(31 1.75 "(`lci31_f' – `uci31_f'%)", color(black) size(tiny) justification(left) placement(e)) ///
	yline(0) yline(1) yline(5, lcolor(gray) lpattern(dot)) yline(9, lcolor(gray) lpattern(dot)) yline(13, lcolor(gray) lpattern(dot)) yline(18, lcolor(gray) lpattern(dot)) yline(26, lcolor(gray) lpattern(dot)) ///
	legend(label(1 "Adjusted risk") label(2 "Bootstrapped 95%CI") order(1 2) col(2) pos(6)) ///
	yscale(range(1 32) titlegap(5) reverse off) ylab(0 "U" 1 "E", labsize(vsmall) nogrid labcolor(white) notick) ytitle("") ///
	xscale(range(0 18) titlegap(1)) xlab(0(2)18, labsize(vsmall)) xtitle("{bf}Miscarriage (%)", size(vsmall)) ///
	graphregion(color(white) lcolor(black)) plotregion(margin(0 0 0 0)) name(risk, replace) ///
	fysize(100) fxsize(40)
	
	/*(bar risk row if row==1, horiz fintensity(inten50) barwidth(0.65)) ///
	text(12.5 0 "{bf}`risk0_f'%", color(black) size(tiny)) text(12 0 "(`lci0_f'-`uci0_f'%)", color(black) size(tiny)) ///
	text(12.5 1 "{bf}`risk1_f'%", color(black) size(tiny)) text(12 1 "(`lci1_f'-`uci1_f'%)", color(black) size(tiny)) /// */
	
	* Combine the graphs to make the primary figure
	graph combine hr_chunk risk, title("{bf}First trimester antidepressant use and miscarriage: adjusted relative and absolute risk", size(small)) imargin(tiny) name(primary_fig, replace)
	
	graph export primary_fig_final.pdf, replace

********************************************************************************	
	
* Stop logging

	log close primary_figure
	
	translate "$Logdir\3_figures\3_primary figure.smcl" "$Logdir\3_figures\3_primary figure.pdf", replace
	
	erase "$Logdir\3_figures\3_primary figure.smcl"
	
********************************************************************************
