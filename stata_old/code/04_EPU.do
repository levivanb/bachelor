****************************************************
* IMPORT AND CLEAN DAILY ECONOMIC UNCERTAINT INDEX (EPU)
****************************************************

clear
import delimited "$data_raw/All_Daily_Policy_Data.csv", clear

* Ensure numeric
destring day month year daily_policy_index, replace force

* Construct daily date
gen date = mdy(month, day, year)
format date %td

* DROP observations before 2019
drop if date < td(01jan2019)

* Keep only what we need
keep date daily_policy_index

* Sort and drop duplicates just in case
sort date
duplicates drop date, force

* Rename for clarity
rename daily_policy_index epu

label var epu "Economic Policy Uncertainty Index (daily)"

save "$data_int/epu_daily.dta", replace
