---
license: mit
language:
- en
library_name: transformers
pipeline_tag: text-classification
tags:
- text-classification
- deberta-v3
- nli
- political-science
- trade-policy
- intellectual-property
base_model: MoritzLaurer/DeBERTa-v3-large-mnli-fever-anli-ling-wanli
metrics:
- f1
- accuracy
- pearsonr
---

# nte-deberta-ipr

DeBERTa-v3 fine-tuned for hypothesis-level classification of intellectual
property rights (IPR) barriers described in the United States Trade
Representative's annual National Trade Estimate (NTE) reports. The model
emits a continuous hypothesis-alignment score on a roughly -5 to +5
scale. Lower (more negative) values indicate stronger IPR-barrier
rhetoric directed at the target country. Higher (more positive) values
indicate paragraphs that do not contain barrier criticism.

## Model description

The classifier follows the natural-language-inference (NLI) framework
for hypothesis-based supervised text scoring described in Grimmer,
Roberts, and Stewart (2022, *Text as Data*, Princeton University
Press). Each input paragraph is paired with each of 13 hand-crafted
hypotheses about IPR barriers, and the softmax probability of
entailment for each pair is multiplied by a fixed hypothesis weight.
Weighted entailment probabilities are summed to produce a raw score,
which is then min-max rescaled to roughly the -5 to +5 range using
the bounds of the published 1,432-paragraph corpus.

The full inference pipeline (premise template, 13 hypotheses, weights,
aggregation, and rescaling formula) is documented below in the
"Inference pipeline" section.

Hypothesis structure

- Six factual hypotheses (H1 through H4, H12, H13) about objective
  IPR designations and event mentions.
- Seven interpretive hypotheses (H5 through H11) capturing the
  author's stance on the country's IPR efforts.

## Intended use

The model is intended for paragraph-level hypothesis scoring of IPR
barrier text from USTR NTE reports. Typical applications include
country-year IPR severity measurement and longitudinal analysis of US
trade rhetoric.

The companion R package `nteText`
(https://github.com/jacqpark/nteText) ships pre-computed scores and a
wrapper around this model.

```r
remotes::install_github("jacqpark/nteText")
nteText::nte_score_ipr(
  text    = c("Patent enforcement remains weak across multiple sectors.",
              "The country has fully implemented its TRIPS obligations."),
  country = c("INDIA", "SINGAPORE"),
  year    = c(2020L, 2020L)
)
```

Direct use from Python (with the helper from
[inst/python/score_ipr.py](https://github.com/jacqpark/nteText/blob/master/inst/python/score_ipr.py)
on the path).

```python
import score_ipr
scores = score_ipr.score(
    text=["Patent enforcement remains weak across multiple sectors."],
    country=["INDIA"],
    year=[2020],
    model_id="jacqpark/nte-deberta-ipr",
)
```

## Limitations

The model targets IPR text only. It was trained on hypothesis labels
specific to intellectual property rights barriers as articulated in
NTE reports. Applying it to text outside this domain (other NTE issue
areas, non-USTR documents, non-trade-policy prose) will produce
out-of-distribution scores with no error or warning.

The training corpus reflects the rhetorical conventions of USTR. Use
with comparable text from other governments or international
organizations may underperform.

## Training data

Hand-labeled training set of 300 IPR paragraphs from NTE reports
spanning 1995 through 2022, drawn from 49 countries. Each paragraph
was scored by the author on a -4 to +4 integer scale on each of 13
hypotheses, yielding up to 3,900 NLI pairs.

## Training procedure

Base checkpoint is
`MoritzLaurer/DeBERTa-v3-large-mnli-fever-anli-ling-wanli`, an NLI
model already fine-tuned on MNLI, FEVER-NLI, ANLI, LingNLI, and
WANLI. Training uses hypothesis-paragraph NLI pairs under 10-fold
cross-validation (roughly 1,598 pairs per fold on average, range
1,578 to 1,629). All metrics reported below are fully out-of-sample.
See `NTE_DeBERTa_V3_revised_colab.ipynb` in the source repository for
exact hyperparameters.

## Inference pipeline

The steps below match the published scoring pipeline exactly. A
reference Python implementation lives at
[inst/python/score_ipr.py](https://github.com/jacqpark/nteText/blob/master/inst/python/score_ipr.py).

### Premise template

For each paragraph, the premise fed to the model is

```
This text is about the IPR protection situation in country {COUNTRY} and year {YEAR}: {TEXT}
```

where `{COUNTRY}` is the uppercased country name, `{YEAR}` is the
report year, and `{TEXT}` is the paragraph text.

### Hypotheses and weights

The 13 hypotheses and their fixed score weights.

| ID  | Type         | Hypothesis                                                                                          | Weight |
|-----|--------------|-----------------------------------------------------------------------------------------------------|-------:|
| H1  | factual      | The country is the Priority Foreign Country.                                                        |   -2.0 |
| H2  | factual      | The country is on the Priority Watch List.                                                          |   -2.0 |
| H3  | factual      | The country is on the Watch List.                                                                   |   -1.5 |
| H4  | factual      | The country has markets listed as the Notorious Market.                                             |   -1.5 |
| H5  | interpretive | The author of this text believes that the country does not put in efforts to combat IPR violations. |   -1.0 |
| H6  | interpretive | The author of this text believes that the country has made efforts to combat IPR violations.        |   +1.0 |
| H7  | interpretive | The author of this text supports the passage of the new IPR legislation in the country.             |   +1.0 |
| H8  | interpretive | The author of this text opposes the passage of the new IPR legislation in the country.              |   -1.0 |
| H9  | interpretive | The author of this text believes that there is widespread IPR violation in the country.             |   -1.5 |
| H10 | interpretive | The author of this text believes that the country is lack of resources to combat IPR violations.    |   -1.0 |
| H11 | interpretive | The author of this text believes that the country has strong IPR law.                               |   +2.0 |
| H12 | factual      | This text mentions the increase of IPR violations in the country.                                   |   -1.0 |
| H13 | factual      | This text mentions the decrease of IPR violations in the country.                                   |   +1.0 |

### Aggregation

For each (premise, hypothesis) pair, take the softmax over the
three-class NLI head (entailment, neutral, contradiction) and read
the entailment probability at index 0 (the convention used in the
MoritzLaurer NLI checkpoint family). Sum across the 13 hypotheses,
weighted.

```
raw_score = sum(P_entail(premise, h_i) * weight_i for i in 1..13)
```

### Rescaling

Min-max rescale the raw score to roughly the -5 to +5 range using
the bounds from the published corpus run.

```
PUBLISHED_RAW_MIN = -8.7824
PUBLISHED_RAW_MAX =  4.5083

scaled = -5 + 10 * (raw - PUBLISHED_RAW_MIN) / (PUBLISHED_RAW_MAX - PUBLISHED_RAW_MIN)
```

New paragraphs more extreme than anything in the published corpus
may produce scaled scores outside the -5 to +5 envelope. That is
expected behavior.

## Evaluation

### 10-fold cross-validation (Grimmer, Roberts, and Stewart 2022)

Aggregate score validation.

```
Weighted F1   0.787
Accuracy      0.773
Pearson r     0.676
Spearman rho  0.689
```

Per-class metrics (binarized at midpoint of bin means).

| Class    | Precision | Recall |    F1 |   N |
|----------|----------:|-------:|------:|----:|
| Negative |     0.938 |  0.746 | 0.831 | 224 |
| Positive |     0.533 |  0.855 | 0.657 |  76 |

Hypothesis-level pool across H1 through H13.

```
Weighted F1   0.870
Accuracy      0.863
```

### Per-hypothesis validation

Out-of-sample weighted F1 and accuracy by hypothesis (10-fold CV).
N=1 is the count of paragraphs hand-coded as entailing the
hypothesis. N=0 is the count of paragraphs hand-coded as not
entailing it.

| Hypothesis | Type         |   wF1 |   Acc | N=1 | N=0 |
|------------|--------------|------:|------:|----:|----:|
| H1         | factual      | 0.988 | 0.987 |   6 | 294 |
| H2         | factual      | 0.977 | 0.977 |  58 | 242 |
| H3         | factual      | 0.963 | 0.963 |  86 | 214 |
| H4         | factual      | 0.993 | 0.993 |  21 | 279 |
| H5         | interpretive | 0.840 | 0.840 | 146 | 154 |
| H6         | interpretive | 0.694 | 0.697 | 110 | 190 |
| H7         | interpretive | 0.813 | 0.777 |  32 | 268 |
| H8         | interpretive | 0.849 | 0.797 |  15 | 285 |
| H9         | interpretive | 0.803 | 0.803 | 134 | 166 |
| H10        | interpretive | 0.875 | 0.847 |  21 | 279 |
| H11        | interpretive | 0.857 | 0.840 |  35 | 265 |
| H12        | factual      | 0.893 | 0.840 |   7 | 293 |
| H13        | factual      | 0.894 | 0.857 |  11 | 289 |
| Pool       |              | 0.870 | 0.863 |     |     |

## Citation

```bibtex
@unpublished{park_nteipr,
  author = {Park, Jihye},
  title  = {National Trade Estimate text-as-data analysis of intellectual property barriers},
  note   = {Working paper, University of Geneva},
  year   = {2026}
}
```

## License

MIT.

## Contact

Jihye Park, University of Geneva. jihye.park.psci@gmail.com.
