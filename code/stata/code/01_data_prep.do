****************************************************
* DATA PREPARATION
* 1. Google Trends: import, clean, compute dASVI
* 2. CRSP market returns
* 3. EPU index
* 4. ETF daily returns
* 5. ADS business conditions index
* 6. VIX
* 7. Merge all into master dataset
****************************************************


****************************************************
* 1. IMPORT GOOGLE TRENDS AND GENERATE dASVI MEASURE
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

    label var SVI   "Google Trends Search Volume Index (raw, within block scaling)"
    label var dSVI  "Raw daily log change: ln(SVI_t)-ln(SVI_{t-1})"
    label var dASVI "Adjusted daily change (winsorized, deseasonalized, standardized), per term"

    save "$data_int/`b'_adj.dta", replace
}

* --- Append all blocks ---
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


****************************************************
* 2. IMPORT AND CLEAN CRSP DATA
****************************************************
clear all

use "$data_raw/CRSP.dta", clear

* Keep only variables needed
keep DlyCalDt YYYYMMDD vwretd vwretx ewretd ewretx sprtrn

* Create a clean Stata daily date
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

* Ensure returns are numeric
foreach v in vwretd vwretx ewretd ewretx sprtrn {
    capture confirm numeric variable `v'
    if _rc!=0 {
        destring `v', replace force
    }
}

drop if missing(date)
drop if missing(vwretd)

* One obs per day (defensive)
sort date
by date: keep if _n==1

order date vwretd vwretx sprtrn ewretd ewretx
sort date

save "$data_int/CRSP_clean.dta", replace


****************************************************
* 3. IMPORT AND CLEAN DAILY EPU INDEX
****************************************************

clear
import delimited "$data_raw/All_Daily_Policy_Data.csv", clear

destring day month year daily_policy_index, replace force

gen date = mdy(month, day, year)
format date %td

drop if date < td(01jan2019)

keep date daily_policy_index

sort date
duplicates drop date, force

rename daily_policy_index epu
label var epu "Economic Policy Uncertainty Index (daily)"

save "$data_int/epu_daily.dta", replace


****************************************************
* 4. GET ETF RETURNS
****************************************************

clear all

use "$data_raw/CRSP.dta", clear

keep if inlist(Ticker, "SPY", "QQQ", "QQQQ", "IWB", "IWM")

rename DlyCalDt date
format date %td

gen ret_etf = DlyRet

keep date PERMNO Ticker ret_etf DlyRetx DlyVol DlyClose

sort Ticker date

replace Ticker = "QQQ" if Ticker=="QQQQ"

levelsof Ticker, local(etfs)

foreach t of local etfs {

    preserve
        keep if Ticker=="`t'"
        keep date PERMNO Ticker ret_etf DlyRetx DlyVol DlyClose
        sort date

        save "$data_int/ETF_`t'_daily.dta", replace
    restore
}


****************************************************
* 5. IMPORT AND CLEAN ADS INDEX
****************************************************

clear all

import excel "$data_raw/ADS_Index_Most_Current_Vintage.xlsx", firstrow clear

rename ADS_Index ads

gen date = date(A, "YMD")
format date %td
drop A

destring ads, replace force

drop if date < td(01jan2019)

keep date ads

sort date
duplicates drop date, force

label var ads "Aruba–Diebold–Scotti Business Conditions Index"

save "$data_int/ads_daily.dta", replace


****************************************************
* 6. IMPORT AND CLEAN VIX
****************************************************

clear all

use "$data_raw/vix.dta", clear

keep Date vix

rename Date date

save "$data_int/vix_daily.dta", replace


****************************************************
* 7. MERGE ALL INTO MASTER DATASET
****************************************************

clear all

use "$data_int/trends_all_adj.dta", clear

merge m:1 date using "$data_int/CRSP_clean.dta", keep(match) nogenerate

merge m:1 date using "$data_int/epu_daily.dta", keep(master match) nogenerate
merge m:1 date using "$data_int/ads_daily.dta", keep(master match) nogenerate
merge m:1 date using "$data_int/vix_daily.dta", keep(master match) nogenerate

sort tic date

save "$data_int/mrkt_google_controls.dta", replace
