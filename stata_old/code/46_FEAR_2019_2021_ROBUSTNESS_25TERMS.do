****************************************************
* GENERATE FEAR VARIABLE FOR PERIOD 2019-2021
****************************************************

clear all
set more off

*============================================================
* 1) Build a date->block calendar (one block per day)
*============================================================
preserve
use "$data_int/mrkt_google_controls.dta", clear
keep date
duplicates drop
sort date

* Keep the FEARS period you care about
keep if date >= td(1jun2019) & date <= td(31dec2021)    // EDIT end date if needed

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

*============================================================
* 2) Create a block x tic lookup (30 tics per block)
*============================================================
use "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_25.dta", clear
keep tic block
duplicates drop

tempfile top30
save `top30', replace

*============================================================
* 3) Compute FEARS:
*    FEARS_t = mean(dASVI_{tic,t}) over the 30 tics active in block(t)
*============================================================
use "$data_int/mrkt_google_controls.dta", clear
keep date tic dASVI
drop if missing(date) | missing(tic) | missing(dASVI)

* Attach block to each date
merge m:1 date using `calendar', keep(match) nogenerate

* Keep only the 30 active tics for that block
merge m:1 block tic using `top30', keep(match) nogenerate

* Average across the 30 tics each day
bysort date: egen FEARS = mean(dASVI)

* How many terms contributed each day (target ~30, may be <30 if missing dASVI)
bysort date: egen n_terms = count(dASVI)

keep date FEARS n_terms
duplicates drop
sort date

save "$data_int/FEARS_daily_2019_2021_ROBUSTNESS_25TERMS.dta", replace
