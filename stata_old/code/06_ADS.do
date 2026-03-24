****************************************************
* IMPORT AND CLEAN ADS INDEX 
****************************************************

clear all

import excel "$data_raw/ADS_Index_Most_Current_Vintage.xlsx", firstrow clear

rename ADS_Index ads

* Parse date in col A (format YYYY:MM:DD)
gen date = date(A, "YMD")
format date %td
drop A

* Ensure numeric
destring ads, replace force

* DROP observations before 2019
drop if date < td(01jan2019)

* Keep only what we need
keep date ads

* Sort and deduplicate
sort date
duplicates drop date, force

label var ads "Aruba–Diebold–Scotti Business Conditions Index"

save "$data_int/ads_daily.dta", replace
