# Build script for nteText data objects.
# Run from the package root with: source("data-raw/build_data.R")

library(readr)
library(dplyr)
library(usethis)

raw_path <- normalizePath("~/nte_text", mustWork = TRUE)

# 1. NTEbysect, the section-level corpus.
# Renames the source column "body" to "text" for schema parity with
# NTE_IPR_scored.
NTEbysect <- read_csv(
  file.path(raw_path, "NTEbysect.csv"),
  show_col_types = FALSE
) |>
  rename(
    issue_area = `issue area`,
    text = body
  ) |>
  mutate(
    country = toupper(trimws(country)),
    issue_area = toupper(trimws(issue_area)),
    text = trimws(text)
  ) |>
  filter(!is.na(text), nchar(text) > 0)

# 2. NTE_IPR_scored, paragraph-level IPR with DeBERTa scores from the
# V3 revised model. NTE_IPR_final_v2.csv is the output of the V3
# colab notebook (an older NTE_IPR_final2.csv from a prior model run
# also exists in the working directory and should not be used here).
NTE_IPR_scored <- read_csv(
  file.path(raw_path, "NTE_IPR_final_v2.csv"),
  show_col_types = FALSE
) |>
  select(country, year, text, deberta_score) |>
  mutate(
    country = toupper(trimws(country)),
    text = trimws(text)
  ) |>
  filter(!is.na(text), nchar(text) > 0)

usethis::use_data(NTEbysect, overwrite = TRUE, compress = "xz")
usethis::use_data(NTE_IPR_scored, overwrite = TRUE, compress = "xz")
