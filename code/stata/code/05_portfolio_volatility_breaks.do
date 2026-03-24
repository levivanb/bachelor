****************************************************
* PORTFOLIO AND VOLATILITY ANALYSIS
* 1. Decile construction (beta, std, cap)
* 2. Decile regressions
* 3. Downside decile construction (downside beta + sigma)
* 4. Downside decile regressions
* 5. Volatility analysis (ARFIMA, Newey-West, DCC-GARCH)
* 6. Structural break analysis on returns
****************************************************


****************************************************
* 1. DECILE CONSTRUCTION
****************************************************

clear all
set more off

* Beta
use "$data_raw/beta_deciles.dta", clear
describe
rename betan beta_decile
capture rename betav beta_value
keep PERMNO date beta_decile beta_value
duplicates drop PERMNO date, force
save "$data_int/beta_deciles_clean.dta", replace

bys beta_decile: summ beta_value


* Std dev
use "$data_raw/std_deciles.dta", clear
describe
rename sdevn std_decile
capture rename sdevv std_value
keep PERMNO date std_decile std_value
duplicates drop PERMNO date, force
save "$data_int/std_deciles_clean.dta", replace

bys std_decile: summ std_value

* Cap
use "$data_raw/capitilization_deciles.dta", clear
describe
rename capn cap_decile
capture rename capv cap_value
keep PERMNO date cap_decile cap_value
duplicates drop PERMNO date, force
save "$data_int/capitalization_deciles_clean.dta", replace

bys cap_decile: summ cap_value

* Merge all deciles together
use "$data_int/beta_deciles_clean.dta", clear
sort PERMNO date

merge 1:1 PERMNO date using "$data_int/std_deciles_clean.dta"
tab _merge
drop _merge

merge 1:1 PERMNO date using "$data_int/capitalization_deciles_clean.dta"
tab _merge
drop _merge

sort PERMNO date
save "$data_int/all_deciles_merged.dta", replace

* Load CRSP daily stock data and merge deciles onto it
use "$data_raw/CRSP.dta", clear

keep PERMNO DlyCalDt DlyRet
rename DlyCalDt date
sort PERMNO date

merge m:1 PERMNO date using "$data_int/all_deciles_merged.dta"
tab _merge
drop _merge

sort PERMNO date

* Carry assignments forward within stock
by PERMNO (date): replace beta_decile = beta_decile[_n-1] if missing(beta_decile)
by PERMNO (date): replace beta_value  = beta_value[_n-1]  if missing(beta_value)

by PERMNO (date): replace std_decile  = std_decile[_n-1]  if missing(std_decile)
by PERMNO (date): replace std_value   = std_value[_n-1]   if missing(std_value)

by PERMNO (date): replace cap_decile  = cap_decile[_n-1]  if missing(cap_decile)
by PERMNO (date): replace cap_value   = cap_value[_n-1]   if missing(cap_value)

drop if missing(beta_decile) & missing(std_decile) & missing(cap_decile)
sort PERMNO date

* Beta decile daily returns and spread
preserve
    keep date DlyRet beta_decile
    drop if missing(beta_decile)
    collapse (mean) beta_ret = DlyRet, by(date beta_decile)
    reshape wide beta_ret, i(date) j(beta_decile)
    gen beta_spread = beta_ret1 - beta_ret10
    save "$data_int/beta_daily_spread.dta", replace
restore

* Std decile daily returns and spread
preserve
    keep date DlyRet std_decile
    drop if missing(std_decile)
    collapse (mean) std_ret = DlyRet, by(date std_decile)
    reshape wide std_ret, i(date) j(std_decile)
    gen std_spread = std_ret1 - std_ret10
    save "$data_int/std_daily_spread.dta", replace
restore

* Cap decile daily returns and spread
preserve
    keep date DlyRet cap_decile
    drop if missing(cap_decile)
    collapse (mean) cap_ret = DlyRet, by(date cap_decile)
    reshape wide cap_ret, i(date) j(cap_decile)
    gen cap_spread = cap_ret1 - cap_ret10
    save "$data_int/cap_daily_spread.dta", replace
restore

* Merge all three spread datasets together
use "$data_int/beta_daily_spread.dta", clear

merge 1:1 date using "$data_int/std_daily_spread.dta"
drop _merge

merge 1:1 date using "$data_int/cap_daily_spread.dta"
drop _merge

keep date beta_spread std_spread cap_spread

sort date
save "$data_int/all_daily_spreads.dta", replace


****************************************************
* 2. DECILE REGRESSIONS
****************************************************

clear all
set more off

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2024.dta", keep(match) nogenerate

drop query SVI dSVI dASVI

keep date sprtrn vwretd epu ads vix FEARS
duplicates drop date, force

sort date
save "$data_int/mrkt_google_controls_daily.dta", replace


use "$data_int/all_daily_spreads.dta", clear
sort date

merge 1:1 date using "$data_int/mrkt_google_controls_daily.dta"
tab _merge
keep if _merge == 3
drop _merge

sort date
gen long t = _n
tsset t

gen period = .
replace period = 0 if inrange(year(date), 2019, 2021)
replace period = 1 if year(date) == 2022
replace period = 2 if inrange(year(date), 2023, 2024)

label define periodlbl 0 "2019-2021" 1 "2022" 2 "2023-2024"
label values period periodlbl

gen d_epu = D.epu
gen d_ads = D.ads

* Beta spread regressions
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

* Std spread regressions
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

* Export beta table
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

* Export std table
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


****************************************************
* 3. DOWNSIDE DECILE CONSTRUCTION
****************************************************

clear all
set more off

use "$data_raw/crsp.dta", clear

* Parse date
capture confirm variable DlyCalDt
if _rc==0 {
    gen double date = DlyCalDt
    format date %td
}
else {
    tostring YYYYMMDD, replace
    gen double date = daily(YYYYMMDD, "YMD")
    format date %td
}

drop DlyCalDt YYYYMMDD

keep if year(date) >= 2019

keep if SecurityType == "EQTY"
keep if inlist(PrimaryExch, "N", "A", "Q")
keep if TradingStatusFlg == "A"

drop if missing(DlyRet, sprtrn, date)
drop if missing(DlyPrc)

keep if abs(DlyPrc) >= 5
keep if DlyCap >= 10000000

distinct PERMNO

keep PERMNO date DlyRet DlyVol DlyPrc DlyCap ShrOut vwretd sprtrn

rename DlyRet ret
rename DlyVol volume
rename DlyPrc price
rename DlyCap mcap

drop if missing(date)
drop if missing(vwretd)

sort PERMNO date
duplicates drop PERMNO date, force

egen firm_id = group(PERMNO)
xtset firm_id date, daily

gen year = year(date)

* Compute annual market mean return
preserve
bysort date: keep if _n == 1
keep date year sprtrn
bysort year: egen double mkt_mean = mean(sprtrn)
keep date sprtrn mkt_mean
tempfile mkt_means
save `mkt_means'
restore

drop if missing(sprtrn)
merge m:1 date using `mkt_means', keep(match) nogenerate

gen byte down_day = (sprtrn < mkt_mean)

tab down_day

* Compute downside beta and downside sigma per stock-year
bysort PERMNO year: egen int n_down = total(down_day) if !missing(ret)

gen byte enough_down = (n_down >= 40)

preserve

keep if down_day == 1 & enough_down == 1
keep if !missing(ret, sprtrn, PERMNO, year)

* Downside sigma by stock-year
bysort PERMNO year: egen double ds_sigma = sd(ret)

bysort PERMNO year: gen byte tag_sigma = (_n == 1)
tempfile sigma_vals
save "`sigma_vals'_raw", replace

use "`sigma_vals'_raw", clear
keep if tag_sigma == 1
keep PERMNO year ds_sigma
save "`sigma_vals'", replace

* Downside beta by stock-year via statsby
restore
preserve

keep if down_day == 1 & enough_down == 1
keep if !missing(ret, sprtrn, PERMNO, year)

statsby ///
    ds_beta    = _b[sprtrn] ///
    ds_beta_se = _se[sprtrn] ///
    ds_nobs    = e(N), ///
    by(PERMNO year) clear: reg ret sprtrn

* Merge downside sigma back in
merge 1:1 PERMNO year using "`sigma_vals'", keep(match) nogenerate

drop if ds_nobs < 40
drop if missing(ds_beta, ds_sigma)

* Winsorize at 1/99
foreach var in ds_beta ds_sigma {
    quietly summarize `var', detail
    replace `var' = r(p1)  if `var' < r(p1)  & !missing(`var')
    replace `var' = r(p99) if `var' > r(p99) & !missing(`var')
}

di _n "Downside beta summary:"
summarize ds_beta, detail

di _n "Downside sigma summary:"
summarize ds_sigma, detail

* Lag characteristics: estimated in year t, used in year t+1
rename year year_est
gen year = year_est + 1

order PERMNO year year_est ds_beta ds_sigma ds_beta_se ds_nobs
save "$data_int/downside_chars.dta", replace

restore

* Assign deciles
merge m:1 PERMNO year using "$data_int/downside_chars.dta", ///
    keep(master match) nogenerate

keep if !missing(ds_beta) & !missing(ds_sigma)

foreach var in ds_beta ds_sigma {

    local dname `var'_decile
    gen `dname' = .

    forvalues y = 2020/2024 {
        capture xtile tmp = `var' if year == `y', nq(10)
        if _rc == 0 {
            replace `dname' = tmp if year == `y'
            drop tmp
        }
    }
}

tab ds_beta_decile, missing
tab ds_sigma_decile, missing

* Compute decile spread returns
foreach proxy in ds_beta ds_sigma {

    di _n "Building `proxy' spread returns..."

    preserve

    keep if !missing(`proxy'_decile) & !missing(ret) & !missing(mcap)

    bysort date `proxy'_decile: egen double tot_mcap = total(mcap)
    gen double wt = mcap / tot_mcap
    gen double ret_wt = ret * wt

    collapse (sum) vw_ret = ret_wt ///
             (mean) ew_ret = ret ///
             (count) n_stocks = ret, ///
        by(date `proxy'_decile)

    reshape wide vw_ret ew_ret n_stocks, i(date) j(`proxy'_decile)

    gen `proxy'_hml_vw = vw_ret10 - vw_ret1
    gen `proxy'_hml_ew = ew_ret10 - ew_ret1

    label var `proxy'_hml_vw "High-Low `proxy' Spread (VW)"
    label var `proxy'_hml_ew "High-Low `proxy' Spread (EW)"

    sum `proxy'_hml_vw `proxy'_hml_ew

    keep date `proxy'_hml_vw `proxy'_hml_ew

    save "$data_int/`proxy'_spread_returns.dta", replace
    restore
}


****************************************************
* 4. DOWNSIDE DECILE REGRESSIONS
****************************************************

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

sort date tic
by date: keep if _n==1

merge 1:1 date using "$data_int/ds_beta_spread_returns.dta", keep(master match) nogenerate
merge 1:1 date using "$data_int/ds_sigma_spread_returns.dta", keep(master match) nogenerate

sort date
gen long t = _n
tsset t

gen d_epu = D.epu
gen d_ads = D.ads

foreach spread in ds_beta_hml_vw ds_beta_hml_ew ds_sigma_hml_vw ds_sigma_hml_ew {
    gen `spread'_f1   = F.`spread'
    gen `spread'_f1f2 = F.`spread' + F2.`spread'

    forvalues i = 1/5 {
        gen `spread'_L`i' = L`i'.`spread'
    }
}

drop if missing(FEARS) | missing(d_epu) | missing(d_ads) | missing(vix)

gen period = .
replace period = 0 if inrange(year(date), 2019, 2021)
replace period = 1 if year(date) == 2022
replace period = 2 if inrange(year(date), 2023, 2024)

label define periodlbl 0 "2019-2021" 1 "2022" 2 "2023-2024"
label values period periodlbl

* Downside beta spread
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

* Downside sigma spread
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


****************************************************
* 5. VOLATILITY ANALYSIS: ARFIMA + OLS (NEWEY-WEST) + DCC-GARCH
****************************************************

clear all
set more off

use "$data_int/mrkt_google_controls.dta", clear
merge m:1 date using "$data_int/FEARS_daily_2019_2024.dta", keep(match) nogenerate
drop query SVI dSVI dASVI
sort date tic
by date: keep if _n == 1
sort date
gen long t = _n
tsset t

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

* Part 1: ARFIMA(1,d,1) on seasonally-adjusted log VIX (full sample)
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


* Part 2: OLS with Newey-West SEs by subperiod
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

* Structural break test on VIX
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

* Part 3: DCC-GARCH
di _n "--- DCC-GARCH(1,1): sprtrn and FEARS ---"
mgarch dcc (sprtrn = d_epu d_ads, noconstant) ///
           (FEARS = , noconstant), ///
    arch(1) garch(1)
estimates store dcc_model

predict H_sprtrn_sprtrn, variance equation(sprtrn)
predict H_FEARS_FEARS, variance equation(FEARS)

di _n "--- Correlation between conditional variances ---"
pwcorr H_sprtrn_sprtrn H_FEARS_FEARS, sig

di _n "--- DCC model parameters ---"
estimates replay dcc_model

* DCC by subperiods
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


****************************************************
* 6. STRUCTURAL BREAK ANALYSIS ON RETURNS
****************************************************

clear all
set more off

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2024.dta", keep(match) nogenerate

drop query SVI dSVI dASVI

sort date tic
by date: keep if _n==1

sort date
gen long t = _n
tsset t

summ FEARS

gen ret_fwd_1 = F1.sprtrn
gen ret_fwd_2 = F2.sprtrn
gen ret_fwd_3 = F3.sprtrn
gen ret_fwd_4 = F4.sprtrn
gen ret_fwd_5 = F5.sprtrn

gen ret_fwd_cum_2 = F1.sprtrn + F2.sprtrn

gen L1_ret = L1.sprtrn
gen L2_ret = L2.sprtrn
gen L3_ret = L3.sprtrn
gen L4_ret = L4.sprtrn
gen L5_ret = L5.sprtrn

gen d_epu = D.epu
gen d_ads = D.ads

* Structural break test
xtbreak test sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, ///
    hypothesis(2) breaks(1 3)

xtbreak estimate sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, ///
  breaks(2)

list t date if t==208 | t==818, noobs
format date %td

* Regressions by break period
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
