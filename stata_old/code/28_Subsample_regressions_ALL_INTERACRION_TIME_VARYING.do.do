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


gen period = .
replace period = 0 if inrange(year(date), 2019, 2021)
replace period = 1 if year(date) == 2022
replace period = 2 if inrange(year(date), 2023, 2024)

label define periodlbl 0 "2019-2021" 1 "2022" 2 "2023-2024"
label values period periodlbl

tab period, missing

//baseline

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn ib0.period##c.FEARS ///
    ib0.period##c.L1_ret ///
    ib0.period##c.L2_ret ///
    ib0.period##c.L3_ret ///
    ib0.period##c.L4_ret ///
    ib0.period##c.L5_ret ///
    ib0.period##c.d_epu ///
    ib0.period##c.d_ads ///
    ib0.period##c.vix, robust

test 1.period#c.FEARS = 2.period#c.FEARS

est sto reg1 
estadd local Controls "Yes"

// forward 1 day
bootstrap _b, reps(1000) seed(6666): ///
reg ret_fwd_1 ib0.period##c.FEARS ///
    ib0.period##c.vwretd ///
    ib0.period##c.L1_ret ///
    ib0.period##c.L2_ret ///
    ib0.period##c.L3_ret ///
    ib0.period##c.L4_ret ///
    ib0.period##c.L5_ret ///
    ib0.period##c.d_epu ///
    ib0.period##c.d_ads ///
    ib0.period##c.vix, robust
	
est sto reg2
estadd local Controls "Yes"



// cumulative t+1 to t+2
bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 ib0.period##c.FEARS ///
    ib0.period##c.vwretd ///
    ib0.period##c.L1_ret ///
    ib0.period##c.L2_ret ///
    ib0.period##c.L3_ret ///
    ib0.period##c.L4_ret ///
    ib0.period##c.L5_ret ///
    ib0.period##c.d_epu ///
    ib0.period##c.d_ads ///
    ib0.period##c.vix, robust
	
est sto reg3
estadd local Controls "Yes"

esttab reg1 reg2 reg3 using "$data_output/fears_full_interaction.tex", ///
    replace ///
    booktabs ///
    label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    compress ///
    mtitles("t" "t+1" "t+2" "t+3" "t+4" "t+5" "t+1 to t+2") ///
    stats(Controls N r2, fmt(%9s 0 3) ///
          labels("Controls" "Observations" "R-squared")) ///
    title("FEARS and S\&P 500 returns (2023--2024)") ///
    alignment(l*{7}{c})
