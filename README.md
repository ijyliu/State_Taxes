# State_Taxes

The main data files of 2010-2020 state corporate, personal, and sales taxes with unadjusted and adjusted rates are [State_Taxes.dta](State_Taxes.dta) in Stata dta format, and [State_Taxes.csv](State_Taxes.csv), which is the same, but converted to a csv file. The dta is produced by [Process_State_Taxes.do](Process_State_Taxes.do) and [Convert_State_Taxes_To_CSV.R](Convert_State_Taxes_To_CSV.R) handles the conversion to csv.

Also included in the "Input" folder are several files from [Giroud & Rauh (2019)](http://www.columbia.edu/~xg2285/Taxes.pdf) which can be downloaded [here](http://www.columbia.edu/~xg2285/).

[Benchmarking_Tax_Data.do](Benchmarking_Tax_Data.do) performs an internal comparison of the NBER and Tax Foundation personal income tax rates and and external comparison of this project's rates with those from Giroud & Rauh (2019) for overlapping years.

## Data Sources

### Corporate Income Taxes

Initial data for the variable "Corp_Rate" comes from the Tax Policy Center.

* 2010-2020:
  https://www.taxpolicycenter.org/statistics/state-corporate-income-tax-rates

For the variable "Corp_Rate_Adj", various adjustments are made for items such as temporary surtaxes and surcharges and accounting methods; these adjustments are detailed in the code, along with links to sources.

### Personal Income Taxes

Initial data for the variable "Pers_Rate" comes from NBER Taxsim (2010-2018) and the Tax Foundation (2019-2020).

* 2010-2018:
  http://users.nber.org/~taxsim/state-rates/maxrate.html
* 2018-2020 (the file also contains 2015-2017 data):
  https://taxfoundation.org/state-individual-income-tax-rates-and-brackets-for-2020/

For the variable "Pers_Rate_Adj", Tax Foundation data is used for the entire period 2010-2020.

* 2010-2014:
  https://taxfoundation.org/state-individual-income-tax-rates/

### Sales Taxes

Initial data for the variable "Sales_Rate" comes from the Tax Foundation.

* 2010-2014:
  https://taxfoundation.org/state-sales-gasoline-cigarette-and-alcohol-tax-rates
* 2015:
  https://taxfoundation.org/state-and-local-sales-tax-rates-2015/
* 2016:
  https://taxfoundation.org/state-and-local-sales-tax-rates-2016/
* 2017:
  https://taxfoundation.org/state-and-local-sales-tax-rates-in-2017/
* 2018:
  https://taxfoundation.org/state-and-local-sales-tax-rates-2018/
* 2019:
  https://taxfoundation.org/sales-tax-rates-2019/
* 2020:
  https://taxfoundation.org/2020-sales-taxes/

For the variable "Sales_Rate_Adj", various adjustments are made for items such as gross receipts taxes; these adjustments are detailed in the code, along with links to sources.
