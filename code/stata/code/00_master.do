****************************************************
* MASTER DO FILE
* Runs all analysis files in order.

* --- Required packages ---
ssc install estout       // esttab, estadd, estpost, est sto
ssc install xtbreak      // structural break tests (54_volatility, 55_BREAKS_Returns)
ssc install distinct     // distinct PERMNO in downside deciles (52_Downside_Deciles)
ssc install scheme-burd  // set scheme burd in 00_master.do
****************************************************

clear all
set more off, perm

* --- Globals ---
global code "/Users/levivanboekel/Desktop/clean_code/stata/code"
do "$code/global.do"

* --- Graph settings ---
graph set window fontface "Garamond"
set scheme burd

* --- Data preparation ---
do "$code/01_data_prep.do"

* --- Baseline analysis (full sample, 30 terms) ---
do "$code/02_baseline.do"

* --- Subperiod analysis (time-varying regressions) ---
do "$code/03_subperiods.do"

* --- Robustness: alternative number of terms (35 and 25) + old FEARS ---
do "$code/04_robustness.do"

* --- Portfolio analysis, volatility, structural breaks ---
do "$code/05_portfolio_volatility_breaks.do"
