`%||%` <- function(a, b) if (is.null(a)) b else a


#' Issue-area alias table
#'
#' Maps short aliases to substring patterns matched against the
#' \code{issue_area} column of \code{NTEbysect}. Exposed so callers can
#' inspect and override.
#'
#' @return A named list of regex patterns.
#' @keywords internal
issue_alias_table <- function() {
  list(
    "IPR" = "INTELLECTUAL PROPERTY",
    "SERVICES" = "SERVICES BARRIERS|SERVICES",
    "INVESTMENT" = "INVESTMENT",
    "IMPORT" = "IMPORT POLICIES",
    "EXPORT" = "EXPORT SUBSIDIES|EXPORT",
    "STANDARDS" = "STANDARDS|TECHNICAL BARRIERS|SANITARY",
    "GOVT_PROCUREMENT" = "GOVERNMENT PROCUREMENT",
    "ANTICOMPETITIVE" = "ANTICOMPETITIVE|ANTI-COMPETITIVE",
    "ECOMMERCE" = "ELECTRONIC COMMERCE|DIGITAL TRADE",
    "OTHER" = "OTHER BARRIERS"
  )
}


token_frequencies <- function(data, remove_stopwords = TRUE) {
  toks <- quanteda::tokens(
    data[["text"]],
    remove_punct = TRUE,
    remove_numbers = TRUE
  )
  toks <- quanteda::tokens_tolower(toks)
  if (remove_stopwords) {
    toks <- quanteda::tokens_remove(toks, quanteda::stopwords("en"))
  }
  dfm <- quanteda::dfm(toks)
  freq <- quanteda.textstats::textstat_frequency(dfm)
  tibble::tibble(term = freq$feature, n = freq$frequency)
}


term_year_counts <- function(data, terms, normalize = TRUE) {
  per_term <- lapply(terms, function(tm) {
    pat <- stringr::regex(paste0("\\b", tm, "\\b"), ignore_case = TRUE)
    data |>
      dplyr::mutate(
        .count = stringr::str_count(.data[["text"]], pat),
        .ntok = stringr::str_count(.data[["text"]], "\\w+")
      ) |>
      dplyr::group_by(.data$year) |>
      dplyr::summarise(
        count = sum(.data$.count, na.rm = TRUE),
        n_tokens = sum(.data$.ntok, na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        term = tm,
        rate = if (normalize) {
          1000 * .data$count / pmax(.data$n_tokens, 1L)
        } else {
          .data$count
        }
      )
  })
  dplyr::bind_rows(per_term)
}
