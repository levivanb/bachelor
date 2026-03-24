****************************************************
*IMPORT AND CLEAN CRSP DATA
****************************************************
clear all

use "$data_raw/CRSP.dta", clear 
****************************************************
* 1) Keep only variables needed
****************************************************
keep DlyCalDt YYYYMMDD vwretd vwretx ewretd ewretx sprtrn

****************************************************
* 2) Create a clean Stata daily date
****************************************************
capture confirm variable DlyCalDt
if _rc==0 {
    * DlyCalDt may already be a Stata %td date; enforce format
    gen double date = DlyCalDt
    format date %td
}
else {
    * If only YYYYMMDD exists
    tostring YYYYMMDD, replace
    gen double date = daily(YYYYMMDD, "YMD")
    format date %td
}

drop DlyCalDt YYYYMMDD

****************************************************
* 3) Ensure returns are numeric
****************************************************
foreach v in vwretd vwretx ewretd ewretx sprtrn {
    capture confirm numeric variable `v'
    if _rc!=0 {
        destring `v', replace force
    }
}

****************************************************
* 4) Drop missing dates and (at least) missing main return
****************************************************
drop if missing(date)

* Baseline dependent variable is vwretd
drop if missing(vwretd)


* 6) One obs per day (defensive)
****************************************************
sort date
by date: keep if _n==1


order date vwretd vwretx sprtrn ewretd ewretx
sort date

save "$data_int/CRSP_clean.dta", replace
