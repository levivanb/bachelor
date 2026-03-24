clear all
set more off

**************************************************
*Make date-level controls 
**************************************************
use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2024.dta", keep(match) nogenerate

drop query SVI dSVI dASVI 

keep date sprtrn vwretd epu ads vix FEARS
duplicates drop date, force

sort date
save "$data_int/mrkt_google_controls_daily.dta", replace


**************************************************
* Load spreads and merge with date-level controls
**************************************************
use "$data_int/all_daily_spreads.dta", clear
sort date


merge 1:1 date using "$data_int/mrkt_google_controls_daily.dta"
tab _merge
keep if _merge == 3
drop _merge


* Create a gap-free trading-day index
sort date
gen long t = _n
tsset t

gen period = .
replace period = 0 if inrange(year(date), 2019, 2021)
replace period = 1 if year(date) == 2022
replace period = 2 if inrange(year(date), 2023, 2024)

label define periodlbl 0 "2019-2021" 1 "2022" 2 "2023-2024"
label values period periodlbl


**************************************************
*Create controls and forward returns for beta spread
**************************************************
gen d_epu = D.epu
gen d_ads = D.ads

gen L1_ret = L1.beta_spread
gen L2_ret = L2.beta_spread
gen L3_ret = L3.beta_spread
gen L4_ret = L4.beta_spread
gen L5_ret = L5.beta_spread

gen beta_fwd_1     = F1.beta_spread
gen beta_fwd_2     = F2.beta_spread
gen beta_fwd_cum_2 = F1.beta_spread + F2.beta_spread

* 2019-2021
bootstrap _b, reps(1000) seed(12345): ///
reg beta_spread FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==0, robust
est sto b1
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg beta_fwd_1 FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==0, robust
est sto b2
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg beta_fwd_cum_2 FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==0, robust
est sto b3
estadd local Controls "Yes"

* 2022
bootstrap _b, reps(1000) seed(12345): ///
reg beta_spread FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==1, robust
est sto b4
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg beta_fwd_1 FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==1, robust
est sto b5
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg beta_fwd_cum_2 FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==1, robust
est sto b6
estadd local Controls "Yes"

* 2023-2024
bootstrap _b, reps(1000) seed(12345): ///
reg beta_spread FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==2, robust
est sto b7
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg beta_fwd_1 FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==2, robust
est sto b8
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg beta_fwd_cum_2 FEARS ///
    L1_ret L2_ret L3_ret L4_ret L5_ret ///
    d_epu d_ads vix if period==2, robust
est sto b9
estadd local Controls "Yes"


	
	
**************************************************
*Create controls and forward returns for std spread
**************************************************

gen L1_ret_std = L1.std_spread
gen L2_ret_std = L2.std_spread
gen L3_ret_std = L3.std_spread
gen L4_ret_std = L4.std_spread
gen L5_ret_std = L5.std_spread

gen std_fwd_1     = F1.std_spread
gen std_fwd_2     = F2.std_spread
gen std_fwd_cum_2 = F1.std_spread + F2.std_spread

* 2019-2021
bootstrap _b, reps(1000) seed(12345): ///
reg std_spread FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==0, robust
est sto s1
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg std_fwd_1 FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==0, robust
est sto s2
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg std_fwd_cum_2 FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==0, robust
est sto s3
estadd local Controls "Yes"

* 2022
bootstrap _b, reps(1000) seed(12345): ///
reg std_spread FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==1, robust
est sto s4
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg std_fwd_1 FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==1, robust
est sto s5
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg std_fwd_cum_2 FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==1, robust
est sto s6
estadd local Controls "Yes"

* 2023-2024
bootstrap _b, reps(1000) seed(12345): ///
reg std_spread FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==2, robust
est sto s7
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg std_fwd_1 FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==2, robust
est sto s8
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg std_fwd_cum_2 FEARS ///
    L1_ret_std L2_ret_std L3_ret_std L4_ret_std L5_ret_std ///
    d_epu d_ads vix if period==2, robust
est sto s9
estadd local Controls "Yes"

**************************************************
* Export beta table
**************************************************
esttab b1 b2 b3 b4 b5 b6 b7 b8 b9 using "$data_output/beta_spreads_subperiods.tex", ///
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
    title("FEARS and beta-spread returns across subperiods") ///
    alignment(l*{9}{c})

**************************************************
* Export std table
**************************************************
esttab s1 s2 s3 s4 s5 s6 s7 s8 s9 using "$data_output/std_spreads_subperiods.tex", ///
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
    title("FEARS and volatility-spread returns across subperiods") ///
    alignment(l*{9}{c})
