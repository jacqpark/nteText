.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "nteText loaded. nte_score_ipr() applies only to IPR text. ",
    "See vignette('extending', package = 'nteText') for details."
  )
}

utils::globalVariables(c("NTEbysect", "NTE_IPR_scored", ".data"))
