****************************************************
* BASELINE ANALYSIS (full sample, 30 terms)
* 1. Whole-period term stats table (2019-2024)
* 2. Rolling regressions: 10 expanding windows, all starting Jun 2019 (Prerequisiste for FEARS construction)
* 3. Merge rolling regression outputs (Prerequisiste for FEARS construction)
* 4. Construct FEARS index (full sample) 
* 5. Baseline predictive regressions
****************************************************


****************************************************
* 1. MOST NEGATIVE T-STAT QUERIES, 2019-2024 (BASELINE TOP 30)
****************************************************

clear all

use "$data_int/mrkt_google_controls.dta", clear

gen mktret = sprtrn

drop if missing(mktret)

sort tic date

tempfile results
postfile handle str80 query double beta tstat N using `results', replace

levelsof tic, local(tlist)

keep if date >= td(1jun2019) & date <= td(31dec2024)

foreach k of local tlist {

    quietly count if tic==`k' & !missing(mktret, dASVI)
    local N = r(N)

    if (`N' >= 40) {
        capture quietly regress mktret dASVI if tic==`k' & !missing(mktret, dASVI)
        if (_rc==0) {
            quietly levelsof query if tic==`k', local(q) clean
            post handle ("`q'") (_b[dASVI]) (_b[dASVI]/_se[dASVI]) (e(N))
        }
    }
}

postclose handle
use `results', clear

sort tstat

list query beta tstat N in 1/30

keep in 1/30

rename query term
label var term  "Search term"
label var beta  "Coefficient on $\Delta ASVI$"
label var tstat "t-statistic"


****************************************************
* 2. ROLLING REGRESSIONS (all start Jun 2019, 30 terms)
****************************************************

* end dates, block labels, and save names for each of the 10 windows
local end_dates   01jan2020 01jul2020 01jan2021 01jul2021 01jan2022 01jul2022 01jan2023 01jul2023 01jan2024 01jul2024
local block_names jun19-jan20 jun19-jul20 jun19-jan21 jun19-jul21 jun19-jan22 jun19-jul22 jun19-jan23 jun19-jul23 jun19-jan24 jun19-jul24
local save_names  jun2019_jan2020 jun2019_jul2020 jun2019_jan2021 jun2019_jul2021 jun2019_jan2022 jun2019_jul2022 jun2019_jan2023 jun2019_jul2023 jun2019_jan2024 jun2019_jul2024

local n : word count `end_dates'
forvalues i = 1/`n' {

    local edate : word `i' of `end_dates'
    local bname : word `i' of `block_names'
    local sname : word `i' of `save_names'

    use "$data_int/mrkt_google_controls.dta", clear
    format date %td

    keep if inrange(date, td(01jun2019), td(`edate'))

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

    keep in 1/30

    keep tic query
    gen str20 block = "`bname'"
    duplicates drop

    save "$data_int/term_betas_`sname'.dta", replace
}


****************************************************
* 3. MERGE ROLLING REGRESSIONS (BASELINE)
****************************************************

clear all
set more off

local files ///
    $data_int/term_betas_jun2019_jan2020.dta ///
    $data_int/term_betas_jun2019_jul2020.dta ///
    $data_int/term_betas_jun2019_jan2021.dta ///
    $data_int/term_betas_jun2019_jul2021.dta ///
    $data_int/term_betas_jun2019_jan2022.dta ///
    $data_int/term_betas_jun2019_jul2022.dta ///
    $data_int/term_betas_jun2019_jan2023.dta ///
    $data_int/term_betas_jun2019_jul2023.dta ///
    $data_int/term_betas_jun2019_jan2024.dta ///
    $data_int/term_betas_jun2019_jul2024.dta

local first : word 1 of `files'
use `first', clear

local n : word count `files'
forvalues i = 2/`n' {
    local f : word `i' of `files'
    append using `f'
}

tab block

save "$data_int/fears_term_sets_all_blocks_BASELINE.dta", replace


****************************************************
* 4. CONSTRUCT FEARS INDEX (FULL SAMPLE, BASELINE)
****************************************************

clear all
set more off

*============================================================
* 1) Build a date->block calendar (one block per day)
*============================================================
preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

keep if date >= td(1jun2019) & date <= td(31dec2024)

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

*============================================================
* 2) Create a block x tic lookup (30 tics per block)
*============================================================
use "$data_int/fears_term_sets_all_blocks_BASELINE.dta", clear
keep tic block
duplicates drop

tempfile top30
save `top30', replace

*============================================================
* 3) Compute FEARS:
*    FEARS_t = mean(dASVI_{tic,t}) over the 30 tics active in block(t)
*============================================================
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

save "$data_int/FEARS_daily_2019_2024_BASELINE.dta", replace


****************************************************
* 5. BASELINE PREDICTIVE REGRESSIONS
****************************************************

clear all

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2024_BASELINE.dta", keep(match) nogenerate

drop query SVI dSVI dASVI

sort date tic
by date: keep if _n==1

sort date
gen long t = _n
tsset t

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

summ FEARS

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

label var FEARS    "FEARS"

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 using "$data_output/fears_predictive_regs.tex", ///
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
    title("FEARS and S\&P 500 returns (full sample, 2019--2024)") ///
    alignment(l*{7}{c})
