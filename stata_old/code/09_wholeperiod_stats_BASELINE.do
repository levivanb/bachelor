****************************************************
* FIND QUERIES OVER 2019-2024 WITH MOST NEGATIVE T STAT
****************************************************

clear all

use "$data_int/mrkt_google_controls.dta", clear

* Choose market return to analyze (baseline)
gen mktret = sprtrn

drop if missing(mktret)

sort tic date

tempfile results
postfile handle str80 query double beta tstat N using `results', replace

levelsof tic, local(tlist)

keep if date >= td(1jun2019) & date <= td(31dec2024) 

foreach k of local tlist {

    * Require enough usable observations
    quietly count if tic==`k' & !missing(mktret, dASVI)
    local N = r(N)

    if (`N' >= 40) {   // set threshold; 60 is a safe minimum for daily
        capture quietly regress mktret dASVI if tic==`k' & !missing(mktret, dASVI)
        if (_rc==0) {
            * grab the query string for this tic
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

* Rename for LaTeX clarity
rename query term
label var term  "Search term"
label var beta  "Coefficient on $\Delta ASVI$"
label var tstat "t-statistic"

estpost tabstat beta tstat, by(term) statistics(mean) nototal

esttab using "$data_output/top30_terms.tex", ///
    cells("beta(fmt(4)) tstat(fmt(2))") ///
    noobs ///
    nonumber ///
    label ///
    replace ///
    booktabs ///
    title("Top 30 Search Terms by Market Sensitivity (full sample, 2019-2024)") ///
    alignment(lccc)
