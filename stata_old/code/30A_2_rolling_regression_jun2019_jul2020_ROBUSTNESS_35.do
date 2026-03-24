****************************************************
* ROLLING REGRESSION, JUN19 - JUL20
****************************************************

clear all
set more off

use "$data_int/mrkt_google_controls.dta", clear
format date %td

* Restrict sample
keep if inrange(date, td(01jun2019), td(1jul2020))

* Get list of queries (numeric tic)
levelsof tic, local(tics)

* Prepare results container
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

* Keep top 30 most negative
keep in 1/35

* Keep only identifiers needed for FEARS construction
keep tic query

gen str20 block = "jun19-jul20"

* Optional: enforce uniqueness (should already hold)
duplicates drop

save "$data_int/term_betas_35TERMS_jun2019_jul2020.dta", replace
