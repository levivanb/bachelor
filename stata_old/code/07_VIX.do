****************************************************
* IMPORT AND CLEAN VIX
****************************************************

clear all

use "$data_raw/vix.dta", clear

keep Date vix

rename Date date 

save "$data_int/vix_daily.dta", replace 
