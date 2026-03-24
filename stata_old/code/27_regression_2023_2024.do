****************************************************
* FEAR AND RETURNS, 2023-2024
****************************************************
clear all

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2023_2024.dta", keep(match) nogenerate

drop query SVI dSVI dASVI 

* Keep one row per trading day (vwretd etc are identical across tics anyway)
sort date tic
by date: keep if _n==1

* Create a gap-free trading-day index
sort date
gen long t = _n
tsset t

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

//baseline
bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust

est sto reg1 
estadd local Controls "Yes"

//forward 1 day
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust 

est sto reg2
estadd local Controls "Yes"

//forward 2 days
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust 

est sto reg3
estadd local Controls "Yes"

//forward 3 days
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_3 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust 

est sto reg4
estadd local Controls "Yes"

//forward 4 days
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_4 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust 

est sto reg5
estadd local Controls "Yes"

//forward 5 days
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_5 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust 

est sto reg6
estadd local Controls "Yes"

//cumulative 1 day
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust

est sto reg7
estadd local Controls "Yes"

//LATEX

* (Optional) Label variables for nicer LaTeX
label var FEARS    "FEARS"



esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 using "$data_output/fears_predictive_regs_2023_2024.tex", ///
    replace ///
    booktabs ///
    label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    compress ///
    mtitles("t" "t+1" "t+2" "t+3" "t+4" "t+5" "t+1 to t+2") ///
    keep(FEARS) ///
    order(FEARS) ///
    stats(Controls N r2, fmt(%9s 0 3) ///
          labels("Controls" "Observations" "R-squared")) ///
    title("FEARS and S\&P 500 returns (2023--2024)") ///
    alignment(l*{7}{c})



