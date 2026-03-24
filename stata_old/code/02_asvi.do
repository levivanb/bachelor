****************************************************
*IMPORT GOOGLE DATA AND GENERATE DSVI MEASURE + APPEND
****************************************************

clear all

local blocks "trends_2019_h2 trends_2020_h1 trends_2020_h2 trends_2021_h1 trends_2021_h2 trends_2022_h1 trends_2022_h2 trends_2023_h1 trends_2023_h2 trends_2024_h1 trends_2024_h2"

foreach b of local blocks {

    * --- Import CSV ---
    import delimited "$data_raw/`b'.csv", clear stringcols(_all)

    * --- Parse date + basic cleaning ---
    gen double date_st = daily(date, "YMD")
    format date_st %td
    drop date
    rename date_st date

    destring tic svi, replace force
    replace query = strtrim(query)

    drop if missing(tic) | missing(date) | missing(svi) | svi <= 0
    gen str20 block = "`b'"

    * --- Rename raw SVI to make notation explicit ---
    rename svi SVI

    * --- Raw ΔSVI within tic within block ---
    sort tic date
    by tic: gen double dSVI = ln(SVI) - ln(SVI[_n-1])
    by tic: drop if _n == 1
    drop if missing(dSVI)

    * --- Winsorize dSVI at 2.5%/97.5% within tic ---
    gen double dSVI_w = dSVI
    by tic: egen double p025 = pctile(dSVI), p(2.5)
    by tic: egen double p975 = pctile(dSVI), p(97.5)
    replace dSVI_w = p025 if dSVI_w < p025
    replace dSVI_w = p975 if dSVI_w > p975
    drop p025 p975

    * --- Seasonality controls ---
    gen byte dow = dow(date)
    gen byte mon = month(date)

    * --- Deseasonalize within tic: weekday + month dummies ---
    gen double resid = .
    levelsof tic, local(tlist)

    foreach k of local tlist {

        quietly count if tic==`k' & !missing(dSVI_w, dow, mon)
        local N = r(N)

        if (`N' >= 30) {
            capture quietly regress dSVI_w i.dow i.mon if tic==`k'
            if (_rc==0) {
                capture drop rtmp
                quietly predict double rtmp if e(sample), resid
                replace resid = rtmp if tic==`k' & e(sample)
                drop rtmp
            }
            else {
                replace resid = dSVI_w if tic==`k'
            }
        }
        else {
            replace resid = dSVI_w if tic==`k'
        }
    }

    * --- Standardize within tic (after loop): this is adjusted ΔASVI_{j,t} ---
    by tic: egen double sd_resid = sd(resid)
    gen double dASVI = resid / sd_resid
    replace dASVI = . if sd_resid == 0 | missing(sd_resid)

    * --- Final keep ---
    keep date tic query SVI dSVI dASVI block
    order date tic query SVI dSVI dASVI block
    sort tic date

    * Optional: label variables for sanity
    label var SVI   "Google Trends Search Volume Index (raw, within block scaling)"
    label var dSVI  "Raw daily log change: ln(SVI_t)-ln(SVI_{t-1})"
    label var dASVI "Adjusted daily change (winsorized, deseasonalized, standardized), per term"

    save "$data_int/`b'_adj.dta", replace
}

**append** 

clear
local first = 1
foreach b of local blocks {
    if `first' {
        use "$data_int/`b'_adj.dta", clear
        local first = 0
    }
    else {
        append using "$data_int/`b'_adj.dta"
    }
}

sort tic date
drop if missing(date) | missing(dASVI)
save "$data_int/trends_all_adj.dta", replace
