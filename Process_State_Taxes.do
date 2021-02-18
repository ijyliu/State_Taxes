*Process_State_Taxes.do

*Process State Tax Files

*Also includes adjusted tax rates based on further investigation

*Notes
*GRT, or Gross Receipts Taxes are classified as Sales Taxes for my purposes, though they are sometimes considered corporate income taxes.

********************************************************************************

*Corporate

forvalues year = 2010/2020 {

    import excel "Input/Corporate/state_corporate_income_tax_3.xlsx", sheet("`year'") case(preserve) clear
	
    if `year' == 2018 {
        rename B A
        rename C B
    }

    keep A B

    gen year = .

    replace A = strtrim(A)

    rename A State
    rename B Corp_Rate

    drop if missing(State)

    merge 1:1 State using "Input/State_Names", keepusing(State)
    keep if _m == 2 | _m == 3
    drop _m
	
	drop if missing(State)
	
    *clean the B values/tax rates

    *remove non-numeric, non-space, non-period symbols
    *handle surcharges
    replace Corp_Rate = regexr(Corp_Rate, "[0-9]+\%", "")
    *space out cases where there is a - then a number directly
    replace Corp_Rate = "- " + regexs(1) if regexm(Corp_Rate, "-([0-9\.]+)")

    *run regex replace code 1000 times, should be enough
    forvalues i = 1/1000 {
        replace Corp_Rate = regexr(Corp_Rate, "[^0-9\. ]", "")
    }
    
    replace Corp_Rate = strtrim(Corp_Rate)
    replace Corp_Rate = stritrim(Corp_Rate)

    *Take the maximum corp rate
    replace Corp_Rate = regexs(1) if regexm(Corp_Rate, " ([0-9\.]+)$")

    destring Corp_Rate, replace

    replace year = `year'

    compress
	
    save "Input/Corporate/Corp_Clean_`year'", replace

}

clear

forvalues year = 2010/2020 {

    append using "Input/Corporate/Corp_Clean_`year'"

}

********************************************************************************

*Fill in absent years/states in the panel with missing values, for convenience
encode State, gen(State_f)
tsset State_f year
tsfill
drop State_f

*For the baseline estimate, missing values do actually represent no corporate income tax
replace Corp_Rate = 0 if missing(Corp_Rate)

********************************************************************************

*Correction: 

*Delaware's corporate tax rate appears to be misclassified in some years, but in reality it is 8.7% across the entire period
replace Corp_Rate = 8.7 if State == "Delaware"

********************************************************************************

*Resolving differences with Giroud on Corporate Taxes

*Kansas- Giroud always adds the 3.05 or 3% surtax, I only do this for the adjusted value

*Massachussetts 2010 - Giroud cites 8.8%, versus my 8.75%. 8.75% appears to be correct: https://www.google.com/search?client=firefox-b-1-d&q=massachussets+corporate+income+tax+2010.

*Ohio- Giroud puts down a 26% corporate tax which seems excessive. That's basically as high as the federal rate! Maybe this is a mistype of the 0.26% CAT tax. I classified that as a sales tax btw. https://www.upcounsel.com/ohio-corporate-income-tax

*Texas- Giroud puts down the gross receipts tax, which I classified as sales

*Connecticut 2012- Giroud adds a 20% surtax, which I only do for the adjusted value

*Indiana 2012- Giroud is 0.5% lower than me. Probably due to the fact there was a phased decrease of 0.5% every year around that time, we are just treating middle of the year differences differently. https://www.areadevelopment.com/stateresources/indiana/indiana-basic-business-taxes-2012-46615.shtml

*West Virginia 2012- Giroud has 7.75% which is higher than me. But independently, the tax foundation states the rate was 7.75%, so I think the spreadsheet I have is wrong. https://taxfoundation.org/west-virginia-reduces-franchise-tax-corporate-income-tax/
*This is a one-time blip, the rest of the spreadsheet WV values line up
replace Corp_Rate = 7.75 if State == "West Virginia" & year == 2012

********************************************************************************

*Create a new variable with adjusted corporate rates. These are things such as surtaxes/surcharges, gross receipts taxes, accounting adjustments, etc.
gen Corp_Rate_Adj = Corp_Rate

********************************************************************************

*I examine Giroud's guidance first. However, I disagree with his classification of GRTs (Gross Receipt Taxes) as corporate income taxes, and I instead classify them as sales taxes. Therefore, for me relative to him:

*The Ohio GRT is Classified as Sales Tax

*Michigan : The Income Component of the Single Business Tax in 2010-2011 is already accounted for in Tax Foundation data (and the GRT component counted as a Sales Tax)

*Washington State's B & O Classified as Sales Tax

*Texas' corporate franchise tax/GRT is classified as a Sales Tax

********************************************************************************

*Other items the Tax Foundation notes on individual sheets which I deemed needing adjustment

********************************************************************************

*Accounting Adjustments
*These are taxes on income earned within a state's borders, so called "water's edge" accounting. In this situation, the corporation agrees to be taxed only for sales within the state. A large coropation would probably make use of this accounting.

*Montana's corporate income tax rate increases to 7% if water's edge accounting is used
replace Corp_Rate_Adj = 7 if State == "Montana"

*North Dakota water's edge adjustment for all years
replace Corp_Rate_Adj = Corp_Rate + 3.5 if State == "North Dakota"

********************************************************************************

*Special taxes

*Massachussetts Assets and Property Surcharge. This was included in the tax foundation calculation for 2010. It is $2.60 per $1000 of taxable tangible property.
*Let us assume tangible assets are 20 times net income (what would be taxed at the corporate rate)
replace Corp_Rate_Adj = Corp_Rate + (Corp_Rate * 20 * 0.0026) if State == "Massachussetts" & year != 2010

********************************************************************************

*Surcharges and Surtaxes

*Kansas surtax on corp income over 50K. Here I am computing values for a large corporation, so I'll just assume that income is way over 50K and hence the 3% is just added on (effectively making this a marginal corporate income tax rate)
*higher surtax/surcharge in 2010
replace Corp_Rate_Adj = Corp_Rate + 3.05 if State == "Kansas" & year == 2010
*lower rate from 2011 on
replace Corp_Rate_Adj = Corp_Rate + 3 if State == "Kansas" & year >= 2011

*Connecticut 2009-2011 surcharge of 10% for corporations with gross sales of $100m or more not paying the minimum tax: https://portal.ct.gov/DRS/Publications/Informational-Publications/2010/IP-201020-Business-Taxes
replace Corp_Rate_Adj = Corp_Rate + 0.1 * Corp_Rate if State == "Connecticut" & (year == 2010 | year == 2011)
*Connecticut 20% surcharge for 2012-2018
replace Corp_Rate_Adj = Corp_Rate + 0.2 * Corp_Rate if State == "Connecticut" & year >= 2012 & year <= 2018
*10% surcharge in 2019 and 2020 (decreased from 20% in 2018): https://www.cohencpa.com/insights/articles/connecticut-passes-house-bill-enacting-changes, https://www.blumshapiro.com/insights/connecticut-budget-what-you-need-to-know/
replace Corp_Rate_Adj = Corp_Rate + 0.1 * Corp_Rate if State == "Connecticut" & (year == 2019 | year == 2020)

*North Carolina 2009-2010 3% surcharge. However, the state expanded business tax credits also.
replace Corp_Rate_Adj = Corp_Rate + 0.03 * Corp_Rate if State == "North Carolina" & year == 2010

*Michigan's Single Business Tax (SBT) 2010 and 2011 surcharge of 21.99% on corporate income not yet accounted for
replace Corp_Rate_Adj = Corp_Rate + 0.2199 * Corp_Rate if State == "Michigan" & (year == 2011 | year == 2010)
*(SBT was repealed by Rick Synder in 2012)

*New Jersey surtax for businesses with net income over 1 million
*NJ 4% surtax up until 7/1/10 not included (Corp_Rate + 0.04 * Corp_Rate)
*2018-2020 surtaxes
replace Corp_Rate_Adj = Corp_Rate + 2.5 if State == "New Jersey" & (year == 2018 | year == 2019)
replace Corp_Rate_Adj = Corp_Rate + 1.5 if State == "New Jersey" & year == 2020

********************************************************************************

save "Input/Corporate/Corp_Clean", replace

********************************************************************************

*Personal
import excel "Input/Personal/NBER State Income Rates Recent.xlsx", clear firstrow

des

rename Year year
drop StateID*

rename StateName State
replace State = "District of Columbia" if State == "Washington DC"

merge m:1 State using "Input/State_Names", keepusing(State)
keep if _m == 3
drop _m

rename StateRateWages Pers_Rate

*Fill in absent years/states in the panel with missing values, for convenience
encode State, gen(State_f)
tsset State_f year
tsfill
drop State_f

*For the baseline estimate, missing values do actually represent no personal income tax
replace Pers_Rate = 0 if missing(Pers_Rate)

********************************************************************************

*Resolving differences between Tax Foundation and NBER

*Many of the differences are small (probably due to NBER's calculations, versus Tax Foundation's simple statutory rates)

*NBER Corrections

*Hawaii 2017- NBER has 0%, tax foundation has 8.25%. Tax Foundation appears to be correct.
replace Pers_Rate = 8.25 if State == "Hawaii" & year == 2017

*WV 2015- NBER has 0%, TF has 6.5%, TF is clearly correct: https://tax.wv.gov/Documents/Reports/IncomeTaxes.JointSelectCommitteeOnTaxReform.pdf
replace Pers_Rate = 6.5 if State == "West Virginia" & year == 2015

*Iowa- NBER has always had a lower rate than Tax Foundation by over 3%. The higher rate is correct: https://ballotpedia.org/Historical_Iowa_tax_policy_information
replace Pers_Rate = Pers_Rate + 3 if State == "Iowa"
replace Pers_Rate = 8.98 if State == "Iowa" & year <= 2018 // https://www.halfpricesoft.com/2010/taxrate-Iowa-2010.asp, https://www.halfpricesoft.com/2011/taxrate-Iowa-2011.asp, https://www.halfpricesoft.com/2012/taxrate-iowa-2012.asp, https://www.halfpricesoft.com/2013/taxrate-iowa-2013.asp, https://tax.iowa.gov/sites/default/files/idr/Individual%20Income%20Tax%20Report%202014.pdf, https://www.tax-brackets.org/iowataxtable/2015
*https://tax.iowa.gov/iowa-tax-rate-history
*8.53 percent in 2019 https://www.creditkarma.com/tax/i/filing-an-iowa-state-tax-return and 2020 https://tax.iowa.gov/idr-announces-2020-interest-rates-standard-deductions-and-income-tax-brackets
replace Pers_Rate = 8.53 if State == "Iowa" & year >= 2019

*NY- NBER is consistently nearly 2% lower
* 8.82% for all years https://www.tax-brackets.org/newyorktaxtable/2011 (click through)
replace Pers_Rate = 8.82 if State == "New York"

*Louisiana- NBER is consistently about 2.5% lower
* 6% for all years (click through): https://www.tax-brackets.org/louisianataxtable/2011
replace Pers_Rate = 6 if State == "Louisiana"

*Alabama- NBER is consistently about 2% lower
* 5% for all years (click through): https://www.tax-brackets.org/alabamataxtable/2011
replace Pers_Rate = 5 if State == "Alabama"

*Hawaii - NBER is 9.91% in 2010, should by 11: https://www.tax-brackets.org/hawaiitaxtable/2011
replace Pers_Rate = 11 if State == "Hawaii" & year == 2010

*Nebraska- NBER is lower than should by by 1.33 in 2010-2013
replace Pers_Rate = Pers_Rate + 1.33 if State == "Nebraska" & (year >= 2010 & year <= 2013)

********************************************************************************

save "Input/Personal/NBER_Clean", replace

clear

*Prep Tax Foundation 2010 to 2014 excel files
forvalues year = 2010/2014 {

    import excel "Input/Personal/State-Individual-Income-Tax-Rates-2000-2014.xlsx", clear sheet("`year'") case(preserve)
	
	des
	
	if `year' == 2010 {
		keep A C
		rename C Pers_Rate
	}

	if `year' >= 2011 {
		keep A B
		rename B Pers_Rate
	}
	
	replace A = "" if regexm(A, "Single")
	replace A = "" if regexm(A, "Couple")
	replace A = "" if regexm(A, "Source")
	
	gen year = `year'
	
    replace A = strtrim(A)

	local convention = "TF_Early_Pers"
	
    rename A `convention'
    
	des
	
	*clean up rates
	forvalues i = 1/1000 {
        replace Pers_Rate = regexr(Pers_Rate, "[^0-9\. ]", "")
    }
	
	replace Pers_Rate = strtrim(Pers_Rate)
	
	*clean up state abbreviations
	*wipe out rest of line after and including starting parentheses
	replace `convention' = regexs(1) if regexm(`convention', "(.+)\(")
	
	*any line still containing an open parentheses (starting with an open parentheses) should be set to blank
	replace `convention' = "" if regexm(`convention', "\(")
	*for weird cases where there is still closing parentheses on a line, wipe out that entire line
	replace `convention' = "" if regexm(`convention', "\)")
	
	*Fill in the states
	replace `convention'=`convention'[_n-1] if missing(`convention')
	
	replace Pers_Rate = stritrim(Pers_Rate)
	replace Pers_Rate = strtrim(Pers_Rate)
	
	replace Pers_Rate = "" if regexm(Pers_Rate, "\.\.")
	replace Pers_Rate = "" if regexm(Pers_Rate, " ")
	
	destring Pers_Rate, replace
	replace Pers_Rate = Pers_Rate * 100 if Pers_Rate < 1
	
	collapse (max) Pers_Rate, by(`convention' year)
	
	replace `convention' = stritrim(`convention')
	replace `convention' = strtrim(`convention')
	
    merge 1:1 `convention' using "Input/State_Names", keepusing(State)	
	keep if _m == 2 | _m == 3
	drop _m `convention'
	
	drop if missing(State)
	
	*Fill in absent years/states in the panel with missing values, for convenience
	encode State, gen(State_f)
	tsset State_f year
	tsfill
	drop State_f

	*For the baseline estimate, missing values do actually represent no personal income tax
	replace Pers_Rate = 0 if missing(Pers_Rate)
	
	drop if missing(State)
	
	********************************************************************************
	
	*Resolving differences between Tax Foundation and NBER

	*TF Corrections
	
	*Tennessee had the "Hall Income Tax" during the entire period. This was the only personal income tax and it was on interest and dividend income: https://en.wikipedia.org/wiki/Hall_income_tax
	*NBER marks this as no tax and I will too.
	replace Pers_Rate = 0 if State == "Tennessee"
	
	*There was a similar case for New Hampshire: https://www.google.com/search?client=firefox-b-1-d&q=new+hampshire+personal+income+tax+2015
	replace Pers_Rate = 0 if State == "New Hampshire"
	
	*Maine: https://www.tax-brackets.org/mainetaxtable/2011, Tax Foundation's number is just wrong
	replace Pers_Rate = 8.5 if State == "Maine" & year == 2010
	
	*Minnesota 2013 too low: https://www.tax-brackets.org/minnesotataxtable/2014
	replace Pers_Rate = 9.85 if State == "Minnesota" & year == 2013
	
	*Oregon 2010 and 2011- TF too low: https://www.tax-brackets.org/oregontaxtable/2011
	replace Pers_Rate = 9.9 if State == "Oregon" & (year == 2010 | year == 2011)
	
	*RI 2010- TF too high by a lot: https://www.tax-brackets.org/rhodeislandtaxtable/2011
	replace Pers_Rate = 5.99 if State == "Rhode Island" & year == 2010
	
	*ND 2011 - TF too high: https://www.tax-brackets.org/northdakotataxtable/2012
	replace Pers_Rate = 3.99 if State == "North Dakota" & (year == 2010 | year == 2011)
	
	********************************************************************************
	
    save "Input/Personal/Pers_Clean_`year'", replace

}

clear

*Prep Tax Foundation 2015 to 2020 excel files for comparison with NBER, though we will only use 2019-2020 (after NBER stops)
forvalues year = 2015/2020 {

    import excel "Input/Personal/State-Individual-Income-Tax-Rates-and-Brackets-for-2020-U.xlsx", clear sheet("`year'") case(preserve)

	des
	
    keep A B D

	gen year = `year'
	
    replace A = strtrim(A)

    rename A TF_Abb_Short
    rename B Pers_Rate

	des
	
	*clean up rates and brackets
	forvalues i = 1/1000 {
        replace Pers_Rate = regexr(Pers_Rate, "[^0-9\. ]", "")
    }
	
	drop if _n <= 2 | _n > 268
	
	replace Pers_Rate = strtrim(Pers_Rate)
	
	*clean up state abbreviations
	*wipe out rest of line after and including starting parentheses
	replace TF_Abb_Short = regexs(1) if regexm(TF_Abb_Short, "(.+)\(")
	
	*any line still containing an open parentheses (starting with an open parentheses) should be set to blank
	replace TF_Abb_Short = "" if regexm(TF_Abb_Short, "\(")
	*for weird cases where there is still closing parentheses on a line, wipe out that entire line
	replace TF_Abb_Short = "" if regexm(TF_Abb_Short, "\)")
	
	*Fill in the state names
	replace TF_Abb_Short=TF_Abb_Short[_n-1] if missing(TF_Abb_Short)
	
	destring Pers_Rate, replace
	replace Pers_Rate = Pers_Rate * 100 if Pers_Rate < 1
	
	collapse (max) Pers_Rate, by(TF_Abb_Short year)
	
	replace TF_Abb_Short = strtrim(TF_Abb_Short)
	replace TF_Abb_Short = strtrim(TF_Abb_Short)
	
    merge 1:1 TF_Abb_Short using "Input/State_Names", keepusing(State)
	
	keep if _m == 2 | _m == 3
	drop _m TF_Abb_Short
	
	drop if missing(State)
	
	*Fill in absent years/states in the panel with missing values, for convenience
	encode State, gen(State_f)
	tsset State_f year
	tsfill
	drop State_f

	*For the baseline estimate, missing values do actually represent no personal income tax
	replace Pers_Rate = 0 if missing(Pers_Rate)
	
	drop if missing(State)
	
	********************************************************************************
	
	*Resolving differences between Tax Foundation and NBER

	*TF Corrections
	
	*Tennessee had the "Hall Income Tax" during the entire period. This was the only personal income tax and it was on interest and dividend income: https://en.wikipedia.org/wiki/Hall_income_tax
	*NBER marks this as no tax and I will too.
	replace Pers_Rate = 0 if State == "Tennessee"
	
	*There was a similar case for New Hampshire: https://www.google.com/search?client=firefox-b-1-d&q=new+hampshire+personal+income+tax+2015
	replace Pers_Rate = 0 if State == "New Hampshire"
	
	*Kentucky 2018 rate is too high versus NBER: https://www.tax-brackets.org/kentuckytaxtable/2019
	replace Pers_Rate = 5 if State == "Kentucky" & year == 2018
	
	********************************************************************************
	
    save "Input/Personal/Pers_Clean_`year'", replace

}

clear

forvalues year = 2019/2020 {

    append using "Input/Personal/Pers_Clean_`year'"

    replace year = `year' if missing(year)

}

*Fill in absent years/states in the panel with missing values, for convenience
encode State, gen(State_f)
tsset State_f year
tsfill
drop State_f

*For the baseline estimate, missing values do actually represent no personal income tax
replace Pers_Rate = 0 if missing(Pers_Rate)

save "Input/Personal/Pers_Clean_Tax_Foundation", replace

*append NBER and Tax Foundation data together
use "Input/Personal/NBER_Clean", clear
append using "Input/Personal/Pers_Clean_Tax_Foundation" //, gen(dataset)

********************************************************************************

*Fill in absent years/states in the panel with missing values, for convenience
encode State, gen(State_f)
tsset State_f year
tsfill
drop State_f

*For the baseline estimate, missing values do actually represent no personal income tax
replace Pers_Rate = 0 if missing(Pers_Rate)

********************************************************************************

*Resolving differences with Giroud on Personal Income Taxes

*Unclear why there should be any disagreement here really, we are both using NBER top marginal rates.
*maybe these were updated at some point? In this case, my numbers are more up to date, so should probably keep those

*California- every year I am 1.06% higher. But neither of us match this source: https://www.tax-brackets.org/californiataxtable/2012. So it's not really clear what's going on, I will just assume my NBER number is more current.

*Georgia- every year I am 0.34% higher. I am correct, the figure is 6%: https://www.tax-brackets.org/georgiataxtable/2010

*Oregon- Giroud is 0.85% higher, 1.75% higher, 0.68% higher. He is closer to 11% which is cited here: https://www.tax-brackets.org/oregontaxtable/2010. But I think the updated NBER number is good.

*Vermont- I am 0.12% higher in 2010, 2011, 2012

*Wisconsin- I am 1% higher in 2010, 2011, 2012

*Minnesota- Giroud 0.68% higher in 2011, 0.24% 2012

*DC - I am 0.45% higher in 2012

*Oklahoma - Giroud .22% higher in 2012

********************************************************************************

*Personal Income tax adjustments (none included for now)

*Not included are many tricky phase outs of standard deductions and other exemptions over certain amounts, federal tax deductions, etc.

*Also not included are county or city level income taxes (Tax Foundation datasets are somewhat incomplete/only cover some years).
*For example, weighted average local rates from the Tax Foundation’s 2019 State Business Tax Climate Index are as follows: 0.50% in Alabama; 0.63% in Delaware; 1.56% in Indiana; 0.22% in Iowa; 2.08% in Kentucky; 2.85% in Maryland; 1.70% in Michigan; 0.50% in Missouri; 0.50% in New Jersey; 1.87% in New York; 2.50% in Ohio; 0.38% in Oregon; and 2.94% in Pennsylvania.
*Eleven states have county- or city-level income taxes; the average rates expressed as a percentage of AGI within each jurisdiction are: 0.10% in Alabama; 0.19% in Delaware; 0.73% in Indiana; 0.11% in Iowa; 1.29% in Kentucky; 2.28% in Maryland; 0.17% in Michigan; 0.23% in Missouri; 1.49% in New York; 1.56% in Ohio; and 1.21% in Pennsylvania. In California, Colorado, Kansas, New Jersey, Oregon, and West Virginia, some jurisdictions have payroll taxes, flat-rate wage taxes, or interest and dividend income taxes. See Jared Walczak, “Local Income Taxes in 2019,” Tax Foundation, July 30, 2019, https://taxfoundation.org/local-income-taxes-2019/.

*Delaware tax on lump sum distributions- there is no record of this, so it's amount is unclear

*Hawaii supposedly had a 0.5 percent tax on business entities not a corporation tax (individuals?) in 2020

********************************************************************************

save "Input/Personal/Pers_Clean", replace

********************************************************************************

*Tax foundation full coverage personal income taxes

clear

forvalues year = 2010/2020 {

    append using "Input/Personal/Pers_Clean_`year'"

    replace year = `year' if missing(year)

}

rename Pers_Rate Pers_Rate_Adj

save "Input/Personal/Fully_TF_Pers_Clean_2010_to_2020", replace

********************************************************************************

use "Input/Personal/Pers_Clean", clear

merge 1:1 State year using "Input/Personal/Fully_TF_Pers_Clean_2010_to_2020"
drop _m

save "Input/Personal/Pers_Clean", replace

********************************************************************************

*Sales

*Tax foundation sheets 2010-2014
forvalues year = 2010/2014 {

    import excel "Input/Sales/State Sales, Gasoline, Cigarette and Alcohol Taxes, 2000-2014.xlsx", clear sheet("`year'")

    keep A B

    replace A = strtrim(A)

    rename A TF_Abb_Long
    rename B Sales_Rate
	
	drop if missing(TF_Abb_Long)
	
    merge 1:1 TF_Abb_Long using "Input/State_Names", keepusing(State)
    keep if _m == 2 | _m == 3
    drop _m TF_Abb_Long

	drop if missing(State)
	
    *clean the B values/tax rates

    *remove non-numeric, non-space, non-period symbols
	forvalues i = 1/1000 {
		replace Sales_Rate = regexr(Sales_Rate, "[^0-9\. ]", "")
	}
    replace Sales_Rate = strtrim(Sales_Rate)
    replace Sales_Rate = stritrim(Sales_Rate)

	gen year = `year'
	
    save "Input/Sales/Sales_Clean_`year'", replace

}

* Tax foundation individual files 2015-2020
forvalues year = 2015/2020 {

    import excel "Input/Sales/Tax_Foundation_`year'_Sales.xlsx", clear
	
    keep A B

    gen year = `year'

	*Clean state names/abbs
    replace A = strtrim(A)
	
	*Clean state names and tax rates
	forvalues i = 1/1000 {
        replace A = regexr(A, "\(.+\)", "")
		replace B = regexr(B, "[^0-9\. ]", "")
    }
	
	replace A = strtrim(A)
	replace A = stritrim(A)
	replace B = strtrim(B)
	replace B = stritrim(B)
	
	*A represents different TF naming conventions based on the year
	if `year' <= 2014 {
		local convention = "State"
	}
	if `year' >= 2015 & year != 2019 {
		local convention = "State_w_DC_Abb"
	}
	if `year' == 2019 {
		local convention = "TF_Abb_Short"
	}
	
    rename A `convention'
    rename B Sales_Rate
	
    merge 1:1 `convention' using "Input/State_Names", keepusing(State)
	cap drop State_w_DC_Abb
	cap drop TF_Abb_Short
	keep if _m == 3
    drop _m
	
    save "Input/Sales/Sales_Clean_`year'", replace

}

clear
forvalues year = 2010/2020 {

    append using "Input/Sales/Sales_Clean_`year'"

}

destring Sales_Rate, replace
replace Sales_Rate = Sales_Rate * 100 if Sales_Rate < 1

********************************************************************************

*Fill in absent years/states in the panel with missing values, for convenience
encode State, gen(State_f)
tsset State_f year
tsfill
drop State_f

*For the baseline estimate, missing values do actually represent no sales income tax
replace Sales_Rate = 0 if missing(Sales_Rate)

********************************************************************************

*Resolving differences with Giroud on Sales Taxes

*Most differences are just numeric/tiny, ie -4.44e-16 higher for me in 2010 in Colorado

*Missouri, Minnesota, New Mexico - He is 0.005% higher in some years.
*Minnesota for example, the correct figure is 6.875%: https://www.google.com/search?client=firefox-b-1-d&q=minnesota+2010+sales+tax
*So in these cases, I think he rounded. I will not make changes then.

*New Mexico 2011 might be a problem though. I am 0.125% higher. But I match this source: https://taxfoundation.org/ranking-state-and-local-sales-taxes-1/

********************************************************************************

*Sales tax adjustments

*These are all gross receipts taxes, which may be counted as sales taxes or corporate taxes.
gen Sales_Rate_Adj = Sales_Rate

*Arizona's 5.6% GRT is included already

*New Mexico technically has a GRT, but the sales tax rate listed by the Tax Foundation is accurate
*(Some sources give a higher tax rate, but this is including local taxes: https://www.taxjar.com/states/new-mexico-sales-tax-online/)

*Delaware's GRT
*2009: top GR rate was 1.92%: https://www.youngconaway.com/content/uploads/2018/06/Delaware-Gross-Receipts-Tax.pdf
*this increase phased out in 2012: https://www.salestaxinstitute.com/resources/delaware-temporarily-increases-gross-receipts-tax-rates
replace Sales_Rate_Adj = Sales_Rate + 1.92 if State == "Delaware" & (year >= 2009 & year <= 2012)
*Unclear what the max rate in 2013 was, but these is some evidence for 1.53% if taxes reverted as described in the previous link: https://revenuefiles.delaware.gov/docs/tim2008-01.pdf
replace Sales_Rate_Adj = Sales_Rate + 1.536 if State == "Delaware" & (year == 2013)
*2014: https://financefiles.delaware.gov/docs/bus_occup_lic.pdf
replace Sales_Rate_Adj = Sales_Rate + 1.9914 if State == "Delaware" & (year >= 2014 & year <= 2019)
*2020: https://revenue.delaware.gov/frequently-asked-questions/gross-receipts-tax-faqs/
replace Sales_Rate_Adj = Sales_Rate + 0.7468 if State == "Delaware" & year == 2020
*replace Sales_Rate_Adj = Sales_Rate + 2.0736 if State == "Delaware" https://www.upcounsel.com/delaware-gross-receipts-tax#gross-receipts-tax-vs-sales-tax
*There is also a more complex franchise tax calculation based on the number of shares outstanding
*According the the tax foundation, the Delaware GRT was up to 1.9914% in 2020, but no other sources support this: https://taxfoundation.org/state-gross-receipts-taxes-2020/

*Hawaii's GRT of 4% is included already

*Kentucky's LLET - lesser of 0.75 percent of gross profits or 0.095% of gross receipts
replace Sales_Rate_Adj = Sales_Rate + 0.095 if State == "Kentucky"

*Ohio: CAT tax of 0.26% on receipts over 1 million since 2005
replace Sales_Rate_Adj = Sales_Rate + 0.26 if State == "Ohio" & year >= 2005

*Washington State - B&O Tax with a top rate of 1.5%
*example source: https://evergreensmallbusiness.com/washington-state-business-occupation-taxes-a-primer/
replace Sales_Rate_Adj = Sales_Rate + 1.5 if State == "Washington" & (year != 2019 & year != 2020)
*However, for the past few years, there has been a surcharge on advanced computing services which adds to the this tax for certain industries. I add this on because large tech companies are a fair amount of Washington state's economy
* 2019 2.5% advanced computing services: https://clarknuber.com/articles/washington-legislature-enacts-bo-tax-rate-increase-and-real-estate-excise-tax-changes/, https://www.grantthornton.com/library/alerts/tax/2019/SALT/U-Z/WA-establishes-surcharge-on-service-businesses-05-30.aspx
replace Sales_Rate_Adj = Sales_Rate + 2.5 if State == "Washington" & year == 2019
* 2020 2.72% advanced computing services tax https://dor.wa.gov/taxes-rates/business-occupation-tax/workforce-education/select-advanced-computing-businesses
replace Sales_Rate_Adj = Sales_Rate + 2.72 if State == "Washington" & year == 2020
*According the the tax foundation, the Washington GRT was up to 3.3% in 2020, but no other sources support this: https://taxfoundation.org/state-gross-receipts-taxes-2020/

*Texas- Corporate Franchise Tax (really a GRT/Sales Tax)
*Older years: https://comptroller.texas.gov/taxes/franchise/forms/2010-franchise.php
replace Sales_Rate_Adj = Sales_Rate + 1 if State == "Texas" & year <= 2015
*More recent years: https://comptroller.texas.gov/taxes/franchise/forms/2018-franchise.php
replace Sales_Rate_Adj = Sales_Rate + 0.75 if State == "Texas" & year >= 2016

*2010-2011 Michigan gross receipts tax of 0.8%
replace Sales_Rate_Adj = Sales_Rate + 0.8 if State == "Michigan" & (year == 2011 | year == 2010)

*The tax foundation also has additional data on other gross receipt taxes: https://taxfoundation.org/state-gross-receipts-taxes-2020/

*Oregon, effective 2020: https://www.salestaxinstitute.com/resources/oregon-enacts-new-gross-receipts-tax
replace Sales_Rate_Adj = Sales_Rate + 0.57 if State == "Oregon" & year == 2020
*supposedly there was an earlier tax on corporate sales, but this was just a minimum corporate tax: https://www.ocpp.org/2017/05/10/blog20170510-oregon-gross-receipts-corporate-tax/
*The TF says this is a very low minimum, however, so I'll ignore it

*Nevada's Commerce Tax, enacted in 2015 and implemented after: https://taxfoundation.org/nevada-approves-commerce-tax-new-tax-business-gross-receipts/
replace Sales_Rate_Adj = Sales_Rate + 0.331 if State == "Nevada" & year >= 2016

*Tennessee: Gross business receipts tax state administered from 2009 on: https://www.bassberry.com/wp-content/uploads/Journal-of-Multistate-Taxation-and-Incentives-January-2017.pdf
*Per this document, the tax really started for be enforced on out of state businesses in 2013... unclear really what to pick as a start date
replace Sales_Rate_Adj = Sales_Rate + 0.03 if State == "Tennessee" & year >= 2009

*WV business franchise rate taxes on capital: https://tax.wv.gov/Documents/TSD/tsd200.pdf
replace Sales_Rate_Adj = Sales_Rate + 0.41 if State == "West Virginia" & year == 2010
replace Sales_Rate_Adj = Sales_Rate + 0.34 if State == "West Virginia" & year == 2011
replace Sales_Rate_Adj = Sales_Rate + 0.27 if State == "West Virginia" & year == 2012
replace Sales_Rate_Adj = Sales_Rate + 0.20 if State == "West Virginia" & year == 2013
replace Sales_Rate_Adj = Sales_Rate + 0.10 if State == "West Virginia" & year == 2014

********************************************************************************

*Special Taxes

*Similar to a GRT (except on expenses more or less), is the New Hampshire business enterprise tax- this is on all compensation paid or accrued, interest, and dividends, after special adjustments
*source: https://www.revenue.nh.gov/faq/business-enterprise.htm
replace Sales_Rate_Adj = Sales_Rate + 0.75 if State == "New Hampshire" & year <= 2016
replace Sales_Rate_Adj = Sales_Rate + 0.72 if State == "New Hampshire" & (year == 2017 | year == 2018)
replace Sales_Rate_Adj = Sales_Rate + 0.675 if State == "New Hampshire" & year == 2019
replace Sales_Rate_Adj = Sales_Rate + 0.60 if State == "New Hampshire" & year == 2020

********************************************************************************

save "Input/Sales/Sales_Clean", replace

********************************************************************************

*Property

********************************************************************************

*Create a big tax dataset with all the types together
use "Input/Corporate/Corp_Clean", clear

merge 1:1 year State using "Input/Personal/Pers_Clean"
drop _m

merge 1:1 year State using "Input/Sales/Sales_Clean"
drop _m

drop if missing(State)

*label variables
label var State "State"
label var year "Year"
label var Corp_Rate "Corporate Income Tax Rate"
label var Corp_Rate_Adj "Adjusted Corporate Income Tax Rate"
label var Pers_Rate "Personal Income Tax Rate, NBER and Tax Foundation Data"
label var Pers_Rate_Adj "Personal Income Tax Rate, Tax Foundation Data"
label var Sales_Rate "Sales Tax Rate"
label var Sales_Rate_Adj "Adjusted Sales Tax Rate"

save "State_Taxes", replace

********************************************************************************

*summary statistics on changes in taxes

order State year Corp_Rate Pers_Rate Sales_Rate

sort State year

foreach tax_type in Corp Pers Sales {

	gen change_`tax_type' = `tax_type'_Rate - `tax_type'_Rate[_n-1] if (year - year[_n-1] == 1 & State == State[_n-1])
	gen change_`tax_type'_Adj = `tax_type'_Rate_Adj - `tax_type'_Rate_Adj[_n-1] if (year - year[_n-1] == 1 & State == State[_n-1])
	
	*histogram changes
	histogram change_`tax_type'
	*you can save a figure here
	
	histogram change_`tax_type'_Adj
	*you can save a figure here

	*list (table for now) of changes
	tab change_`tax_type' if (change_`tax_type' != 0 & !missing(change_`tax_type'))
	tab change_`tax_type'_Adj if (change_`tax_type'_Adj != 0 & !missing(change_`tax_type'_Adj))

}

*Fraction of States with a change in personal income tax rates
gen change_Pers_Ind = (change_Pers != 0 & !missing(change_Pers))
gen change_Pers_Ind_Adj = (change_Pers_Adj != 0 & !missing(change_Pers_Adj))

*State level dataset of change or no
collapse (max) change_Pers_Ind change_Pers_Ind_Adj, by(State)

*Summarize for the share
sum change_Pers_Ind
sum change_Pers_Ind_Adj
