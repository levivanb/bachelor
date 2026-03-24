clear all
set more off

*===============================================================================
* STEP 1: LOAD AND CLEAN CRSP DAILY DATA
*===============================================================================

* Adjust this path to wherever your CRSP data lives
use "$data_raw/crsp.dta", clear


* Parse date if needed
capture confirm variable DlyCalDt
if _rc==0 {
    * DlyCalDt may already be a Stata %td date; enforce format
    gen double date = DlyCalDt
    format date %td
}
else {
    * If only YYYYMMDD exists
    tostring YYYYMMDD, replace
    gen double date = daily(YYYYMMDD, "YMD")
    format date %td
}

drop DlyCalDt YYYYMMDD


* Keep only 2019 onward (need 2019 for rolling windows into 2020)
keep if year(date) >= 2019


keep if SecurityType == "EQTY"

* Keep major exchanges only
keep if inlist(PrimaryExch, "N", "A", "Q")

* Keep normal trading status
keep if TradingStatusFlg == "A"

* Keep usable observations
drop if missing(DlyRet, sprtrn, date)
drop if missing(DlyPrc)

keep if abs(DlyPrc) >= 5
keep if DlyCap >= 10000000

distinct PERMNO

* Keep needed variables only
keep PERMNO date DlyRet DlyVol DlyPrc DlyCap ShrOut vwretd sprtrn

* Rename for convenience
rename DlyRet ret
rename DlyVol volume
rename DlyPrc price
rename DlyCap mcap

* ── Drop problematic observations ──
drop if missing(date)

* Baseline dependent variable is vwretd
drop if missing(vwretd)


* ── Sort and set panel ──
sort PERMNO date
duplicates drop PERMNO date, force

* Create numeric panel id
egen firm_id = group(PERMNO)
xtset firm_id date, daily


gen year = year(date)


*===============================================================================
* STEP 1: COMPUTE ANNUAL MARKET MEAN RETURN
*===============================================================================

* Get one market return per date (sprtrn is repeated across stocks)
preserve
bysort date: keep if _n == 1
keep date year sprtrn
bysort year: egen double mkt_mean = mean(sprtrn)
keep date sprtrn mkt_mean
tempfile mkt_means
save `mkt_means'
restore

* Merge back
drop if missing(sprtrn)
merge m:1 date using `mkt_means', keep(match) nogenerate

* Flag down-market days
gen byte down_day = (sprtrn < mkt_mean)

tab down_day


*===============================================================================
* STEP 2: COMPUTE DOWNSIDE BETA AND DOWNSIDE SIGMA PER STOCK-YEAR
*===============================================================================

* ── Downside beta: regress r_i on r_m using only down days ──
* ── Downside sigma: std dev of r_i on down days ──

* Prepare: count down days per stock-year
bysort PERMNO year: egen int n_down = total(down_day) if !missing(ret)

* We need enough down days for a meaningful estimate
* Require at least 40 down-market days in the year
gen byte enough_down = (n_down >= 40)

* ── Method: collapse to stock-year level using statsby ──

preserve

* Keep downside-market observations with enough usable downside days
keep if down_day == 1 & enough_down == 1
keep if !missing(ret, sprtrn, PERMNO, year)

**************************************************
* 1. Downside sigma by stock-year
**************************************************
bysort PERMNO year: egen double ds_sigma = sd(ret)

* Keep one row per PERMNO-year for sigma
bysort PERMNO year: gen byte tag_sigma = (_n == 1)
tempfile sigma_vals
save "`sigma_vals'_raw", replace

use "`sigma_vals'_raw", clear
keep if tag_sigma == 1
keep PERMNO year ds_sigma
save "`sigma_vals'", replace

**************************************************
* 2. Downside beta by stock-year via statsby
**************************************************
restore
preserve

keep if down_day == 1 & enough_down == 1
keep if !missing(ret, sprtrn, PERMNO, year)

statsby ///
    ds_beta    = _b[sprtrn] ///
    ds_beta_se = _se[sprtrn] ///
    ds_nobs    = e(N), ///
    by(PERMNO year) clear: reg ret sprtrn

**************************************************
* 3. Merge downside sigma back in
**************************************************
merge 1:1 PERMNO year using "`sigma_vals'", keep(match) nogenerate

**************************************************
* 4. Drop unreliable estimates
**************************************************
drop if ds_nobs < 40
drop if missing(ds_beta, ds_sigma)

**************************************************
* 5. Winsorize at 1/99
**************************************************
foreach var in ds_beta ds_sigma {
    quietly summarize `var', detail
    replace `var' = r(p1)  if `var' < r(p1)  & !missing(`var')
    replace `var' = r(p99) if `var' > r(p99) & !missing(`var')
}

di _n "Downside beta summary:"
summarize ds_beta, detail

di _n "Downside sigma summary:"
summarize ds_sigma, detail

**************************************************
* 6. Create lagged characteristics for portfolio formation
* Characteristics estimated in year t are used in year t+1
**************************************************
rename year year_est
gen year = year_est + 1

order PERMNO year year_est ds_beta ds_sigma ds_beta_se ds_nobs
save "$data_int/downside_chars.dta", replace

restore


*===============================================================================
* STEP 3: ASSIGN DECILES
*===============================================================================

* Merge characteristics into daily data
* (year in daily data matches year_hold from characteristics)
merge m:1 PERMNO year using "$data_int/downside_chars.dta", ///
    keep(master match) nogenerate

* Only keep years where we have prior-year characteristics (2020+)
keep if !missing(ds_beta) & !missing(ds_sigma)

* Assign deciles within each year
foreach var in ds_beta ds_sigma {
    
    local dname `var'_decile
    gen `dname' = .
    
    forvalues y = 2020/2024 {
        capture xtile tmp = `var' if year == `y', nq(10)
        if _rc == 0 {
            replace `dname' = tmp if year == `y'
            drop tmp
        }
    }
}

tab ds_beta_decile, missing
tab ds_sigma_decile, missing


*===============================================================================
* STEP 4: COMPUTE DECILE SPREAD RETURNS
*===============================================================================

foreach proxy in ds_beta ds_sigma {
    
    di _n "Building `proxy' spread returns..."
    
    preserve
    
    keep if !missing(`proxy'_decile) & !missing(ret) & !missing(mcap)
    
    * Value weights
    bysort date `proxy'_decile: egen double tot_mcap = total(mcap)
    gen double wt = mcap / tot_mcap
    gen double ret_wt = ret * wt
    
    * Collapse to decile-date
    collapse (sum) vw_ret = ret_wt ///
             (mean) ew_ret = ret ///
             (count) n_stocks = ret, ///
        by(date `proxy'_decile)
    
    * Reshape wide
    reshape wide vw_ret ew_ret n_stocks, i(date) j(`proxy'_decile)
    
    * High minus low (decile 10 = high downside risk, decile 1 = low)
    gen `proxy'_hml_vw = vw_ret10 - vw_ret1
    gen `proxy'_hml_ew = ew_ret10 - ew_ret1
    
    label var `proxy'_hml_vw "High-Low `proxy' Spread (VW)"
    label var `proxy'_hml_ew "High-Low `proxy' Spread (EW)"
    
    * Quick summary
    sum `proxy'_hml_vw `proxy'_hml_ew
    
    keep date `proxy'_hml_vw `proxy'_hml_ew
    
    save "$data_int/`proxy'_spread_returns.dta", replace
    restore
}


*===============================================================================
* STEP 5: MERGE WITH FEARS AND RUN REGRESSIONS
*===============================================================================

use "$data_int/FEARS_daily_2019_2024.dta", clear
merge m:1 date using "$data_int/mrkt_google_controls.dta", keep(match) nogenerate
duplicates drop date, force

merge 1:1 date using "$data_int/ds_beta_spread_returns.dta", keep(master match) nogenerate
merge 1:1 date using "$data_int/ds_sigma_spread_returns.dta", keep(master match) nogenerate

sort date
gen long t = _n
tsset t

gen d_epu = D.epu
gen d_ads = D.ads

* Generate leads and lags for each spread
foreach spread in ds_beta_hml_vw ds_beta_hml_ew ds_sigma_hml_vw ds_sigma_hml_ew {
    gen `spread'_f1   = F.`spread'
    gen `spread'_f1f2 = F.`spread' + F2.`spread'
    
    forvalues i = 1/5 {
        gen `spread'_L`i' = L`i'.`spread'
    }
}

drop if missing(FEARS) | missing(d_epu) | missing(d_ads) | missing(vix)

