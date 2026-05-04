#' Keyword in context
#'
#' Show concordance lines around a keyword across the NTE corpus or any
#' subset of it. Wraps \code{quanteda::kwic()}.
#'
#' @param data Corpus tibble. Defaults to \code{nte_load()}.
#' @param keyword Character. The token or phrase to search for.
#' @param window Integer. Number of tokens of context on each side.
#' @param case_insensitive Logical. Whether to ignore case while matching.
#' @return A tibble of keyword-in-context matches, one row per hit.
#' @export
nte_kwic <- function(data = nte_load(),
                     keyword,
                     window = 8L,
                     case_insensitive = TRUE) {
  corp <- as_quanteda_corpus(data)
  toks <- quanteda::tokens(corp)
  kw <- quanteda::kwic(
    toks,
    pattern = keyword,
    window = window,
    case_insensitive = case_insensitive
  )
  tibble::as_tibble(kw)
}


#' Comparative wordcloud across two slices of the corpus
#'
#' Build a side-by-side wordcloud comparing two subsets defined by
#' arbitrary filter expressions. Useful for contrasting countries,
#' years, or issue areas.
#'
#' @param data Corpus tibble.
#' @param group_a An expression evaluated against \code{data} to define
#'   the left-hand subset (e.g. \code{country == "CHINA"}).
#' @param group_b An expression evaluated against \code{data} to define
#'   the right-hand subset.
#' @param top_n Integer. Number of terms per side.
#' @param remove_stopwords Logical. Drop English stopwords before
#'   counting.
#' @return A ggplot object built with \code{ggwordcloud}.
#' @export
nte_wordcloud <- function(data = nte_load(),
                          group_a,
                          group_b,
                          top_n = 50L,
                          remove_stopwords = TRUE) {
  if (!requireNamespace("ggwordcloud", quietly = TRUE)) {
    stop("nte_wordcloud() requires the 'ggwordcloud' package.")
  }
  qa <- rlang::enquo(group_a)
  qb <- rlang::enquo(group_b)
  a <- dplyr::filter(data, !!qa)
  b <- dplyr::filter(data, !!qb)
  freqs_a <- utils::head(token_frequencies(a, remove_stopwords), top_n)
  freqs_b <- utils::head(token_frequencies(b, remove_stopwords), top_n)
  freqs_a$group <- rlang::as_label(qa)
  freqs_b$group <- rlang::as_label(qb)
  combined <- dplyr::bind_rows(freqs_a, freqs_b)
  ggplot2::ggplot(
    combined,
    ggplot2::aes(label = .data$term, size = .data$n, color = .data$group)
  ) +
    ggwordcloud::geom_text_wordcloud() +
    ggplot2::facet_wrap(ggplot2::vars(.data$group)) +
    ggplot2::theme_minimal()
}


#' Term frequency over time
#'
#' Plot the per-year frequency of one or more terms across the corpus,
#' optionally normalized by total tokens per year.
#'
#' @param data Corpus tibble.
#' @param terms Character vector of terms (or regex word-boundary
#'   patterns) to track.
#' @param normalize Logical. If \code{TRUE}, divide by total tokens per
#'   year and report a rate per 1000 tokens.
#' @return A ggplot object.
#' @export
nte_term_trends <- function(data = nte_load(),
                            terms,
                            normalize = TRUE) {
  out <- term_year_counts(data, terms, normalize)
  ggplot2::ggplot(
    out,
    ggplot2::aes(x = .data$year, y = .data$rate, color = .data$term)
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::labs(
      x = "Year",
      y = if (normalize) "Rate per 1000 tokens" else "Count",
      color = NULL
    ) +
    ggplot2::theme_minimal()
}


#' Country profile across the corpus
#'
#' Pull every section for one country across every report year. When
#' \code{plot = TRUE}, also returns a per-year section-count plot.
#'
#' @param country Character. Country name (case-insensitive).
#' @param data Corpus tibble.
#' @param plot Logical. If \code{TRUE}, return a list with a tibble and
#'   a ggplot. Otherwise return just the tibble.
#' @return A tibble, or a list with elements \code{data} and
#'   \code{plot}.
#' @export
nte_country_profile <- function(country,
                                data = nte_load(),
                                plot = FALSE) {
  cn <- toupper(country)
  out <- dplyr::filter(data, toupper(.data$country) == cn)
  if (!plot) {
    return(out)
  }
  p <- ggplot2::ggplot(out, ggplot2::aes(x = .data$year)) +
    ggplot2::geom_bar() +
    ggplot2::labs(
      title = paste("NTE sections,", cn),
      x = "Year",
      y = "Number of sections"
    ) +
    ggplot2::theme_minimal()
  list(data = out, plot = p)
}


#' Keyness comparison between two corpus subsets
#'
#' Compute keyness statistics between a target subset and a reference
#' subset. Wraps \code{quanteda.textstats::textstat_keyness()}.
#'
#' @param data Corpus tibble.
#' @param group_a Filter expression for the target subset.
#' @param group_b Filter expression for the reference subset.
#' @param measure One of \code{"chi2"}, \code{"lr"}, or \code{"pmi"}.
#' @param top_n Integer. Number of top terms to return.
#' @return A tibble of keyness scores.
#' @export
nte_compare_corpora <- function(data = nte_load(),
                                group_a,
                                group_b,
                                measure = c("chi2", "lr", "pmi"),
                                top_n = 30L) {
  measure <- match.arg(measure)
  qa <- rlang::enquo(group_a)
  qb <- rlang::enquo(group_b)
  a <- dplyr::mutate(dplyr::filter(data, !!qa), .grp = "target")
  b <- dplyr::mutate(dplyr::filter(data, !!qb), .grp = "reference")
  corp <- as_quanteda_corpus(dplyr::bind_rows(a, b))
  dfm <- quanteda::dfm(quanteda::tokens(
    corp,
    remove_punct = TRUE,
    remove_numbers = TRUE
  ))
  dfm <- quanteda::dfm_group(dfm, groups = quanteda::docvars(corp, ".grp"))
  ks <- quanteda.textstats::textstat_keyness(
    dfm,
    target = "target",
    measure = measure
  )
  tibble::as_tibble(utils::head(ks, top_n))
}


#' Convert an NTE tibble to a quanteda corpus
#'
#' Expects a \code{text} column on the input tibble.
#'
#' @param data Corpus tibble with a \code{text} column.
#' @return A \code{quanteda::corpus} object.
#' @export
as_quanteda_corpus <- function(data) {
  quanteda::corpus(data, text_field = "text")
}
