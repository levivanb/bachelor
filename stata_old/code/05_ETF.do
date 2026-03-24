****
*Gets ETF returns
****

clear all

use "$data_raw/CRSP.dta", clear

* Keep only the ETFs of interest
keep if inlist(Ticker, "SPY", "QQQ", "QQQQ", "IWB", "IWM")

* Use CRSP calendar date directly
rename DlyCalDt date
format date %td

* Daily total return (includes dividends)
gen ret_etf = DlyRet

* Keep only what you need
keep date PERMNO Ticker ret_etf DlyRetx DlyVol DlyClose

sort Ticker date

replace Ticker = "QQQ" if Ticker=="QQQQ"

* Save one .dta per ETF
levelsof Ticker, local(etfs)

foreach t of local etfs {

    preserve
        keep if Ticker=="`t'"
        keep date PERMNO Ticker ret_etf DlyRetx DlyVol DlyClose
        sort date

        save "$data_int/ETF_`t'_daily.dta", replace
    restore
}
