
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nteText

<!-- badges: start -->
<!-- badges: end -->

nteText provides National Trade Estimate (NTE) reports published
annually by the Office of the United States Trade Representative (USTR)
from 1995 to 2022 in a format of dataframe. This data features over 60
countries determined as prominent trade partners by the United States
and reorganized categories of trade concerns appearing most frequently
in the reports into 15 sections; Import Policies, Export Subsidies,
Standards, Labeling and Certification, Government Procurement,
Intellectual Property Rights, Services Barriers, Investment Barriers,
Anti-competitive Pratices, Technical Barriers to Trade, Sanitary and
Phytosanitary Barriers, E-commerce, Barriers to Digital Trade,
Agriculture, Trade Remedies and Other Barriers.

## Installation

You can install the development version of nteText from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("jacqpark/nteText")
```

## Example

You can fetch the dataset as follows:

``` r
library(nteText)
dt = data("nteText")
head(dt, 5)
#> [1] "nteText"
```
