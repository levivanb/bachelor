clear all
set more off

use "$data_int/FEARS_daily_2019_2021.dta", clear
append using "$data_int/FEARS_daily_2022.dta"
append using "$data_int/FEARS_daily_2023_2024.dta"

sort date

duplicates list date
duplicates drop date, force
save "$data_int/FEARS_daily_2019_2024.dta", replace

******Merge togeter******
clear all

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2024.dta", keep(match) nogenerate

drop query SVI dSVI dASVI 

* Keep one row per trading day (vwretd etc are identical across tics anyway)
sort date tic
by date: keep if _n==1

* Create a gap-free trading-day index

merge 1:1 date using "$data_int/ds_beta_spread_returns.dta", keep(master match) nogenerate
merge 1:1 date using "$data_int/ds_sigma_spread_returns.dta", keep(master match) nogenerate


sort date
gen long t = _n
tsset t


gen d_epu = D.epu
gen d_ads = D.ads

* Generate leads and lags for each spread
foreach spread in ds_beta_hml_vw ds_beta_hml_ew ds_sigma_hml_vw ds_sigma_hml_ew {
    gen `spread'_f1   = F.`spread'
    gen `spread'_f1f2 = F.`spread' + F2.`spread'
    
    forvalues i = 1/5 {
        gen `spread'_L`i' = L`i'.`spread'
    }
}

drop if missing(FEARS) | missing(d_epu) | missing(d_ads) | missing(vix)

*===============================================================================
* REGRESSIONS
*===============================================================================
gen period = .
replace period = 0 if inrange(year(date), 2019, 2021)
replace period = 1 if year(date) == 2022
replace period = 2 if inrange(year(date), 2023, 2024)

label define periodlbl 0 "2019-2021" 1 "2022" 2 "2023-2024"
label values period periodlbl
**************************************************
* DOWNSIDE BETA SPREAD
**************************************************

* 2019-2021
bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==0, robust
est sto db1
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw_f1 FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==0, robust
est sto db2
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw_f1f2 FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==0, robust
est sto db3
estadd local Controls "Yes"

* 2022
bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==1, robust
est sto db4
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw_f1 FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==1, robust
est sto db5
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw_f1f2 FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==1, robust
est sto db6
estadd local Controls "Yes"

* 2023-2024
bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==2, robust
est sto db7
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw_f1 FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==2, robust
est sto db8
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_beta_hml_vw_f1f2 FEARS ///
    ds_beta_hml_vw_L1 ds_beta_hml_vw_L2 ds_beta_hml_vw_L3 ds_beta_hml_vw_L4 ds_beta_hml_vw_L5 ///
    d_epu d_ads vix if period==2, robust
est sto db9
estadd local Controls "Yes"

**************************************************
* DOWNSIDE SIGMA SPREAD
**************************************************

* 2019-2021
bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==0, robust
est sto ds1
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw_f1 FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==0, robust
est sto ds2
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw_f1f2 FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==0, robust
est sto ds3
estadd local Controls "Yes"

* 2022
bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==1, robust
est sto ds4
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw_f1 FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==1, robust
est sto ds5
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw_f1f2 FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==1, robust
est sto ds6
estadd local Controls "Yes"

* 2023-2024
bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==2, robust
est sto ds7
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw_f1 FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==2, robust
est sto ds8
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ds_sigma_hml_vw_f1f2 FEARS ///
    ds_sigma_hml_vw_L1 ds_sigma_hml_vw_L2 ds_sigma_hml_vw_L3 ds_sigma_hml_vw_L4 ds_sigma_hml_vw_L5 ///
    d_epu d_ads vix if period==2, robust
est sto ds9
estadd local Controls "Yes"

esttab db1 db2 db3 db4 db5 db6 db7 db8 db9 using "$data_output/downside_beta_spreads_subperiods.tex", ///
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
    stats(Controls N r2, fmt(%9s 0 3) ///
          labels("Controls" "Observations" "R-squared")) ///
    title("X-FEARS and downside-beta spread returns across subperiods") ///
    alignment(l*{9}{c})

esttab ds1 ds2 ds3 ds4 ds5 ds6 ds7 ds8 ds9 using "$data_output/downside_sigma_spreads_subperiods.tex", ///
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
    stats(Controls N r2, fmt(%9s 0 3) ///
          labels("Controls" "Observations" "R-squared")) ///
    title("X-FEARS and downside-volatility spread returns across subperiods") ///
    alignment(l*{9}{c})
