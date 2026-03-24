********************************************************************************
* VOLATILITY ANALYSIS: ARFIMA + OLS (Newey-West) + DCC-GARCH
********************************************************************************

clear all
set more off

use "$data_int/FEARS_daily_2019_2021.dta", clear
append using "$data_int/FEARS_daily_2022.dta"
append using "$data_int/FEARS_daily_2023_2024.dta"
sort date
duplicates drop date, force
save "$data_int/FEARS_daily_2019_2024.dta", replace

clear all
use "$data_int/mrkt_google_controls.dta", clear
merge m:1 date using "$data_int/FEARS_daily_2019_2024.dta", keep(match) nogenerate
drop query SVI dSVI dASVI
sort date tic
by date: keep if _n == 1
sort date
gen long t = _n
tsset t

*===============================================================================
* VARIABLE CONSTRUCTION
*===============================================================================

gen ln_vix    = ln(vix)
gen d_ln_vix  = D.ln_vix

gen d_ln_vix_f1   = F.d_ln_vix
gen d_ln_vix_f2   = F2.d_ln_vix
gen d_ln_vix_f1f2 = d_ln_vix_f1 + d_ln_vix_f2

forvalues i = 1/5 {
    gen d_ln_vix_L`i' = L`i'.d_ln_vix
}

gen d_epu = D.epu
gen d_ads = D.ads

gen FEARS_L1 = L.FEARS
gen FEARS_L2 = L2.FEARS

gen dow   = dow(date)
gen month = month(date)
quietly reg ln_vix i.dow i.month
predict adj_ln_vix, resid

drop if missing(d_ln_vix) | missing(FEARS) | missing(d_epu) | ///
       missing(d_ads) | missing(d_ln_vix_L5)

di "Observations: " _N


*===============================================================================
* PART 1: ARFIMA(1,d,1) ON SEASONALLY-ADJUSTED LOG VIX (FULL SAMPLE)
*===============================================================================

di _n "================================================================"
di "PART 1: ARFIMA(1,d,1) ON SEASONALLY-ADJUSTED LOG VIX"
di "================================================================"

di _n "--- ARFIMA: Contemporaneous FEARS ---"
arfima adj_ln_vix FEARS d_epu d_ads, ar(1) ma(1)
estimates store arfima_contemp

di _n "--- ARFIMA: FEARS at t-1 ---"
arfima adj_ln_vix FEARS_L1 d_epu d_ads, ar(1) ma(1)
estimates store arfima_lag1

di _n "--- ARFIMA: FEARS at t-2 ---"
arfima adj_ln_vix FEARS_L2 d_epu d_ads, ar(1) ma(1)
estimates store arfima_lag2

estimates table arfima_contemp arfima_lag1 arfima_lag2, ///
    keep(FEARS FEARS_L1 FEARS_L2) b(%9.4f) se(%9.4f) stats(N ll)

	
esttab arfima_contemp arfima_lag1 arfima_lag2 ///
    using "$data_output/arfima_vix.tex", ///
    replace ///
    booktabs ///
    label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    compress ///
    keep(adj_ln_vix:FEARS adj_ln_vix:FEARS_L1 adj_ln_vix:FEARS_L2 ///
         adj_ln_vix:d_epu adj_ln_vix:d_ads ///
         ARFIMA:L.ar ARFIMA:L.ma ARFIMA:d) ///
    order(adj_ln_vix:FEARS adj_ln_vix:FEARS_L1 adj_ln_vix:FEARS_L2 ///
          ARFIMA:d ARFIMA:L.ar ARFIMA:L.ma ///
          adj_ln_vix:d_epu adj_ln_vix:d_ads) ///
    coeflabels(adj_ln_vix:FEARS "X-FEARS\$_{t}\$" ///
               adj_ln_vix:FEARS_L1 "X-FEARS\$_{t-1}\$" ///
               adj_ln_vix:FEARS_L2 "X-FEARS\$_{t-2}\$" ///
               ARFIMA:d "\$d\$" ///
               ARFIMA:L.ar "AR(1)" ///
               ARFIMA:L.ma "MA(1)" ///
               adj_ln_vix:d_epu "\$\Delta\$EPU" ///
               adj_ln_vix:d_ads "\$\Delta\$ADS") ///
    mtitles("FEARS\$_t\$" "FEARS\$_{t-1}\$" "FEARS\$_{t-2}\$") ///
    stats(N ll, fmt(0 2) labels("Observations" "Log likelihood")) ///
    title("ARFIMA(1,d,1) estimates: X-FEARS and seasonally adjusted log VIX") ///
    alignment(l*{3}{c})
	
	

*===============================================================================
* PART 2: OLS WITH NEWEY-WEST SEs — BY SUBPERIOD
*===============================================================================
* Newey-West standard errors account for heteroskedasticity and
* residual autocorrelation up to the specified bandwidth. This is
* important because OLS with five lags does not fully capture the
* long-memory persistence of VIX, leaving serial dependence in
* the residuals.
*
* Bandwidth rule of thumb: floor(4*(T/100)^(2/9))
*   Full sample (T~1248): lag(10)
*   2019-2021   (T~497):  lag(8)
*   2022        (T~250):  lag(7)
*   2023-2024   (T~500):  lag(8)

* 2019-2021
newey d_ln_vix FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) >= 2019 & year(date) <= 2021, lag(6)
estimates store vix_1_k0
newey d_ln_vix_f1 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) >= 2019 & year(date) <= 2021, lag(6)
estimates store vix_1_k1
newey d_ln_vix_f1f2 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) >= 2019 & year(date) <= 2021, lag(6)
estimates store vix_1_k2

* 2022
newey d_ln_vix FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) == 2022, lag(5)
estimates store vix_2_k0
newey d_ln_vix_f1 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) == 2022, lag(5)
estimates store vix_2_k1
newey d_ln_vix_f1f2 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) == 2022, lag(5)
estimates store vix_2_k2

* 2023-2024
newey d_ln_vix FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) >= 2023 & year(date) <= 2024, lag(6)
estimates store vix_3_k0
newey d_ln_vix_f1 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) >= 2023 & year(date) <= 2024, lag(6)
estimates store vix_3_k1
newey d_ln_vix_f1f2 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads if year(date) >= 2023 & year(date) <= 2024, lag(6)
estimates store vix_3_k2

esttab vix_1_k0 vix_1_k1 vix_1_k2 vix_2_k0 vix_2_k1 vix_2_k2 vix_3_k0 vix_3_k1 vix_3_k2 ///
    using "$data_output/vix_ols_subperiods.tex", ///
    replace ///
    booktabs ///
    label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    compress ///
    keep(FEARS) ///
    mtitles("t" "t+1" "t+1 to t+2" "t" "t+1" "t+1 to t+2" "t" "t+1" "t+1 to t+2") ///
    mgroups("2019--2021" "2022" "2023--2024", pattern(1 0 0 1 0 0 1 0 0) ///
            prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    stats(N, fmt(0) ///
          labels("Observations")) ///
    title("X-FEARS and $\Delta \log$ VIX across subperiods") ///
    alignment(l*{9}{c})
	
**BP TEST**

xtbreak estimate d_ln_vix FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, ///
  breaks(2)

xtbreak test d_ln_vix FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, ///
    hypothesis(2) breaks(1 3)
	
list t date if t==493 | t==1066, noobs

capture drop bp_vix
gen bp_vix = .
replace bp_vix = 0 if date <= td(16dec2021)
replace bp_vix = 1 if date > td(16dec2021) & date <= td(03apr2024)
replace bp_vix = 2 if date > td(03apr2024) & !missing(date)
tab bp_vix, missing

foreach k in 0 1 2 {
    if `k' == 0 local dep d_ln_vix
    if `k' == 1 local dep d_ln_vix_f1
    if `k' == 2 local dep d_ln_vix_f1f2

    forvalues p = 0/2 {
        quietly newey `dep' FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads ///
            if bp_vix==`p', lag(6)
        di "Period `p', k=`k': b = " %9.4f _b[FEARS] ///
           "  se = " %9.4f _se[FEARS] ///
           "  t = " %6.2f _b[FEARS]/_se[FEARS] ///
           "  p = " %6.4f 2*ttail(e(df_r), abs(_b[FEARS]/_se[FEARS])) ///
           "  N = " e(N)
    }
}



	
	
	

*===============================================================================
* PART 3: DCC-GARCH — CONDITIONAL VARIANCE CORRELATION
*===============================================================================

di _n "================================================================"
di "PART 3: DCC-GARCH — FEARS AND MARKET RETURNS"
di "================================================================"

di _n "--- DCC-GARCH(1,1): sprtrn and FEARS ---"
mgarch dcc (sprtrn = d_epu d_ads, noconstant) ///
           (FEARS = , noconstant), ///
    arch(1) garch(1)
estimates store dcc_model

* Extract conditional variances
predict H_sprtrn_sprtrn, variance equation(sprtrn)
predict H_FEARS_FEARS, variance equation(FEARS)

* Correlation between conditional variances (what Da et al. report)
di _n "--- Correlation between conditional variances ---"
pwcorr H_sprtrn_sprtrn H_FEARS_FEARS, sig

* DCC model parameters (includes level correlation)
di _n "--- DCC model parameters ---"
estimates replay dcc_model



* DCC by subperiods* 
foreach period in "1" "2" "3" {

    if "`period'" == "1" local cond "year(date) >= 2019 & year(date) <= 2021"
    if "`period'" == "1" local label "2019-2021"
    if "`period'" == "2" local cond "year(date) == 2022"
    if "`period'" == "2" local label "2022"
    if "`period'" == "3" local cond "year(date) >= 2023 & year(date) <= 2024"
    if "`period'" == "3" local label "2023-2024"

    di _n "--- DCC-GARCH: `label' ---"
    
    capture drop H_s_`period' H_f_`period'
    
    mgarch dcc (sprtrn = d_epu d_ads, noconstant) ///
               (FEARS = , noconstant) ///
        if `cond', arch(1) garch(1)
    
    predict H_s_`period' if `cond', variance equation(sprtrn)
    predict H_f_`period' if `cond', variance equation(FEARS)
    
    di _n "Conditional variance correlation (`label'):"
    pwcorr H_s_`period' H_f_`period', sig
}




di _n "================================================================"
di "DONE."
di "================================================================"
