clear all
set more off

use "$data_int/FEARS_daily_2019_2021.dta", clear
append using "$data_int/FEARS_daily_2022.dta"
append using "$data_int/FEARS_daily_2023_2024.dta"

sort date

duplicates list date
duplicates drop date, force
save "$data_int/FEARS_daily_2019_2024.dta", replace

clear all

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2024.dta", keep(match) nogenerate

drop query SVI dSVI dASVI 

* Keep one row per trading day (vwretd etc are identical across tics anyway)
sort date tic
by date: keep if _n==1

* Create a gap-free trading-day index
sort date
gen long t = _n
tsset t

*===============================================================================
* SECTION 1: GENERATE VARIABLES
*===============================================================================

* Forward returns
gen sprtrn_f1   = F.sprtrn
gen sprtrn_f2   = F2.sprtrn
gen sprtrn_f1f2 = sprtrn_f1 + sprtrn_f2

* Lagged returns
forvalues i = 1/5 {
    gen sprtrn_L`i' = L`i'.sprtrn
}

* Control variable changes
gen d_epu    = D.epu
gen d_ads    = D.ads
gen vix_L1   = L.vix
gen ln_vix   = ln(vix)
gen d_ln_vix = D.ln_vix

* Drop missing
drop if missing(sprtrn_f1) | missing(FEARS) | missing(vix) | ///
       missing(d_epu) | missing(d_ads) | missing(sprtrn_L5)

* VIX summary by subperiod
di _n "=== VIX Summary by Subperiod ==="
sum vix if year(date) >= 2019 & year(date) <= 2021
sum vix if year(date) == 2022
sum vix if year(date) >= 2023 & year(date) <= 2024

********************************************************************************
* VIX ANALYSIS BATTERY: EVERYTHING ON THE WALL
*
* Starting point: your daily dataset is already loaded, collapsed to
* one obs per trading day, with FEARS, returns, controls, and VIX.
* Run your standard data prep code first, then run this.
********************************************************************************

*===============================================================================
* PART 1: BASIC OLS — FEARS PREDICTING VIX CHANGES
*===============================================================================
* This is the simplest version of Da et al. Section 4
* ΔlogVIX_{t+k} = α + β·FEARS_t + controls + ε

* Generate VIX variables
gen d_vix      = D.vix                // raw VIX change
gen d_vix_f1   = F.d_vix              // next-day VIX change
gen d_vix_f2   = F2.d_vix             // t+2 VIX change
gen d_vix_f1f2 = d_vix_f1 + d_vix_f2  // cumulative 2-day

gen d_ln_vix_f1   = F.d_ln_vix
gen d_ln_vix_f2   = F2.d_ln_vix
gen d_ln_vix_f1f2 = d_ln_vix_f1 + d_ln_vix_f2

* Lagged VIX changes for controls
forvalues i = 1/5 {
    gen d_ln_vix_L`i' = L`i'.d_ln_vix
}

di _n "================================================================"
di "PART 1: OLS — FEARS AND ΔlogVIX"
di "================================================================"

di _n "--- Full sample ---"
foreach k in 0 1 2 {
    if `k' == 0 local dep d_ln_vix
    if `k' == 1 local dep d_ln_vix_f1
    if `k' == 2 local dep d_ln_vix_f1f2
    
    quietly reg `dep' FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, robust
    di "k=`k': b = " %9.4f _b[FEARS] "  se = " %9.4f _se[FEARS] ///
       "  t = " %6.2f _b[FEARS]/_se[FEARS] ///
       "  p = " %6.4f 2*ttail(e(df_r), abs(_b[FEARS]/_se[FEARS])) ///
       "  N = " e(N)
}

di _n "--- 2019-2021 ---"
foreach k in 0 1 2 {
    if `k' == 0 local dep d_ln_vix
    if `k' == 1 local dep d_ln_vix_f1
    if `k' == 2 local dep d_ln_vix_f1f2
    
    quietly reg `dep' FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads ///
        if year(date) >= 2019 & year(date) <= 2021, robust
    di "k=`k': b = " %9.4f _b[FEARS] "  se = " %9.4f _se[FEARS] ///
       "  t = " %6.2f _b[FEARS]/_se[FEARS] ///
       "  p = " %6.4f 2*ttail(e(df_r), abs(_b[FEARS]/_se[FEARS])) ///
       "  N = " e(N)
}

di _n "--- 2022 ---"
foreach k in 0 1 2 {
    if `k' == 0 local dep d_ln_vix
    if `k' == 1 local dep d_ln_vix_f1
    if `k' == 2 local dep d_ln_vix_f1f2
    
    quietly reg `dep' FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads ///
        if year(date) == 2022, robust
    di "k=`k': b = " %9.4f _b[FEARS] "  se = " %9.4f _se[FEARS] ///
       "  t = " %6.2f _b[FEARS]/_se[FEARS] ///
       "  p = " %6.4f 2*ttail(e(df_r), abs(_b[FEARS]/_se[FEARS])) ///
       "  N = " e(N)
}

di _n "--- 2023-2024 ---"
foreach k in 0 1 2 {
    if `k' == 0 local dep d_ln_vix
    if `k' == 1 local dep d_ln_vix_f1
    if `k' == 2 local dep d_ln_vix_f1f2
    
    quietly reg `dep' FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads ///
        if year(date) >= 2023 & year(date) <= 2024, robust
    di "k=`k': b = " %9.4f _b[FEARS] "  se = " %9.4f _se[FEARS] ///
       "  t = " %6.2f _b[FEARS]/_se[FEARS] ///
       "  p = " %6.4f 2*ttail(e(df_r), abs(_b[FEARS]/_se[FEARS])) ///
       "  N = " e(N)
}


*===============================================================================
* PART 2: ARFIMA(1,d,1) ON LOG VIX LEVEL
*===============================================================================
* This replicates Da et al. Table 6 Panel A
* VIX is persistent and long-memory, so ARFIMA captures fractional integration
*
* Model: (1-L)^d (adj_vix_t - β₁·FEARS_t - controls) = (1+θL)·ε_t / (1-φL)


di _n "================================================================"
di "PART 2: ARFIMA(1,d,1) ON SEASONALLY ADJUSTED LOG VIX"
di "================================================================"

* Deseasonalize log VIX (remove day-of-week and month effects)
gen dow = dow(date)
gen month = month(date)

quietly reg ln_vix i.dow i.month
predict adj_ln_vix, resid

* Lags of FEARS
gen FEARS_L1 = L.FEARS
gen FEARS_L2 = L2.FEARS

*--------------------------------------
* Full sample
*--------------------------------------
di _n "--- ARFIMA: Full sample, contemporaneous FEARS ---"
arfima adj_ln_vix FEARS d_epu d_ads, ar(1) ma(1)

di _n "--- ARFIMA: Full sample, FEARS(t-1) ---"
arfima adj_ln_vix FEARS_L1 d_epu d_ads, ar(1) ma(1)

di _n "--- ARFIMA: Full sample, FEARS(t-2) ---"
arfima adj_ln_vix FEARS_L2 d_epu d_ads, ar(1) ma(1)


*===============================================================================
* PART 3: ARFIMA BY SUBPERIOD
*===============================================================================

di _n "================================================================"
di "PART 3: ARFIMA BY SUBPERIOD"
di "================================================================"

di _n "--- 2019-2021: Contemporaneous ---"
capture arfima adj_ln_vix FEARS d_epu d_ads if year(date) >= 2019 & year(date) <= 2021, ar(1) ma(1)

di _n "--- 2019-2021: Lagged ---"
capture arfima adj_ln_vix FEARS_L1 d_epu d_ads if year(date) >= 2019 & year(date) <= 2021, ar(1) ma(1)

di _n "--- 2022: Contemporaneous ---"
capture arfima adj_ln_vix FEARS d_epu d_ads if year(date) == 2022, ar(1) ma(1)

di _n "--- 2022: Lagged ---"
capture arfima adj_ln_vix FEARS_L1 d_epu d_ads if year(date) == 2022, ar(1) ma(1)

di _n "--- 2023-2024: Contemporaneous ---"
capture arfima adj_ln_vix FEARS d_epu d_ads if year(date) >= 2023 & year(date) <= 2024, ar(1) ma(1)

di _n "--- 2023-2024: Lagged ---"
capture arfima adj_ln_vix FEARS_L1 d_epu d_ads if year(date) >= 2023 & year(date) <= 2024, ar(1) ma(1)


*===============================================================================
* PART 4: LOGIT/PROBIT — FEARS PREDICTING VIX SPIKES
*===============================================================================
* Does today's FEARS predict a large VIX increase tomorrow?

di _n "================================================================"
di "PART 4: LOGIT/PROBIT — FEARS PREDICTING VIX JUMPS"
di "================================================================"

* Define VIX spike: top decile of daily VIX increases
quietly sum d_vix, detail
local spike_p90 = r(p90)
local spike_p75 = r(p75)
di "VIX spike cutoffs — p75: `spike_p75'  p90: `spike_p90'"

* Next-day VIX spike indicators
gen byte vix_spike_90_f1 = (d_vix_f1 > `spike_p90') if !missing(d_vix_f1)
gen byte vix_spike_75_f1 = (d_vix_f1 > `spike_p75') if !missing(d_vix_f1)

* Same-day VIX spike (for reference)
gen byte vix_spike_90 = (d_vix > `spike_p90') if !missing(d_vix)
gen byte vix_spike_75 = (d_vix > `spike_p75') if !missing(d_vix)

tab vix_spike_90_f1
tab vix_spike_75_f1

* ── Logit: contemporaneous (does FEARS coincide with VIX spikes?) ──
di _n "--- Logit: FEARS → same-day VIX spike (p90) ---"
logit vix_spike_90 FEARS d_ln_vix_L1-d_ln_vix_L3 d_epu d_ads, robust
estimates store logit_contemp_90

di _n "--- Marginal effects ---"
margins, dydx(FEARS) atmeans

* ── Logit: next-day prediction ──
di _n "--- Logit: FEARS → next-day VIX spike (p90) ---"
logit vix_spike_90_f1 FEARS d_ln_vix_L1-d_ln_vix_L3 d_epu d_ads, robust
estimates store logit_f1_90

di _n "--- Marginal effects ---"
margins, dydx(FEARS) atmeans

* ── Logit: next-day with p75 cutoff (more events, more power) ──
di _n "--- Logit: FEARS → next-day VIX spike (p75) ---"
logit vix_spike_75_f1 FEARS d_ln_vix_L1-d_ln_vix_L3 d_epu d_ads, robust
estimates store logit_f1_75

di _n "--- Marginal effects ---"
margins, dydx(FEARS) atmeans

* ── Probit: same tests ──
di _n "--- Probit: FEARS → next-day VIX spike (p90) ---"
probit vix_spike_90_f1 FEARS d_ln_vix_L1-d_ln_vix_L3 d_epu d_ads, robust

di _n "--- Marginal effects ---"
margins, dydx(FEARS) atmeans

* ── Logit by subperiod ──
di _n "--- Logit by subperiod: FEARS → same-day VIX spike (p90) ---"

di _n "  2019-2021:"
capture logit vix_spike_90 FEARS d_ln_vix_L1-d_ln_vix_L3 d_epu d_ads ///
    if year(date) >= 2019 & year(date) <= 2021, robust
if _rc == 0 margins, dydx(FEARS) atmeans

di _n "  2022:"
capture logit vix_spike_90 FEARS d_ln_vix_L1-d_ln_vix_L3 d_epu d_ads ///
    if year(date) == 2022, robust
if _rc == 0 margins, dydx(FEARS) atmeans

di _n "  2023-2024:"
capture logit vix_spike_90 FEARS d_ln_vix_L1-d_ln_vix_L3 d_epu d_ads ///
    if year(date) >= 2023 & year(date) <= 2024, robust
if _rc == 0 margins, dydx(FEARS) atmeans


*===============================================================================
* PART 5: OLS ON RAW VIX CHANGES (SIMPLER ALTERNATIVE TO ARFIMA)
*===============================================================================
* If ARFIMA gives you trouble, this is the fallback

di _n "================================================================"
di "PART 5: OLS ON ΔlogVIX WITH LAGGED ΔlogVIX CONTROLS"
di "================================================================"

di _n "--- Full sample: contemporaneous ---"
reg d_ln_vix FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, robust

di _n "--- Full sample: does FEARS predict next-day ΔlogVIX? ---"
reg d_ln_vix_f1 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, robust

di _n "--- Full sample: does FEARS predict 2-day cumulative ΔlogVIX? ---"
reg d_ln_vix_f1f2 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, robust


*===============================================================================
* PART 6: GRANGER CAUSALITY VAR
*===============================================================================

di _n "================================================================"
di "PART 6: GRANGER CAUSALITY — FEARS ↔ ΔlogVIX"
di "================================================================"

* Lag order selection
varsoc d_ln_vix FEARS, maxlag(10)

* Estimate VAR (adjust lag if varsoc suggests different)
var d_ln_vix FEARS, lags(1/5)
vargranger


*===============================================================================
* PART 7: QUANTILE REGRESSION ON VIX CHANGES
*===============================================================================
* Does FEARS predict VIX changes differently at different quantiles?

di _n "================================================================"
di "PART 7: QUANTILE REGRESSION — FEARS AND ΔlogVIX"
di "================================================================"

di _n "--- Contemporaneous: FEARS → ΔlogVIX at different quantiles ---"
foreach tau in 0.10 0.25 0.50 0.75 0.90 {
    quietly qreg d_ln_vix FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, quantile(`tau')
    di "tau = `tau':  b = " %9.4f _b[FEARS] "  se = " %9.4f _se[FEARS] ///
       "  p = " %6.4f 2*ttail(e(df_r), abs(_b[FEARS]/_se[FEARS]))
}

di _n "--- Next-day: FEARS → ΔlogVIX_{t+1} at different quantiles ---"
foreach tau in 0.10 0.25 0.50 0.75 0.90 {
    quietly qreg d_ln_vix_f1 FEARS d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, quantile(`tau')
    di "tau = `tau':  b = " %9.4f _b[FEARS] "  se = " %9.4f _se[FEARS] ///
       "  p = " %6.4f 2*ttail(e(df_r), abs(_b[FEARS]/_se[FEARS]))
}


*===============================================================================
* PART 8: FEARS ASYMMETRY (BONUS — quick to run)
*===============================================================================
* Do fear INCREASES and DECREASES have different effects?

di _n "================================================================"
di "PART 8: ASYMMETRIC FEARS — POSITIVE VS NEGATIVE"
di "================================================================"

gen FEARS_pos = max(FEARS, 0)
gen FEARS_neg = min(FEARS, 0)

di _n "--- Contemporaneous return: asymmetric FEARS ---"
reg sprtrn FEARS_pos FEARS_neg sprtrn_L1-sprtrn_L5 d_epu d_ads vix, robust
test FEARS_pos = FEARS_neg

di _n "--- Next-day return: asymmetric FEARS ---"
reg sprtrn_f1 FEARS_pos FEARS_neg sprtrn sprtrn_L1-sprtrn_L5 d_epu d_ads vix, robust
test FEARS_pos = FEARS_neg

di _n "--- Contemporaneous ΔlogVIX: asymmetric FEARS ---"
reg d_ln_vix FEARS_pos FEARS_neg d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, robust
test FEARS_pos = FEARS_neg

di _n "--- Next-day ΔlogVIX: asymmetric FEARS ---"
reg d_ln_vix_f1 FEARS_pos FEARS_neg d_ln_vix_L1-d_ln_vix_L5 d_epu d_ads, robust
test FEARS_pos = FEARS_neg

* By subperiod
di _n "--- Asymmetric FEARS on R_t by subperiod ---"

di _n "  2019-2021:"
quietly reg sprtrn FEARS_pos FEARS_neg sprtrn_L1-sprtrn_L5 d_epu d_ads vix ///
    if year(date) >= 2019 & year(date) <= 2021, robust
di "  pos: b=" %8.4f _b[FEARS_pos] " p=" %6.4f 2*ttail(e(df_r), abs(_b[FEARS_pos]/_se[FEARS_pos])) ///
   "  neg: b=" %8.4f _b[FEARS_neg] " p=" %6.4f 2*ttail(e(df_r), abs(_b[FEARS_neg]/_se[FEARS_neg]))
test FEARS_pos = FEARS_neg

di _n "  2022:"
quietly reg sprtrn FEARS_pos FEARS_neg sprtrn_L1-sprtrn_L5 d_epu d_ads vix ///
    if year(date) == 2022, robust
di "  pos: b=" %8.4f _b[FEARS_pos] " p=" %6.4f 2*ttail(e(df_r), abs(_b[FEARS_pos]/_se[FEARS_pos])) ///
   "  neg: b=" %8.4f _b[FEARS_neg] " p=" %6.4f 2*ttail(e(df_r), abs(_b[FEARS_neg]/_se[FEARS_neg]))
test FEARS_pos = FEARS_neg

di _n "  2023-2024:"
quietly reg sprtrn FEARS_pos FEARS_neg sprtrn_L1-sprtrn_L5 d_epu d_ads vix ///
    if year(date) >= 2023 & year(date) <= 2024, robust
di "  pos: b=" %8.4f _b[FEARS_pos] " p=" %6.4f 2*ttail(e(df_r), abs(_b[FEARS_pos]/_se[FEARS_pos])) ///
   "  neg: b=" %8.4f _b[FEARS_neg] " p=" %6.4f 2*ttail(e(df_r), abs(_b[FEARS_neg]/_se[FEARS_neg]))
test FEARS_pos = FEARS_neg


di _n "================================================================"
di "DONE. Review output above and identify significant results."
di "================================================================"
