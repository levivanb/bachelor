clear all
set more off

**************************************************
*Load Deciles and clean*
**************************************************

* Beta
use "$data_raw/beta_deciles.dta", clear
describe
rename betan beta_decile
capture rename betav beta_value
keep PERMNO date beta_decile beta_value
duplicates drop PERMNO date, force
save "$data_int/beta_deciles_clean.dta", replace

bys beta_decile: summ beta_value


* Std dev
use "$data_raw/std_deciles.dta", clear
describe
rename sdevn std_decile
capture rename sdevv std_value
keep PERMNO date std_decile std_value
duplicates drop PERMNO date, force
save "$data_int/std_deciles_clean.dta", replace

bys std_decile: summ std_value

* Cap
use "$data_raw/capitilization_deciles.dta", clear
describe
rename capn cap_decile
capture rename capv cap_value
keep PERMNO date cap_decile cap_value
duplicates drop PERMNO date, force
save "$data_int/capitalization_deciles_clean.dta", replace

bys cap_decile: summ cap_value

******MERGE ALL DECILES TOGETHER****

use "$data_int/beta_deciles_clean.dta", clear
sort PERMNO date

merge 1:1 PERMNO date using "$data_int/std_deciles_clean.dta"
tab _merge
drop _merge

merge 1:1 PERMNO date using "$data_int/capitalization_deciles_clean.dta"
tab _merge
drop _merge

sort PERMNO date
save "$data_int/all_deciles_merged.dta", replace

**************************************************
*Load CRSP daily stock data and merge deciles onto it*
**************************************************
use "$data_raw/CRSP.dta", clear

keep PERMNO DlyCalDt DlyRet

rename DlyCalDt date

sort PERMNO date

merge m:1 PERMNO date using "$data_int/all_deciles_merged.dta"
tab _merge

drop _merge

sort PERMNO date


**************************************************
* Carry assignments forward within stock so 31dec2019 assignment is used after that date
**************************************************
by PERMNO (date): replace beta_decile = beta_decile[_n-1] if missing(beta_decile)
by PERMNO (date): replace beta_value  = beta_value[_n-1]  if missing(beta_value)

by PERMNO (date): replace std_decile  = std_decile[_n-1]  if missing(std_decile)
by PERMNO (date): replace std_value   = std_value[_n-1]   if missing(std_value)

by PERMNO (date): replace cap_decile  = cap_decile[_n-1]  if missing(cap_decile)
by PERMNO (date): replace cap_value   = cap_value[_n-1]   if missing(cap_value)


* drop dates before first assignment **
drop if missing(beta_decile) & missing(std_decile) & missing(cap_decile)
sort PERMNO date


**************************************************
* Beta decile daily returns and spread
**************************************************
preserve
    keep date DlyRet beta_decile
    drop if missing(beta_decile)

    * Equal-weighted daily return within each beta decile
    collapse (mean) beta_ret = DlyRet, by(date beta_decile)

    * Reshape so each decile becomes its own column
    reshape wide beta_ret, i(date) j(beta_decile)

    * High minus low spread
    gen beta_spread = beta_ret1 - beta_ret10

    save "$data_int/beta_daily_spread.dta", replace
restore

**************************************************
* Std decile daily returns and spread
**************************************************
preserve
    keep date DlyRet std_decile
    drop if missing(std_decile)

    * Equal-weighted daily return within each std decile
    collapse (mean) std_ret = DlyRet, by(date std_decile)

    * Reshape so each decile becomes its own column
    reshape wide std_ret, i(date) j(std_decile)

    * High minus low spread
    gen std_spread = std_ret1 - std_ret10

    save "$data_int/std_daily_spread.dta", replace
restore

**************************************************
* Cap decile daily returns and spread
**************************************************
preserve
    keep date DlyRet cap_decile
    drop if missing(cap_decile)

    * Equal-weighted daily return within each cap decile
    collapse (mean) cap_ret = DlyRet, by(date cap_decile)

    * Reshape so each decile becomes its own column
    reshape wide cap_ret, i(date) j(cap_decile)

    * High minus low spread
    gen cap_spread = cap_ret1 - cap_ret10

    save "$data_int/cap_daily_spread.dta", replace
restore

**************************************************
* 4. Merge all three spread datasets together
**************************************************

use "$data_int/beta_daily_spread.dta", clear

merge 1:1 date using "$data_int/std_daily_spread.dta"
drop _merge

merge 1:1 date using "$data_int/cap_daily_spread.dta"
drop _merge

keep date beta_spread std_spread cap_spread

sort date
save "$data_int/all_daily_spreads.dta", replace


