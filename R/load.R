#' Load the section-level NTE corpus
#'
#' Returns the full bundled \code{NTEbysect} dataset as a tibble.
#'
#' @return A tibble with columns \code{country}, \code{year},
#'   \code{issue_area}, \code{text}.
#' @export
#' @examples
#' \dontrun{
#' corp <- nte_load()
#' dplyr::glimpse(corp)
#' }
nte_load <- function() {
  tibble::as_tibble(NTEbysect)
}


#' Subset the NTE corpus by issue area
#'
#' Filter the section-level corpus to one issue area. The default
#' \code{issue = "IPR"} matches the row set used in the published
#' analysis. Aliases are matched case-insensitively against the
#' \code{issue_area} column. Pass an exact heading from the data to
#' bypass aliasing.
#'
#' @param data A tibble in the shape returned by \code{nte_load()}.
#'   Defaults to the full corpus.
#' @param issue Character. One of the aliases listed in
#'   \code{issue_alias_table()} (e.g. \code{"IPR"}, \code{"SERVICES"},
#'   \code{"INVESTMENT"}, \code{"IMPORT"}, \code{"STANDARDS"},
#'   \code{"GOVT_PROCUREMENT"}, \code{"ECOMMERCE"}), or any literal
#'   substring of an \code{issue_area} heading.
#' @param years Optional integer vector of report years to keep.
#' @param countries Optional character vector of country names.
#' @return A tibble matching the schema of \code{data}.
#' @export
nte_subset <- function(data = nte_load(),
                       issue = "IPR",
                       years = NULL,
                       countries = NULL) {
  patterns <- issue_alias_table()
  pat <- patterns[[toupper(issue)]] %||% toupper(issue)
  out <- dplyr::filter(data, grepl(pat, toupper(.data$issue_area)))
  if (!is.null(years)) {
    out <- dplyr::filter(out, .data$year %in% years)
  }
  if (!is.null(countries)) {
    out <- dplyr::filter(
      out,
      toupper(.data$country) %in% toupper(countries)
    )
  }
  out
}


#' Pre-computed DeBERTa scores for IPR paragraphs
#'
#' Returns the bundled IPR paragraph dataset with hypothesis-alignment
#' scores from the fine-tuned DeBERTa-v3 model used in Park (2026,
#' working paper).
#'
#' @return A tibble with columns \code{country}, \code{year},
#'   \code{text}, \code{deberta_score}.
#' @export
nte_ipr_scored <- function() {
  tibble::as_tibble(NTE_IPR_scored)
}
