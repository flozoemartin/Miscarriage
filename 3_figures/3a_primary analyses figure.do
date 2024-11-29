********************************************************************************

  * Primary analyses and absolute risk figure: primary Cox models, exposure discordant pregnancy analysis, and propensity score matched analysis on the left-hand panel. Absolute risk adjusted for confounders bar chart on the right-hand panel

  * Author: Flo Martin

  * Date: 12/11/2024

********************************************************************************

* Load in the data and prepare for use in twoway

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
	
	keep if seq<13
	
	* Macros to create the null line
	local t1=1.2
	local t2=13
	
	replace unadj_or=10 if unadj_or==.
	replace unadj_lci=10 if unadj_lci==.
	replace unadj_uci=10 if unadj_uci==.

* To allow the loops to run
  
	replace or=10 if or==.
	replace lci=10 if lci==.
	replace uci=10 if uci==.

* Creating macros for filling in the figures
	
	forvalues x=3/12 {
		foreach y in unadj_or unadj_lci unadj_uci or lci uci {
		
			sum `y' if seq==`x'
			local `y'_`x' = `r(mean)'
			local `y'_`x'_f : display %4.2fc ``y'_`x'' 
			
		}		
	}
	
	forvalues x=3/12 {
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
	
	forvalues x=3/12 {
	
		local total_exp_`x' = nn[`x']
		di "`total_exp_`x''"
		
	}
	
	set scheme tab2
	
	twoway ///
	(scatteri `t1' 1 `t2' 1, recast(line) yaxis(1) lpatter(dash) lcolor(cranberry)) /// null line
	(rcap unadj_lci unadj_uci seq if unadj_or!=1, horizontal lcolor(gs12)) /// code for 95% CI
	(scatter seq unadj_or if unadj_or!=1, mcolor(gs12) ms(o) msize(medium) mlcolor(gs12) mlw(thin)) ///
	(rcap lci uci seq, horizontal lcolor(black)) /// code for NO 95% CI
	(scatter seq or, mcolor("85 119 135") ms(o) msize(medium) mlcolor(black) mlw(thin)), ///
	text(0.6 0.4 "{bf:Analytical}" "{bf:approach}", size(*0.65) justification(left) placement(e)) text(0.6 0.79 "{bf:Miscarriage / Total}" "{it:n} / N (%)", size(*0.65) justification(left) placement(w)) text(0.6 2.05 "{bf:Unadjusted HR}", size(*0.65) justification(left) placement(e) color(gs10)) text(0.6 2.8 "{bf:Adjusted HR}", size(*0.65) justification(left) placement(e)) ///
	text(2 0.4 "{bf:Primary analysis*}", size(*0.65) justification(left) placement(e)) ///
		text(3 0.4 "Unexposed", size(*0.65) justification(left) placement(e)) ///
	text(3 0.79 "`total_exp_3'", size(*0.65) justification(right) placement(w)) ///
	text(3 2.05 "1.00 (reference)", size(*0.65) justification(left) placement(e) color(gs10)) ///
	text(3 2.8 "1.00 (reference)", size(*0.65) justification(left) placement(e)) ///
	text(4 0.4 "Exposed", size(*0.65) justification(left) placement(e)) ///
	text(4 0.79 "`total_exp_4'", size(*0.65) justification(right) placement(w)) ///
	text(4 2.05 "`unadj_or_4_f' (`unadj_lci_4_f' – `unadj_uci_4_f')", size(*0.65) justification(left) placement(e) color(gs10)) ///
	text(4 2.8 "`or_4_f' (`lci_4_f' – `uci_4_f')", size(*0.65) justification(left) placement(e)) ///
	text(6 0.42 "{bf:Exposure discordant analysis{sup:†}}", size(*0.65) justification(left) placement(e)) ///
		text(7 0.42 "Unexposed", size(*0.65) justification(left) placement(e)) ///
	text(7 0.79 "`total_exp_7'", size(*0.65) justification(right) placement(w)) ///
	text(7 2.05 "1.00 (reference)", size(*0.65) justification(left) placement(e) color(gs10)) ///
	text(7 2.8 "1.00 (reference)", size(*0.65) justification(left) placement(e)) ///
	text(8 0.42 "Exposed", size(*0.65) justification(left) placement(e)) ///
	text(8 0.79 "`total_exp_8'", size(*0.65) justification(right) placement(w)) ///
	text(8 2.05 "`unadj_or_8_f' (`unadj_lci_8_f' – `unadj_uci_8_f')", size(*0.65) justification(left) placement(e) color(gs10)) ///
	text(8 2.8 "`or_8_f' (`lci_8_f' – `uci_8_f')", size(*0.65) justification(left) placement(e)) ///
	text(10 0.42 "{bf:Propensity score analysis{sup:‡}}", size(*0.65) justification(left) placement(e)) ///
		text(11 0.42 "Unexposed", size(*0.65) justification(left) placement(e)) ///
	text(11 0.79 "`total_exp_11'", size(*0.65) justification(right) placement(w)) ///
	text(11 2.05 "1.00 (reference)", size(*0.65) justification(left) placement(e) color(gs10)) ///
	text(11 2.8 "1.00 (reference)", size(*0.65) justification(left) placement(e)) ///
	text(12 0.42 "Exposed", size(*0.65) justification(left) placement(e)) ///
	text(12 0.79 "`total_exp_12'", size(*0.65) justification(right) placement(w)) ///
	text(12 2.05 "–", size(*0.65) justification(left) placement(e) color(gs10)) ///
	text(12 2.8 "`or_12_f' (`lci_12_f' – `uci_12_f')", size(*0.65) justification(left) placement(e)) ///
	text(14.5 0.4 "*Adjusted for maternal age, pregnancy year, practice-level IMD quintile, history of miscarriage, smoking status around the start of pregnancy, parity at the start of" "pregnancy, use of high dose folic acid, antipsychotics, or anti-seizure medication in the 12 months before pregnancy, number of primary care consultations in the" "12 months before pregnancy, and severe mental illness, depression or anxiety ever before the start of pregnancy", size(*0.45) justification(left) placement(e)) ///
	text(15.1 0.4 "{sup:†}Primary analysis adjustment set with history of miscarriage dropped", size(*0.45) justification(left) placement(e)) ///
	text(15.75 0.4 "{sup:‡}Primary adjustment set additionally included in the propensity score: area of residence, alcohol use around the start of pregnancy, illicit drug use in the year" "before pregnancy, diabetes, endometriosis, PCOS, teratogen use in the year before pregnancy, other potential antidepressant indications ever before" "pregnancy", size(*0.45) justification(left) placement(e)) ///
	yscale(range(0 12) noline reverse) ylab("", angle(0) labsize(*0.6) notick nogrid nogextend) ///
	xscale(range(0.39(0.2)3.8) log titlegap(1)) xlabel(0.8(0.2)2, labsize(vsmall) format(%3.1fc) ) xtitle("{bf}Hazard ratio (95% confidence interval)", size(vsmall)) ///
	legend(order(3 "Unadjusted" 5 "Adjusted") pos(5) col(1) region(lcolor(black))) ///
	yline(0) yline(1.2) yline(5, lcolor(gray) lpattern(dot)) yline(9, lcolor(gray) lpattern(dot)) ///
	plotregion(margin(0 0 0 0)) name(hr_chunk, replace)
	
	use "$Graphdir\marginal risk.dta", clear
	
	gen row=3 if x=="Unexposed"
	replace row=4 if row==.
	
	drop x
	
	foreach y in risk lci uci {
		foreach x in 3 4 {
		
			sum `y' if row==`x'
			local `y'`x' = `r(mean)'
			local `y'`x'_f : display %4.1fc ``y'`x'' 
		
		}
	}

	*replace row=2.75 if row==2
	*replace row=3.75 if row==3
	
	*set scheme white_w3d
	
	* Make the bar chart of marginal risk
	twoway ///
	(bar risk row, fcolor("85 119 135") lcolor("85 119 135") horiz barwidth(0.75)) ///
	(rcap lci uci row, horiz lcolor(black)), ///
	text(0.6 0.4 "{bf}Absolute risk of miscarriage adjusted* for" "{bf}confounders", color(black) box bcolor("white") margin(t+1.5 b+2 r+2) size(*0.65) justification(left) placement(e)) ///
	text(3 0.25 "{bf}`risk3_f'%", color(black) size(*0.65) justification(left) placement(e)) text(3 2.75 "(`lci3_f' – `uci3_f'%)", color(black) size(*0.65) justification(left) placement(e)) ///
	text(4 0.25 "{bf}`risk4_f'%", color(black) size(*0.65) justification(left) placement(e)) text(4 2.75 "(`lci4_f' – `uci4_f'%)", color(black) size(*0.65) justification(left) placement(e)) ///
	yline(0) yline(1.2) yline(5, lcolor(gray) lpattern(dot)) yline(9, lcolor(gray) lpattern(dot)) ///
	legend(label(1 "Adjusted* risk") label(2 "Bootstrapped 95% CI") order(1 2) col(1) pos(6) region(lcolor(black))) ///
	yscale(range(0 13) titlegap(5) reverse off) ylab(0 "U" 12 "E", labsize(vsmall) nogrid labcolor(white) notick) ytitle("") ///
	xscale(range(0 18) titlegap(1)) xlab(0(2)18, labsize(vsmall) ) xtitle("{bf}Miscarriage (%)", size(vsmall)) ///
	graphregion(color(white) lcolor(black)) plotregion(margin(0 0 0 0)) name(risk, replace) ///
	fysize(100) fxsize(40)
	
	* Combine the graphs to make the primary figure
	graph combine hr_chunk risk, title("{bf}First trimester antidepressant use and miscarriage" "adjusted relative and absolute risks from primary analyses", size(small)) imargin(tiny) name(primary_fig, replace)

	graph export "C:\Users\ti19522\OneDrive - University of Bristol\Flo Martin Supervisory Team\Year 4\5_Miscarriage\ch5_primary_fig.pdf", replace
