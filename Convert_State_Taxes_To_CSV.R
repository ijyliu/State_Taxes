
# R packages to convert Stata dta file to csv format
library('haven', 'readr', 'tidyverse')

# Read in data
tax_data <- read_dta('State_Taxes.dta')
print(tax_data)

# Reorder variables
tax_data <- dplyr::transmute(tax_data, year, State, Corp_Rate, Corp_Rate_Adj, Pers_Rate, Pers_Rate_Adj, Sales_Rate, Sales_Rate_Adj)
print(tax_data)

# Write data
write.csv(tax_data, 'State_Taxes.csv')
