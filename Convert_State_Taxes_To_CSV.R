
# R packages to convert Stata dta file to csv format
library('haven', 'readr')

# Read in data
tax_data <- read_dta('State_Taxes.dta')
print(tax_data)

# Write data
write.csv(tax_data, 'State_Taxes.csv')
