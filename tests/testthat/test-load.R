test_that("nte_load returns a tibble with expected columns", {
  d <- nte_load()
  expect_s3_class(d, "tbl_df")
  expect_true(all(c("country", "year", "issue_area", "text") %in% names(d)))
})

test_that("nte_subset filters to IPR by default", {
  ipr <- nte_subset()
  expect_true(all(grepl("INTELLECTUAL PROPERTY", ipr$issue_area)))
})

test_that("nte_subset honors years and countries arguments", {
  out <- nte_subset(years = 2005:2010, countries = "CHINA")
  expect_true(all(out$year %in% 2005:2010))
  expect_true(all(out$country == "CHINA"))
})

test_that("nte_ipr_scored returns the deberta_score column", {
  d <- nte_ipr_scored()
  expect_true("deberta_score" %in% names(d))
  expect_type(d$deberta_score, "double")
})
