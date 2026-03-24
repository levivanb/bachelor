****************************************************
* SUBPERIOD ANALYSIS (time-varying term sets)
* 1. Whole-period stats per subperiod
* 2. Rolling regressions: Jun 2021 and Jun 2022 starting windows (Prerequisiste for FEARS construction)
* 3. Merge all rolling regressions (Prerequisiste for FEARS construction)
* 4. FEARS construction per subperiod
* 5. Baseline time-varying specifcation
* 6. Time-varying regressions (interaction + alternative return measure robustness)
****************************************************


****************************************************
* 1. MOST NEGATIVE T-STAT QUERIES BY SUBPERIOD
****************************************************

* --- 2019-2021 ---

clear all

use "$data_int/mrkt_google_controls.dta", clear

gen mktret = sprtrn

drop if missing(mktret)

sort tic date

tempfile results
postfile handle str80 query double beta tstat N using `results', replace

levelsof tic, local(tlist)

keep if date >= td(1jun2019) & date <= td(31dec2021)

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

* --- 2022 ---

clear all

use "$data_int/mrkt_google_controls.dta", clear

gen mktret = sprtrn

drop if missing(mktret)

sort tic date

tempfile results
postfile handle str80 query double beta tstat N using `results', replace

levelsof tic, local(tlist)

keep if date >= td(31dec2021) & date <= td(31dec2022)

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

* --- 2023-2024 ---

clear all

use "$data_int/mrkt_google_controls.dta", clear

gen mktret = sprtrn

drop if missing(mktret)

sort tic date

tempfile results
postfile handle str80 query double beta tstat N using `results', replace

levelsof tic, local(tlist)

keep if date >= td(31dec2022) & date <= td(31dec2024)

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
* 2. ROLLING REGRESSIONS (subperiod starting dates, 30 terms)
* Note: Jun-2019 windows (20A) were already produced in 02_baseline.do
* Here we add Jun-2021 (2 windows) and Jun-2022 (4 windows) starts.
****************************************************

* start dates, end dates, block labels, and save names
local start_dates 01jun2021 01jun2021 01jun2022 01jun2022 01jun2022 01jun2022
local end_dates   01jan2022 01jul2022 01jan2023 01jul2023 01jan2024 01jul2024
local block_names jun21-jan22 jun21-jul22 jun22-jan23 jun22-jul23 jun22-jan24 jun22-jul24
local save_names  jun2021_jan2022 jun2021_jul2022 jun2022_jan2023 jun2022_jul2023 jun2022_jan2024 jun2022_jul2024

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

    keep in 1/30

    keep tic query
    gen str20 block = "`bname'"
    duplicates drop

    save "$data_int/term_betas_`sname'.dta", replace
}


****************************************************
* 3. MERGE ALL ROLLING REGRESSIONS (SUBPERIOD TERM SETS)
****************************************************

clear all
set more off

local files ///
    $data_int/term_betas_jun2019_jan2020.dta ///
    $data_int/term_betas_jun2019_jul2020.dta ///
    $data_int/term_betas_jun2019_jan2021.dta ///
    $data_int/term_betas_jun2019_jul2021.dta ///
    $data_int/term_betas_jun2021_jan2022.dta ///
    $data_int/term_betas_jun2021_jul2022.dta ///
    $data_int/term_betas_jun2022_jan2023.dta ///
    $data_int/term_betas_jun2022_jul2023.dta ///
    $data_int/term_betas_jun2022_jan2024.dta ///
    $data_int/term_betas_jun2022_jul2024.dta

local first : word 1 of `files'
use `first', clear

local n : word count `files'
forvalues i = 2/`n' {
    local f : word `i' of `files'
    append using `f'
}

tab block

save "$data_int/fears_term_sets_all_blocks_update.dta", replace


****************************************************
* 4. FEARS CONSTRUCTION PER SUBPERIOD
****************************************************

* The block calendar below maps each calendar date to the term set
* used for FEARS construction (time-varying start dates from section 2).
* Block calendar is the same for all three subperiods.

* --- 2020-2021 ---

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

use "$data_int/fears_term_sets_all_blocks_update.dta", clear
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

save "$data_int/FEARS_daily_2019_2021.dta", replace


* --- 2022 ---

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

use "$data_int/fears_term_sets_all_blocks_update.dta", clear
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

save "$data_int/FEARS_daily_2022.dta", replace


* --- 2023-2024 ---

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

use "$data_int/fears_term_sets_all_blocks_update.dta", clear
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

save "$data_int/FEARS_daily_2023_2024.dta", replace


****************************************************
* 5. PREDICTIVE REGRESSIONS PER SUBPERIOD: BASELINE TIME VARYING SPECIFICITATION
****************************************************

clear all

use "$data_int/mrkt_google_controls.dta", clear

merge m:1 date using "$data_int/FEARS_daily_2019_2021.dta", keep(match) nogenerate

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

merge m:1 date using "$data_int/FEARS_daily_2022.dta", keep(match) nogenerate

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

merge m:1 date using "$data_int/FEARS_daily_2023_2024.dta", keep(match) nogenerate

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
* 6A. TIME-VARYING: INTERACTION REGRESSION
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

******INTERACTION******
clear all

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


gen period = .
replace period = 0 if inrange(year(date), 2019, 2021)
replace period = 1 if year(date) == 2022
replace period = 2 if inrange(year(date), 2023, 2024)

label define periodlbl 0 "2020-2021" 1 "2022" 2 "2023-2024"
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
    mtitles("t" "t+1" "t+2") ///
    keep(FEARS *.period#c.FEARS) ///
    order(FEARS *.period#c.FEARS) ///
    coeflabels( ///
        FEARS "FEARS" ///
        1.period#c.FEARS "2022 $\times$ FEARS" ///
        2.period#c.FEARS "2023--2024 $\times$ FEARS" ///
    ) ///
    stats(Controls N r2, fmt(%9s 0 3) ///
          labels("Controls" "Observations" "R-squared")) ///
    title("FEARS and S\&P 500 returns (2023--2024)") ///
    alignment(l*{3}{c})


****************************************************
* 6B. TIME-VARYING: VALUE-WEIGHTED RETURNS ROBUSTNESS
****************************************************

clear all

local fears_files FEARS_daily_2019_2021 FEARS_daily_2022 FEARS_daily_2023_2024
local reg_base    1 4 7

forvalues i = 1/3 {
    local ff : word `i' of `fears_files'
    local b  : word `i' of `reg_base'
    local b1 = `b' + 1
    local b2 = `b' + 2

    use "$data_int/mrkt_google_controls.dta", clear
    merge m:1 date using "$data_int/`ff'.dta", keep(match) nogenerate
    drop query SVI dSVI dASVI
    sort date tic
    by date: keep if _n==1
    sort date
    gen long t = _n
    tsset t

    gen ret_fwd_1   = F1.vwretd
    gen ret_fwd_cum_2 = F1.vwretd + F2.vwretd
    gen L1_ret = L1.vwretd
    gen L2_ret = L2.vwretd
    gen L3_ret = L3.vwretd
    gen L4_ret = L4.vwretd
    gen L5_ret = L5.vwretd
    gen d_epu  = D.epu
    gen d_ads  = D.ads

    bootstrap _b, reps(1000) seed(12345): ///
    reg vwretd FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
    est sto reg`b'
    estadd local Controls "Yes"

    bootstrap _b, reps(1000) seed(12345): ///
    reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
    est sto reg`b1'
    estadd local Controls "Yes"

    bootstrap _b, reps(1000) seed(12345): ///
    reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
    est sto reg`b2'
    estadd local Controls "Yes"
}

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 reg9 ///
    using "$data_output/fears_vwretd_subperiods.tex", ///
    replace booktabs label b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) compress keep(FEARS) order(FEARS) ///
    mtitles("t" "t+1" "t+1 to t+2" "t" "t+1" "t+1 to t+2" "t" "t+1" "t+1 to t+2") ///
    mgroups("2019--2021" "2022" "2023--2024", pattern(1 0 0 1 0 0 1 0 0) ///
            prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    stats(Controls N r2, fmt(%9s 0 3) ///
          labels("Controls" "Observations" "R-squared")) ///
    title("FEARS and value-weighted returns across subperiods") ///
    alignment(l*{9}{c})


****************************************************
* 6C. TIME-VARYING: EQUAL-WEIGHTED RETURNS ROBUSTNESS
****************************************************

clear all

local fears_files FEARS_daily_2019_2021 FEARS_daily_2022 FEARS_daily_2023_2024
local reg_base    1 4 7

forvalues i = 1/3 {
    local ff : word `i' of `fears_files'
    local b  : word `i' of `reg_base'
    local b1 = `b' + 1
    local b2 = `b' + 2

    use "$data_int/mrkt_google_controls.dta", clear
    merge m:1 date using "$data_int/`ff'.dta", keep(match) nogenerate
    drop query SVI dSVI dASVI
    sort date tic
    by date: keep if _n==1
    sort date
    gen long t = _n
    tsset t

    gen ret_fwd_1   = F1.ewretd
    gen ret_fwd_cum_2 = F1.ewretd + F2.ewretd
    gen L1_ret = L1.ewretd
    gen L2_ret = L2.ewretd
    gen L3_ret = L3.ewretd
    gen L4_ret = L4.ewretd
    gen L5_ret = L5.ewretd
    gen d_epu  = D.epu
    gen d_ads  = D.ads

    bootstrap _b, reps(1000) seed(12345): ///
    reg ewretd FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
    est sto reg`b'
    estadd local Controls "Yes"

    bootstrap _b, reps(1000) seed(12345): ///
    reg ret_fwd_1 FEARS ewretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
    est sto reg`b1'
    estadd local Controls "Yes"

    bootstrap _b, reps(1000) seed(12345): ///
    reg ret_fwd_cum_2 FEARS ewretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
    est sto reg`b2'
    estadd local Controls "Yes"
}

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 reg9 ///
    using "$data_output/fears_ewretd_subperiods.tex", ///
    replace booktabs label b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) compress keep(FEARS) order(FEARS) ///
    mtitles("t" "t+1" "t+1 to t+2" "t" "t+1" "t+1 to t+2" "t" "t+1" "t+1 to t+2") ///
    mgroups("2019--2021" "2022" "2023--2024", pattern(1 0 0 1 0 0 1 0 0) ///
            prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    stats(Controls N r2, fmt(%9s 0 3) ///
          labels("Controls" "Observations" "R-squared")) ///
    title("FEARS and equal-weighted returns across subperiods") ///
    alignment(l*{9}{c})


****************************************************
* 6D. TIME-VARYING: ETF RETURNS ROBUSTNESS
*     (SPY, IWM, IWB, QQQ)
****************************************************

local etfs        SPY IWM IWB QQQ
local fears_files FEARS_daily_2019_2021 FEARS_daily_2022 FEARS_daily_2023_2024
local reg_base    1 4 7

foreach etf of local etfs {

    forvalues i = 1/3 {
        local ff : word `i' of `fears_files'
        local b  : word `i' of `reg_base'
        local b1 = `b' + 1
        local b2 = `b' + 2

        use "$data_int/mrkt_google_controls.dta", clear
        merge m:1 date using "$data_int/`ff'.dta", keep(match) nogenerate
        drop query SVI dSVI dASVI
        sort date tic
        by date: keep if _n==1
        sort date
        gen long t = _n
        tsset t

        merge 1:1 date using "$data_int/ETF_`etf'_daily.dta", keep(match master) nogen
        sort date
        tsset t

        gen ret_fwd_1   = F1.DlyRetx
        gen ret_fwd_cum_2 = F1.DlyRetx + F2.DlyRetx
        gen L1_ret = L1.DlyRetx
        gen L2_ret = L2.DlyRetx
        gen L3_ret = L3.DlyRetx
        gen L4_ret = L4.DlyRetx
        gen L5_ret = L5.DlyRetx
        gen d_epu  = D.epu
        gen d_ads  = D.ads

        bootstrap _b, reps(1000) seed(12345): ///
        reg DlyRetx FEARS L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
        est sto reg`b'
        estadd local Controls "Yes"

        bootstrap _b, reps(1000) seed(12345): ///
        reg ret_fwd_1 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
        est sto reg`b1'
        estadd local Controls "Yes"

        bootstrap _b, reps(1000) seed(12345): ///
        reg ret_fwd_cum_2 FEARS vwretd L1_ret L2_ret L3_ret L4_ret L5_ret d_epu d_ads vix, robust
        est sto reg`b2'
        estadd local Controls "Yes"
    }

    esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 reg9 ///
        using "$data_output/fears_`etf'_subperiods.tex", ///
        replace booktabs label b(%9.4f) se(%9.4f) ///
        star(* 0.10 ** 0.05 *** 0.01) compress keep(FEARS) order(FEARS) ///
        mtitles("t" "t+1" "t+1 to t+2" "t" "t+1" "t+1 to t+2" "t" "t+1" "t+1 to t+2") ///
        mgroups("2019--2021" "2022" "2023--2024", pattern(1 0 0 1 0 0 1 0 0) ///
                prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
        stats(Controls N r2, fmt(%9s 0 3) ///
              labels("Controls" "Observations" "R-squared")) ///
        title("FEARS and `etf' returns across subperiods") ///
        alignment(l*{9}{c})
}
