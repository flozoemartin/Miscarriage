*********************************************************************************

* Exposure discordant pregnancy analysis sensitivity analysis figure

* Author: Flo Martin

* Date: 25/09/2024

*********************************************************************************

* Figure 3 - Exposure discordant pregnancy sensitivity analysis, restricting first to exposure discordant groups where the first pregnancy was antidepressant exposed and subsequent pregnancies in the group were not, then to groups where subsequent pregnancies were exposed to antidepressants but first pregnancies in the group were not.

*********************************************************************************

* Start logging

  log using "$Logdir\3_figures\4_exposure discord sens", name(exposure_discord_sens) replace

*********************************************************************************

  import delimited using "$Tabledir\supp_exposure discordant sens.txt", varnames(1) clear

	drop if nn==""
	egen seq=seq()
	
	keep nn seq
	
	save "$Graphdir\exposure discordant sens counts.dta", replace

	import delimited using "$Graphdir\discordant supp results fig data.txt", clear
	
	egen seq=seq()
	
	format misc %5.0fc
	format total %6.0fc
	format pct %4.1fc
	
	merge 1:1 seq using "$Graphdir\exposure discordant sens counts.dta", nogen
	
	replace nn = subinstr(nn, " ", "", .)
	replace nn = subinstr(nn, "/", " / ", .)
	replace nn = subinstr(nn, "(", " (", .)
	
	replace model = "discordant_first0" if seq==1
	replace model = "discordant_first1" if seq==2
	replace model = "discordant_subseq0" if seq==3
	replace model = "discordant_subseq1" if seq==4
	
	local y = 1
	
	foreach var in discordant_first discordant_subseq {
		
		set obs `=_N+1'
		replace model = "a_`var'" if model==""
		replace seq = `y' if regexm(model, "`var'")
		
		local y = `y' + 1
		
	}
	
	foreach var in discordant_first discordant_subseq {
		
		set obs `=_N+1'
		replace model = "a_`var'" if model==""
		replace seq = `y' if regexm(model, "`var'")
		
		local y = `y' + 1
		
	}
	
	sort seq model
	
	drop seq
	egen seq=seq() 
	
	gen logor = log(or)
	gen loglci = log(lci)
	gen loguci = log(uci)
	
	replace unadj_or=10 if unadj_or==.
	replace unadj_lci=10 if unadj_lci==.
	replace unadj_uci=10 if unadj_uci==.

	replace or=10 if or==.
	replace lci=10 if lci==.
	replace uci=10 if uci==.
	
	forvalues x=3/8 {
		foreach y in unadj_or unadj_lci unadj_uci or lci uci {
		
			sum `y' if seq==`x'
			local `y'_`x' = `r(mean)'
			local `y'_`x'_f : display %4.2fc ``y'_`x'' 
			
		}		
	}
	
	forvalues x=3/8 {
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
	
	forvalues x=3/8 {
	
		local total_exp_`x' = nn[`x']
		di "`total_exp_`x''"
		
	}
	
	* Macros to create the null line
	local t1=1
	local t2=9
	
	twoway ///
	(scatteri `t1' 1 `t2' 1, recast(line) yaxis(1) lpatter(dash) lcolor(cranberry)) /// null line
	(rcap unadj_lci unadj_uci seq if unadj_or!=1, horizontal lcolor(gs12)) /// code for NO 95% CI
	(scatter seq unadj_or if unadj_or!=1, mcolor(gs12) ms(o) msize(medium) mlcolor(gs12) mlw(thin)) ///
	(rcap lci uci seq, horizontal lcolor(black)) /// code for NO 95% CI
	(scatter seq or, mcolor("85 119 135") ms(o) msize(medium) mlcolor(black) mlw(thin)), ///
	text(0.5 0.4 "{bf:Exposure order}", size(*0.5) justification(left) placement(e)) text(0.5 0.79 "{bf:Miscarriage n / Total N (%)}", size(*0.5) justification(left) placement(w)) text(0.5 2.3 "{bf:Unadjusted HR}", size(*0.5) justification(left) placement(e) color(gs10)) text(0.5 3 "{bf:Adjusted** HR}", size(*0.5) justification(left) placement(e)) ///
	text(2 0.4 "{bf:First pregnancy in the group exposed}", size(*0.5) justification(left) placement(e)) ///
		text(3 0.4 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(3 0.79 "`total_exp_3'", size(*0.5) justification(right) placement(w)) ///
	text(3 2.3 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(3 3 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(4 0.4 "Exposed", size(*0.5) justification(left) placement(e)) ///
	text(4 0.79 "`total_exp_4'", size(*0.5) justification(right) placement(w)) ///
	text(4 2.3 "`unadj_or_4_f' (`unadj_lci_4_f' – `unadj_uci_4_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(4 3 "`or_4_f' (`lci_4_f' – `uci_4_f')", size(*0.5) justification(left) placement(e)) ///
	text(6 0.4 "{bf:Subsequent pregnancy in the group exposed}", size(*0.5) justification(left) placement(e)) ///
		text(7 0.4 "Unexposed", size(*0.5) justification(left) placement(e)) ///
	text(7 0.79 "`total_exp_7'", size(*0.5) justification(right) placement(w)) ///
	text(7 2.3 "1.00 (reference)", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(7 3 "1.00 (reference)", size(*0.5) justification(left) placement(e)) ///
	text(8 0.4 "Exposed", size(*0.5) justification(left) placement(e)) ///
	text(8 0.79 "`total_exp_8'", size(*0.5) justification(right) placement(w)) ///
	text(8 2.3 "`unadj_or_8_f' (`unadj_lci_8_f' – `unadj_uci_8_f')", size(*0.5) justification(left) placement(e) color(gs10)) ///
	text(8 3 "`or_8_f' (`lci_8_f' – `uci_8_f')", size(*0.5) justification(left) placement(e)) ///
	yscale(range(0 9) noline reverse) ylab("", angle(0) labsize(*0.6) notick nogrid nogextend) ///
	xscale(range(0.4(0.2)3.8) log titlegap(1)) xlabel(0.8(0.2)2.2, labsize(vsmall) format(%3.1fc)) xtitle("{bf}Hazard ratio (95% confidence interval)", size(vsmall)) ///
	title("{bf}Exposure discordant pregnancy sensitivity analysis", size(small)) ///
	legend(order(3 "Unadjusted" 5 "Adjusted") pos(6) col(2)) ///
	yline(0) yline(1) yline(5, lcolor(gray) lpattern(dot)) ///
	plotregion(margin(0 0 0 0)) name(figure_3, replace) ///
	fxsize(150) fysize(75)
	
	graph export figure_3.pdf, replace

*********************************************************************************

* Stop logging
		
	log close exposure_discord_sens
	
	translate "$Logdir\3_figures\4_exposure discord sens.smcl" "$Logdir\3_figures\4_exposure discord sens.pdf", replace
	
	erase "$Logdir\3_figures\4_exposure discord sens.smcl"

*********************************************************************************
