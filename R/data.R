#' USTR National Trade Estimate corpus, by section
#'
#' Section-level paragraphs from the Office of the United States Trade
#' Representative annual NTE reports. Each row is one issue-area section
#' for one country in one report year.
#'
#' @format A tibble with four columns.
#' \describe{
#'   \item{country}{Reporting target country, uppercased.}
#'   \item{year}{Report year.}
#'   \item{issue_area}{Issue-area heading from the report (e.g.
#'     \code{"INTELLECTUAL PROPERTY RIGHTS"}).}
#'   \item{text}{Section text.}
#' }
#' @source USTR National Trade Estimate Reports on Foreign Trade Barriers.
"NTEbysect"


#' DeBERTa-scored IPR paragraphs
#'
#' Paragraph-level intellectual property rights sections, each scored by
#' a DeBERTa-v3 classifier fine-tuned on a hand-labeled set of NTE IPR
#' paragraphs (Park 2026, working paper). Lower (more negative) scores
#' indicate stronger IPR-barrier rhetoric directed at the target country.
#'
#' @format A tibble with four columns.
#' \describe{
#'   \item{country}{Reporting target country, uppercased.}
#'   \item{year}{Report year.}
#'   \item{text}{Paragraph text.}
#'   \item{deberta_score}{Hypothesis-alignment logit from the fine-tuned
#'     model.}
#' }
#' @name NTE_IPR_scored_data
#' @aliases NTE_IPR_scored
#' @docType data
#' @keywords datasets
"NTE_IPR_scored"
