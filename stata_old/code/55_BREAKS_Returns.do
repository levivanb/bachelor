clear all
set more off

use "$data_int/FEARS_daily_2019_2021.dta", clear
append using "$data_int/FEARS_daily_2022.dta"
append using "$data_int/FEARS_daily_2023_2024.dta"

sort date

duplicates list date
duplicates drop date, force
save "$data_int/FEARS_daily_2019_2024.dta", replace

******INTERACTION******
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

summ FEARS

* Leads (next trading day)
gen ret_fwd_1 = F1.sprtrn
gen ret_fwd_2 = F2.sprtrn
gen ret_fwd_3 = F3.sprtrn
gen ret_fwd_4 = F4.sprtrn
gen ret_fwd_5 = F5.sprtrn

* Cumulative: Ret[t+1, t+2]
gen ret_fwd_cum_2 = F1.sprtrn + F2.sprtrn

* Lags (previous trading days)
gen L1_ret = L1.sprtrn
gen L2_ret = L2.sprtrn
gen L3_ret = L3.sprtrn
gen L4_ret = L4.sprtrn
gen L5_ret = L5.sprtrn

*Deltas for controls
gen d_epu = D.epu
gen d_ads = D.ads

**BP TEST**

tab period, missing

xtbreak test sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, ///
    hypothesis(2) breaks(1 3)

xtbreak estimate sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, ///
  breaks(2)
   
 list t date if t==208 | t==818, noobs
format date %td


**REGRESSIONS WITH NEW BP**
gen bp_period = .
replace bp_period = 0 if date <= td(28oct2020)
replace bp_period = 1 if inrange(date, td(29oct2020), td(05apr2023))
replace bp_period = 2 if date >= td(06apr2023)

label define bp_lbl 0 "Start--28 Oct 2020" ///
                    1 "29 Oct 2020--5 Apr 2023" ///
                    2 "6 Apr 2023--End"
label values bp_period bp_lbl

tab bp_period, missing


reg ret_fwd_1 FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix ///
    if bp_period==0, robust
est sto bp1

reg ret_fwd_1 FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix ///
    if bp_period==1, robust
est sto bp2

reg ret_fwd_1 FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix ///
    if bp_period==2, robust
est sto bp3
