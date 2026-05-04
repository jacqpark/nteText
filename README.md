# nteText

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20028790.svg)](https://doi.org/10.5281/zenodo.20028790)

Replication data and tooling for analysis of USTR National Trade Estimate
(NTE) reports. Ships the section-level corpus and a fine-tuned DeBERTa-v3
hypothesis-alignment scoring layer for the intellectual property rights
(IPR) issue area.

## Install

```r
remotes::install_github("jacqpark/nteText")
```

## Quick start

```r
library(nteText)

# Full section-level corpus
nte_load()

# IPR subset (mirrors the NTE_IPR2 working file from the source repo)
nte_subset(issue = "IPR")

# Bundled DeBERTa-scored IPR paragraphs
nte_ipr_scored()

# One-shot regeneration of every figure and table in the paper
nte_replicate_paper(dir = "out")
```

## Scope of the DeBERTa model

The shipped DeBERTa-v3 classifier was fine-tuned on hypothesis labels for
the IPR issue area. Use `nte_score_ipr()` to score new IPR paragraphs.
For other issue areas the package provides corpus exploration tools
(keyword in context, term trends, comparative wordclouds, country
profiles, keyness) but ships no classifier. To classify text from
another issue area, fine-tune a separate model using the
`NTE_DeBERTa_V3_revised_colab.ipynb` notebook from the source repository
as a template.

## Citation

Park, J. (2026). Aid, Lending, and TRIPS. Working paper, University
of Geneva. https://doi.org/10.5281/zenodo.20028790
