test_that("nte_kwic returns matches", {
  ipr <- nte_subset()
  hits <- nte_kwic(ipr, keyword = "patent", window = 5)
  expect_s3_class(hits, "tbl_df")
  expect_gt(nrow(hits), 0)
})

test_that("issue_alias_table covers expected aliases", {
  tbl <- issue_alias_table()
  expect_true(all(c("IPR", "SERVICES", "INVESTMENT", "IMPORT") %in% names(tbl)))
})
