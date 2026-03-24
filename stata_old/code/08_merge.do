****************************************************
* MERGE CRSP WITH ALL CONTROL VARIABLES
****************************************************

clear all

use "$data_int/trends_all_adj.dta", clear

* Merge returns (this defines your usable sample for market-return regressions)
merge m:1 date using "$data_int/CRSP_clean.dta", keep(match) nogenerate

* Macros: keep earlier dates even if missing
merge m:1 date using "$data_int/epu_daily.dta", keep(master match) nogenerate
merge m:1 date using "$data_int/ads_daily.dta", keep(master match) nogenerate
merge m:1 date using "$data_int/vix_daily.dta", keep(master match) nogenerate

sort tic date


save "$data_int/mrkt_google_controls.dta", replace 

