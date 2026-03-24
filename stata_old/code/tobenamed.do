clear all
set more off

use "$data_int/FEARS_daily_2019_2021.dta", clear
append using "$data_int/FEARS_daily_2022.dta"
append using "$data_int/FEARS_daily_2023_2024.dta"

sort date

duplicates list date
duplicates drop date, force
save "$data_int/FEARS_daily_2019_2024.dta", replace

******
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


gen period = .
replace period = 0 if inrange(year(date), 2019, 2021)
replace period = 1 if year(date) == 2022
replace period = 2 if inrange(year(date), 2023, 2024)

label define periodlbl 0 "2019-2021" 1 "2022" 2 "2023-2024"
label values period periodlbl

tab period, missing

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn ib0.period##c.FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix, robust

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 ib0.period##c.FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix, robust


//baseline
bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust


//forward 1 day
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust 


//cumulative
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
