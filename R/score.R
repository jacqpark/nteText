#' Score new IPR paragraphs with the fine-tuned DeBERTa model
#'
#' Runs the hypothesis-alignment NLI inference pipeline that produced
#' the bundled \code{NTE_IPR_scored} dataset. For each input paragraph,
#' the model evaluates 13 hand-crafted hypotheses about IPR barriers,
#' takes the softmax probability of entailment for each, multiplies by
#' a fixed hypothesis weight, and sums to produce a raw score. By
#' default the raw score is then rescaled to roughly the -5 to +5 range
#' using the same min-max bounds applied to the published corpus, so
#' new scores are directly comparable to bundled scores. Lower (more
#' negative) values indicate stronger IPR-barrier rhetoric.
#'
#' Each input requires a country and a year because they are inserted
#' into the premise template that the model was trained against.
#'
#' Requires the \code{reticulate} package and a Python environment with
#' \code{transformers}, \code{torch}, and \code{huggingface_hub}
#' installed. Model weights are pulled from Hugging Face Hub on first
#' use and cached locally by \code{transformers}.
#'
#' This function targets IPR text only. The fine-tuned classifier and
#' its 13 hypotheses are specific to intellectual property rights
#' barriers as articulated in NTE reports. Applying it to text from
#' other domains will produce out-of-distribution scores. To extend
#' hypothesis classification to another issue area, fine-tune a
#' separate model using the colab notebook referenced in
#' \code{vignette("extending", package = "nteText")}.
#'
#' @param text Character vector of paragraphs to score.
#' @param country Character vector of country names, same length as
#'   \code{text}.
#' @param year Integer vector of report years, same length as
#'   \code{text}.
#' @param rescale Logical. If \code{TRUE} (default), return scores
#'   rescaled to roughly the -5 to +5 range using the published corpus
#'   bounds. If \code{FALSE}, return raw weighted entailment sums.
#' @param model_id Hugging Face Hub model identifier. Defaults to the
#'   IPR-fine-tuned checkpoint.
#' @param batch_size Integer. Inference batch size. Reduce on
#'   memory-constrained machines.
#' @param device One of \code{"cpu"}, \code{"cuda"}, or \code{"mps"}.
#'   \code{NULL} (the default) lets the Python helper pick the best
#'   available device.
#' @return Numeric vector of scores, one per input paragraph.
#' @export
nte_score_ipr <- function(text,
                          country,
                          year,
                          rescale = TRUE,
                          model_id = "jacqpark/nte-deberta-ipr",
                          batch_size = 32L,
                          device = NULL) {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop(
      "nte_score_ipr() requires the 'reticulate' package. ",
      "Install it with install.packages('reticulate')."
    )
  }
  if (length(text) != length(country) || length(text) != length(year)) {
    stop("text, country, and year must all be the same length.")
  }
  py <- reticulate::import_from_path(
    "score_ipr",
    path = system.file("python", package = "nteText")
  )
  unlist(py$score(
    text = as.character(text),
    country = as.character(country),
    year = as.integer(year),
    model_id = model_id,
    batch_size = as.integer(batch_size),
    device = device,
    rescale = rescale
  ))
}
