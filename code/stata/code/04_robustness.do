****************************************************
* ROBUSTNESS ANALYSIS
* A. Old FEARS robustness (BASELINE term sets applied to subperiods)
* B. 35-term robustness: rolling regressions, FEARS, regressions
* C. 25-term robustness: rolling regressions, FEARS, regressions
****************************************************


****************************************************
* A. OLD FEARS ROBUSTNESS
* Uses the BASELINE rolling windows (all starting Jun 2019)
* to construct FEARS for each subperiod.
****************************************************

* --- FEARS construction: 2019-2021 (BASELINE term sets) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(1jun2019) & date <= td(31dec2021)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun19-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun19-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun19-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun19-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun19-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun19-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_BASELINE.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2019_2021_BASELINE_ROBUSTNESS.dta", replace


* --- FEARS construction: 2022 (BASELINE term sets) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(31dec2021) & date <= td(31dec2022)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun19-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun19-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun19-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun19-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun19-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun19-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_BASELINE.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2022_BASELINE_ROBUSTNESS.dta", replace


* --- FEARS construction: 2023-2024 (BASELINE term sets) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(31dec2022) & date <= td(31dec2024)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun19-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun19-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun19-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun19-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun19-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun19-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_BASELINE.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2023_2024_BASELINE_ROBUSTNESS.dta", replace


* --- Regressions: old FEARS robustness (3 subperiods) ---

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2019-2021)
****************************************************

clear all

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2021_BASELINE_ROBUSTNESS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg1
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg2
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg3
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2022)
****************************************************

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2022_BASELINE_ROBUSTNESS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg4
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg5
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg6
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2023-2024)
****************************************************

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2023_2024_BASELINE_ROBUSTNESS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg7
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg8
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg9
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER: FINAL TABLE
****************************************************

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 reg9 using "$data_output/fears_predictive_regs_2023_2024.tex", ///
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


****************************************************
* B. 35-TERM ROBUSTNESS
****************************************************

* --- Rolling regressions (35 terms, all windows) ---
* Windows: 4 from Jun 2019, 2 from Jun 2021, 4 from Jun 2022

local start_dates 01jun2019 01jun2019 01jun2019 01jun2019 01jun2021 01jun2021 01jun2022 01jun2022 01jun2022 01jun2022
local end_dates   01jan2020 01jul2020 01jan2021 01jul2021 01jan2022 01jul2022 01jan2023 01jul2023 01jan2024 01jul2024
local block_names jun19-jan20 jun19-jul20 jun19-jan21 jun19-jul21 jun21-jan22 jun21-jul22 jun22-jan23 jun22-jul23 jun22-jan24 jun22-jul24
local save_names  35TERMS_jun2019_jan2020 35TERMS_jun2019_jul2020 35TERMS_jun2019_jan2021 35TERMS_jun2019_jul2021 35TERMS_jun2021_jan2022 35TERMS_jun2021_jul2022 35TERMS_jun2022_jan2023 35TERMS_jun2022_jul2023 35TERMS_jun2022_jan2024 35TERMS_jun2022_jul2024

local n : word count `end_dates'
forvalues i = 1/`n' {

    local sdate : word `i' of `start_dates'
    local edate : word `i' of `end_dates'
    local bname : word `i' of `block_names'
    local sname : word `i' of `save_names'

    use "$data_int/mrkt_google_controls.dta", clear
    format date %td

    keep if inrange(date, td(`sdate'), td(`edate'))

    levelsof tic, local(tics)

    tempfile results
    tempname ph

    postfile `ph' ///
        long tic ///
        str200 query ///
        double beta tstat ///
        int N ///
        using "`results'", replace

    foreach k of local tics {

        quietly count if tic==`k' & !missing(vwretd, dASVI)
        if r(N) < 40 continue

        quietly regress vwretd dASVI if tic==`k' & !missing(vwretd, dASVI)
        if _rc != 0 continue

        quietly levelsof query if tic==`k', local(q)
        local q1 : word 1 of `q'

        local b = _b[dASVI]
        local t = _b[dASVI] / _se[dASVI]

        post `ph' (`k') ("`q1'") (`b') (`t') (e(N))
    }

    postclose `ph'

    use "`results'", clear
    sort tstat

    keep in 1/35

    keep tic query
    gen str20 block = "`bname'"
    duplicates drop

    save "$data_int/term_betas_`sname'.dta", replace
}


* --- Merge 35-term rolling regressions ---

clear all
set more off

local files ///
    $data_int/term_betas_35TERMS_jun2019_jan2020.dta ///
    $data_int/term_betas_35TERMS_jun2019_jul2020.dta ///
    $data_int/term_betas_35TERMS_jun2019_jan2021.dta ///
    $data_int/term_betas_35TERMS_jun2019_jul2021.dta ///
    $data_int/term_betas_35TERMS_jun2021_jan2022.dta ///
    $data_int/term_betas_35TERMS_jun2021_jul2022.dta ///
    $data_int/term_betas_35TERMS_jun2022_jan2023.dta ///
    $data_int/term_betas_35TERMS_jun2022_jul2023.dta ///
    $data_int/term_betas_35TERMS_jun2022_jan2024.dta ///
    $data_int/term_betas_35TERMS_jun2022_jul2024.dta

local first : word 1 of `files'
use `first', clear

local n : word count `files'
forvalues i = 2/`n' {
    local f : word `i' of `files'
    append using `f'
}

tab block

save "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_35.dta", replace


* --- FEARS construction: 2019-2021 (35 terms) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(1jun2019) & date <= td(31dec2021)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun21-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun21-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun22-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun22-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun22-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun22-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_35.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2019_2021_ROBUSTNESS_35TERMS.dta", replace


* --- FEARS construction: 2022 (35 terms) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(31dec2021) & date <= td(31dec2022)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun21-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun21-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun22-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun22-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun22-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun22-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_35.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2022_ROBUSTNESS_35TERMS.dta", replace


* --- FEARS construction: 2023-2024 (35 terms) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(31dec2022) & date <= td(31dec2024)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun21-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun21-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun22-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun22-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun22-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun22-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_35.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2023_2024_ROBUSTNESS_35TERMS.dta", replace


* --- Regressions: 35-term robustness (3 subperiods) ---

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2019-2021)
****************************************************

clear all

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2021_ROBUSTNESS_35TERMS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg1
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg2
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg3
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2022)
****************************************************

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2022_ROBUSTNESS_35TERMS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg4
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg5
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg6
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2023-2024)
****************************************************

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2023_2024_ROBUSTNESS_35TERMS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg7
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg8
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg9
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER: FINAL TABLE
****************************************************

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 reg9 using "$data_output/fears_predictive_regs_2023_2024.tex", ///
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
    title("FEARS and S\&P 500 returns") ///
    alignment(l*{7}{c})


****************************************************
* C. 25-TERM ROBUSTNESS
****************************************************

* --- Rolling regressions (25 terms, all windows) ---
* Windows: 4 from Jun 2019, 2 from Jun 2021, 4 from Jun 2022

local start_dates 01jun2019 01jun2019 01jun2019 01jun2019 01jun2021 01jun2021 01jun2022 01jun2022 01jun2022 01jun2022
local end_dates   01jan2020 01jul2020 01jan2021 01jul2021 01jan2022 01jul2022 01jan2023 01jul2023 01jan2024 01jul2024
local block_names jun19-jan20 jun19-jul20 jun19-jan21 jun19-jul21 jun21-jan22 jun21-jul22 jun22-jan23 jun22-jul23 jun22-jan24 jun22-jul24
local save_names  25TERMS_jun2019_jan2020 25TERMS_jun2019_jul2020 25TERMS_jun2019_jan2021 25TERMS_jun2019_jul2021 25TERMS_jun2021_jan2022 25TERMS_jun2021_jul2022 25TERMS_jun2022_jan2023 25TERMS_jun2022_jul2023 25TERMS_jun2022_jan2024 25TERMS_jun2022_jul2024

local n : word count `end_dates'
forvalues i = 1/`n' {

    local sdate : word `i' of `start_dates'
    local edate : word `i' of `end_dates'
    local bname : word `i' of `block_names'
    local sname : word `i' of `save_names'

    use "$data_int/mrkt_google_controls.dta", clear
    format date %td

    keep if inrange(date, td(`sdate'), td(`edate'))

    levelsof tic, local(tics)

    tempfile results
    tempname ph

    postfile `ph' ///
        long tic ///
        str200 query ///
        double beta tstat ///
        int N ///
        using "`results'", replace

    foreach k of local tics {

        quietly count if tic==`k' & !missing(vwretd, dASVI)
        if r(N) < 40 continue

        quietly regress vwretd dASVI if tic==`k' & !missing(vwretd, dASVI)
        if _rc != 0 continue

        quietly levelsof query if tic==`k', local(q)
        local q1 : word 1 of `q'

        local b = _b[dASVI]
        local t = _b[dASVI] / _se[dASVI]

        post `ph' (`k') ("`q1'") (`b') (`t') (e(N))
    }

    postclose `ph'

    use "`results'", clear
    sort tstat

    keep in 1/25

    keep tic query
    gen str20 block = "`bname'"
    duplicates drop

    save "$data_int/term_betas_`sname'.dta", replace
}


* --- Merge 25-term rolling regressions ---

clear all
set more off

local files ///
    $data_int/term_betas_25TERMS_jun2019_jan2020.dta ///
    $data_int/term_betas_25TERMS_jun2019_jul2020.dta ///
    $data_int/term_betas_25TERMS_jun2019_jan2021.dta ///
    $data_int/term_betas_25TERMS_jun2019_jul2021.dta ///
    $data_int/term_betas_25TERMS_jun2021_jan2022.dta ///
    $data_int/term_betas_25TERMS_jun2021_jul2022.dta ///
    $data_int/term_betas_25TERMS_jun2022_jan2023.dta ///
    $data_int/term_betas_25TERMS_jun2022_jul2023.dta ///
    $data_int/term_betas_25TERMS_jun2022_jan2024.dta ///
    $data_int/term_betas_25TERMS_jun2022_jul2024.dta

local first : word 1 of `files'
use `first', clear

local n : word count `files'
forvalues i = 2/`n' {
    local f : word `i' of `files'
    append using `f'
}

tab block

save "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_25.dta", replace


* --- FEARS construction: 2019-2021 (25 terms) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(1jun2019) & date <= td(31dec2021)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun21-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun21-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun22-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun22-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun22-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun22-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_25.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2019_2021_ROBUSTNESS_25TERMS.dta", replace


* --- FEARS construction: 2022 (25 terms) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(31dec2021) & date <= td(31dec2022)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun21-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun21-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun22-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun22-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun22-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun22-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_25.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2022_ROBUSTNESS_25TERMS.dta", replace


* --- FEARS construction: 2023-2024 (25 terms) ---

clear all
set more off

preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(31dec2022) & date <= td(31dec2024)

gen int y = year(date)
gen int m = month(date)

gen str20 block = ""
replace block = "jun19-jan20" if y==2020 & inrange(m,1,6)
replace block = "jun19-jul20" if y==2020 & inrange(m,7,12)

replace block = "jun19-jan21" if y==2021 & inrange(m,1,6)
replace block = "jun19-jul21" if y==2021 & inrange(m,7,12)

replace block = "jun21-jan22" if y==2022 & inrange(m,1,6)
replace block = "jun21-jul22" if y==2022 & inrange(m,7,12)

replace block = "jun22-jan23" if y==2023 & inrange(m,1,6)
replace block = "jun22-jul23" if y==2023 & inrange(m,7,12)

replace block = "jun22-jan24" if y==2024 & inrange(m,1,6)
replace block = "jun22-jul24" if y==2024 & inrange(m,7,12)

drop y m
drop if block==""

tempfile calendar
save `calendar', replace
restore

use "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_25.dta", clear
keep tic block
duplicates drop
tempfile top30
save `top30', replace

use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

merge m:1 date using `calendar', keep(match) nogenerate
merge m:1 block tic using `top30', keep(match) nogenerate

bysort date: egen FEARS = mean(dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2023_2024_ROBUSTNESS_25TERMS.dta", replace


* --- Regressions: 25-term robustness (3 subperiods) ---

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2019-2021)
****************************************************

clear all

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2021_ROBUSTNESS_25TERMS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg1
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg2
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg3
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2022)
****************************************************

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2022_ROBUSTNESS_25TERMS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg4
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg5
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg6
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER (2023-2024)
****************************************************

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2023_2024_ROBUSTNESS_25TERMS.dta", keep(match) nogenerate

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

bootstrap _b, reps(1000) seed(12345): ///
reg sprtrn FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg7
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg8
estadd local Controls "Yes"

bootstrap _b, reps(1000) seed(12345): ///
reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
est sto reg9
estadd local Controls "Yes"

****************************************************
* FEAR AND RETURNS, ALL SHORT TERM TOGETHER: FINAL TABLE
****************************************************

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 reg9 using "$data_output/fears_predictive_regs_2023_2024.tex", ///
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
    title("FEARS and S\&P 500 returns") ///
    alignment(l*{7}{c})
