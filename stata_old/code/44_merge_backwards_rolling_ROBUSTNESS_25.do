****************************************************
*MERGE ALL PERIOD TOGETHER WITH DIFFERENT FEAR REFERENCES
****************************************************

clear all
set more off

local files ///
    $data_int/term_betas_25TERMS_jun2019_jan2020.dta ///
    $data_int/term_betas_25TERMS_jun2019_jul2020.dta ///
    $data_int/term_betas_25TERMS_jun2019_jan2021.dta ///
    $data_int/term_betas_25TERMS_jun2019_jul2021.dta ///
    $data_int/term_betas_25TERMS_jun2021_jan2022.dta ///
    $data_int/term_betas_25TERMS_jun2021_jul2022.dta ///
    $data_int/term_betas_25TERMS_jun2022_jan2023.dta ///
    $data_int/term_betas_25TERMS_jun2022_jul2023.dta ///
    $data_int/term_betas_25TERMS_jun2022_jan2024.dta ///
    $data_int/term_betas_25TERMS_jun2022_jul2024.dta

local first : word 1 of `files'
use `first', clear

local n : word count `files'
forvalues i = 2/`n' {
    local f : word `i' of `files'
    append using `f'
}

tab block

save "$data_int/fears_term_sets_all_blocks_ROBUSTNESS_25.dta", replace
