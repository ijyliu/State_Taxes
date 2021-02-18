*Benchmarking_Tax_Data.do

*Internal Benchmarks
*Check NBER versus Tax Foundation Data on the Personal Income Tax

*External Benchmarks
*Check early year data versus Giroud's

********************************************************************************

*Internal Benchmarks

*Append together all Tax Foundation Personal Files
clear
forvalues year = 2010/2020 {

    append using "Input/Personal/Pers_Clean_`year'"

    replace year = `year' if missing(year)

}

*avoid name conflict
rename Pers_Rate Pers_Rate_TF

*merge in NBER data
*Keep only matched years for the comparison
merge 1:1 year State using "Input/Personal/NBER_Clean"
keep if _m == 3
drop _m

rename Pers_Rate Pers_Rate_NBER

reg Pers_Rate_TF Pers_Rate_NBER, robust

gen diff_Pers_Rate = Pers_Rate_TF - Pers_Rate_NBER

sum diff_Pers_Rate

histogram diff_Pers_Rate

order State year Pers_Rate_NBER Pers_Rate_TF diff_Pers_Rate

save "Input/Personal/TF_vs_NBER_Pers_Rate", replace

stop

********************************************************************************

*External Benchmarks

*Load Giroud's data
use state_name year cit sal pinc using "Input/Giroud_Rauh_2019/stata_tax_data", clear

rename state_name State

keep if year >= 2010

merge 1:1 year State using "Input/State_Taxes"
keep if _m == 3
drop _m

gen Corp_Diff = cit - Corp_Rate
gen Corp_Diff_Adj = cit - Corp_Rate_Adj

gen Pers_Diff = pinc - Pers_Rate

gen Sales_Diff = sal - Sales_Rate
gen Sales_Diff_Adj = sal - Sales_Rate_Adj

foreach tax_type in Corp Pers Sales {
	
	sum `tax_type'_Diff
	
	histogram `tax_type'_Diff
	
}

order State year cit Corp_Rate Corp_Diff Corp_Rate_Adj Corp_Diff_Adj pinc Pers_Rate Pers_Diff sal Sales_Rate Sales_Diff Sales_Rate_Adj Sales_Diff_Adj

save "Input/Giroud_Rauh_2019/Diff_w_Giroud", replace
